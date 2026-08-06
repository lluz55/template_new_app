#!/usr/bin/env bash
# bootstrap-platforms.sh — gera a scaffolding de plataforma do Flutter
# (app/android, app/linux, app/web) se ainda não existir.
#
# Por quê isso é um script e não passos manuais no README: `flutter create`
# não é hermético (gera timestamps, arquivos de IDE, um .gitignore/README
# próprios) e esses diretórios não são versionados neste template (native
# scaffolding é regenerada, não commitada — mesmo tratamento de
# app/lib/l10n/gen/ e shared/proto/gen/, ver .gitignore). Rodar isso à mão
# de forma consistente (e sem sujar o repo com .idea/*.iml) é chato de
# lembrar — inclusive para um agente de IA operando no repo pela primeira
# vez — daí o script.
#
# Idempotente: não faz nada se app/android, app/linux e app/web já existem.
# Chamado automaticamente por scripts/check-web-bundle.sh e
# scripts/check-apk-size.sh antes de buildar.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app" 2>/dev/null || { echo "diretório app/ não encontrado — pulando"; exit 0; }

if [ -d android ] && [ -d linux ] && [ -d web ]; then
  echo "scaffolding de plataforma já existe (app/android, app/linux, app/web) — nada a fazer."
  exit 0
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter não encontrado — pulando (entre no devShell app-linux)"; exit 0
fi

echo "Gerando scaffolding de plataforma (flutter create . --platforms=android,linux,web)..."
# Nunca --overwrite: sem essa flag, `flutter create` só grava o que falta
# (os diretórios de plataforma) e pula arquivos já existentes no projeto
# (pubspec.yaml, analysis_options.yaml, lib/main.dart, ...) em vez de
# substituí-los pelo boilerplate padrão do Flutter.
flutter create . \
  --platforms=android,linux,web \
  --org dev.tpl_new_app \
  --project-name tpl_new_app

