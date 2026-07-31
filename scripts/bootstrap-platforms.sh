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

# 2) build.gradle.kts: elevar compileSdk de subprojetos < 36. Plugins fixam
#    compileSdk antigo (ex.: 34) e deps transitivas (flutter_plugin_android_
#    lifecycle) exigem >= 36 — sem isso quebra :<plugin>:checkReleaseAarMetadata.
build_gradle="android/build.gradle.kts"
if [ -f "$build_gradle" ] && ! grep -q getCompileSdk "$build_gradle"; then
  tmp="$(mktemp)"
  while IFS= read -r line; do
    printf '%s\n' "$line" >>"$tmp"
    if [ "$line" = '    project.layout.buildDirectory.value(newSubprojectBuildDir)' ]; then
      cat >>"$tmp" <<'KOTLIN'

    // Eleva para 36 o compileSdk de qualquer subprojeto Android abaixo disso.
    // Registrado aqui (antes do evaluationDependsOn, que já dispara a avaliação)
    // e via reflexão para não depender da assinatura tipada do AGP (muda entre
    // versões maiores). No-op quando nenhum subprojeto está abaixo de 36.
    // (Reaplicado por bootstrap-platforms.sh.)
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        val current = android.javaClass.methods
            .firstOrNull { it.name == "getCompileSdk" && it.parameterTypes.isEmpty() }
            ?.invoke(android) as? Int
        if (current != null && current < 36) {
            android.javaClass.methods
                .firstOrNull {
                    it.name == "setCompileSdk" &&
                        it.parameterTypes.size == 1 &&
                        it.parameterTypes[0].name == "java.lang.Integer"
                }
                ?.invoke(android, 36)
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