# `flutter create` também gera arquivos que não fazem sentido versionar aqui:
# projeto de IDE (.idea/, *.iml), e um .gitignore/README/test de exemplo que
# duplicam o que este template já define na raiz.
rm -rf .idea tpl_new_app.iml android/*.iml .gitignore README.md test/widget_test.dart

# --- Patches do build Android para NixOS/Nix (store read-only + Gradle 9) -----
# app/android/ é regenerado e NÃO versionado (ver cabeçalho), então esses ajustes
# não podem morar em git — eles são reaplicados aqui a cada bootstrap. Os pré-
# requisitos de SDK (JDK 17, espelho gravável do gradle tooling, NDK/build-tools/
# platforms/cmake pinados) ficam no devShell `android` do flake.nix; estes dois
# patches são a contraparte nos arquivos Gradle gerados. Idempotentes (guardas
# por grep) e fail-loud (avisam se a âncora do `flutter create` mudou).

# 1) settings.gradle.kts: honrar FLUTTER_GRADLE_TOOLING (espelho gravável do
#    flake). Sem isso o Gradle 9 recusa o included build read-only da store.
settings="android/settings.gradle.kts"
if [ -f "$settings" ] && ! grep -q FLUTTER_GRADLE_TOOLING "$settings"; then
  tmp="$(mktemp)"
  while IFS= read -r line; do
    if [ "$line" = '    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")' ]; then
      cat >>"$tmp" <<'KOTLIN'
    // Gradle 9 exige projectDir gravável no included build, mas a SDK do Flutter
    // vem read-only da /nix/store. O devShell `android` (flake.nix) monta um
    // espelho gravável e o expõe via FLUTTER_GRADLE_TOOLING; fora do Nix, cai no
    // caminho padrão dentro da própria SDK. (Reaplicado por bootstrap-platforms.sh.)
    val flutterGradleTooling =
        System.getenv("FLUTTER_GRADLE_TOOLING")
            ?: "$flutterSdkPath/packages/flutter_tools/gradle"
    includeBuild(flutterGradleTooling)
KOTLIN
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
  done < "$settings"
  mv "$tmp" "$settings"
fi
grep -q FLUTTER_GRADLE_TOOLING "$settings" 2>/dev/null \
  || echo "AVISO: não apliquei o patch FLUTTER_GRADLE_TOOLING em $settings (âncora do flutter create mudou?) — build Android na store read-only vai falhar sem ele."

# 2) build.gradle.kts: normalizar compileSdk e buildToolsVersion dos subprojetos.
#
#    compileSdk: plugins fixam valores antigos (ex.: dynamic_color → 34,
#    jni → 35) e o grafo resolvido exige o teto de quem pede mais — sem elevar,
#    quebra :<plugin>:checkReleaseAarMetadata.
#
#    buildToolsVersion: o AGP 9.0.1 NÃO usa um default único quando ninguém
#    declara — :app:minifyReleaseWithR8 pede 36.0.0 e :app:processReleaseResources
#    procura o aapt2 em build-tools/35.0.0. Numa SDK read-only da /nix/store nada
#    disso é auto-instalado, então o build falha em uma tarefa ou na outra
#    dependendo de qual você pinou. Declarar explicitamente elimina o chute.
#
#    Os dois valores precisam casar com o que está pinado no devShell `android`
#    do flake.nix (`platforms-android-<COMPILE_SDK_FLOOR>` e
#    `build-tools-<BUILD_TOOLS_VERSION>`): ao subir aqui, suba lá no mesmo commit.
COMPILE_SDK_FLOOR=37
BUILD_TOOLS_VERSION=36.0.0

build_gradle="android/build.gradle.kts"
if [ -f "$build_gradle" ] && ! grep -q getCompileSdk "$build_gradle"; then
  tmp="$(mktemp)"
  while IFS= read -r line; do
    printf '%s\n' "$line" >>"$tmp"
    if [ "$line" = '    project.layout.buildDirectory.value(newSubprojectBuildDir)' ]; then
      cat >>"$tmp" <<KOTLIN

    // Eleva para ${COMPILE_SDK_FLOOR} o compileSdk de qualquer subprojeto Android abaixo disso
    // e fixa buildToolsVersion em ${BUILD_TOOLS_VERSION} em todos eles. Registrado aqui
    // (antes do evaluationDependsOn, que já dispara a avaliação) e via reflexão
    // para não depender da assinatura tipada do AGP (muda entre versões maiores).
    // (Reaplicado por bootstrap-platforms.sh.)
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        val current = android.javaClass.methods
            .firstOrNull { it.name == "getCompileSdk" && it.parameterTypes.isEmpty() }
            ?.invoke(android) as? Int
        if (current != null && current < ${COMPILE_SDK_FLOOR}) {
            android.javaClass.methods
                .firstOrNull {
                    it.name == "setCompileSdk" &&
                        it.parameterTypes.size == 1 &&
                        it.parameterTypes[0].name == "java.lang.Integer"
                }
                ?.invoke(android, ${COMPILE_SDK_FLOOR})
        }
        android.javaClass.methods
            .firstOrNull {
                it.name == "setBuildToolsVersion" &&
                    it.parameterTypes.size == 1 &&
                    it.parameterTypes[0].name == "java.lang.String"
            }
            ?.invoke(android, "${BUILD_TOOLS_VERSION}")

        // Registra src/main/kotlin no source set JAVA do subprojeto.
        //
        // Por quê: sob \`android.builtInKotlin=false\` (ver gradle.properties), um
        // plugin que aplica o KGP por conta própria compila seu Kotlin — o .class
        // aparece em intermediates/aar_main_jar — mas o AGP 9 NÃO o inclui no
        // compile_library_classes_jar, que é o jar contra o qual os consumidores
        // compilam. Resultado: o javac do :app falha em GeneratedPluginRegistrant
        // com "cannot find symbol <Plugin>" mesmo o Kotlin tendo compilado.
        // Plugins que já fazem \`main.java.srcDirs += 'src/main/kotlin'\` (ex.:
        // dynamic_color) não sofrem disso; os que não fazem (ex.: package_info_plus)
        // sofrem. Adicionar o diretório aqui iguala os dois casos.
        //
        // Idempotente (srcDir num set) e no-op em subprojeto sem src/main/kotlin.
        val kotlinSrc = project.file("src/main/kotlin")
        if (kotlinSrc.isDirectory) {
            val sourceSets = android.javaClass.methods
                .firstOrNull { it.name == "getSourceSets" && it.parameterTypes.isEmpty() }
                ?.invoke(android)
            val mainSet = sourceSets?.let { sets ->
                sets.javaClass.methods
                    .firstOrNull { it.name == "getByName" && it.parameterTypes.size == 1 }
                    ?.invoke(sets, "main")
            }
            val javaSet = mainSet?.let { set ->
                set.javaClass.methods
                    .firstOrNull { it.name == "getJava" && it.parameterTypes.isEmpty() }
                    ?.invoke(set)
            }
            javaSet?.let { js ->
                js.javaClass.methods
                    .firstOrNull { it.name == "srcDir" && it.parameterTypes.size == 1 }
                    ?.invoke(js, kotlinSrc)
            }
        }
    }
KOTLIN
    fi
  done < "$build_gradle"
  mv "$tmp" "$build_gradle"
fi
grep -q getCompileSdk "$build_gradle" 2>/dev/null \
  || echo "AVISO: não apliquei o patch compileSdk em $build_gradle (âncora do flutter create mudou?) — pode quebrar :<plugin>:checkReleaseAarMetadata."

echo "Scaffolding de plataforma pronta em app/android, app/linux, app/web."
