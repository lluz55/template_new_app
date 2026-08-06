{
  description = ''
    Template multiplataforma (Android/Linux/Web) offline-first com sync via
    Nostr. Ambiente de desenvolvimento canônico: NixOS/Nix com flakes
    (ver SPEC.md §13.1). Android SDK/NDK vêm do flake input
    github:tadfisher/android-nixpkgs (ver SPEC.md §13.2) — nunca de
    androidenv "cru" ou instalação manual.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Android SDK/NDK reprodutível via flake input do GitHub (SPEC §13.2).
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # necessário para o Android SDK
        };

        # Versão do build-tools em UM lugar só: o pin da SDK abaixo, o
        # `buildToolsVersion` que scripts/bootstrap-platforms.sh escreve no Gradle
        # e o caminho do aapt2 exportado no devShell `android` precisam ser o
        # mesmo número. Ao subir, suba nos dois arquivos no mesmo commit.
        androidBuildToolsVersion = "36.0.0";

        # Versões pinadas explicitamente — nunca "latest" implícito
        # (SPEC §13.2). Atualize com:
        #   nix flake lock --update-input android-nixpkgs
        # e faça o bump das versões abaixo deliberadamente.
        androidSdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          # build-tools e platform são pinos INDEPENDENTES — não os mantenha no
          # mesmo número por simetria:
          # - build-tools 36.0.0: é a versão que o AGP 9.x pede por conta própria
          #   (default embutido no plugin, não derivado do compileSdk). Trocar por
          #   37.0.0 faz o build falhar pedindo 36.0.0 de volta.
          # - platform 37: é o teto de `compileSdk` do grafo resolvido
          #   (flutter_secure_storage 11 fixa `compileSdk = 37`) e o valor para o
          #   qual bootstrap-platforms.sh eleva todo subprojeto abaixo dele.
          # A SDK é read-only na store, então o AGP não auto-instala o que falta —
          # cada componente usado por app/plugin precisa vir pinado aqui.
          build-tools-36-0-0
          platform-tools
          platforms-android-37-0
          # Plugins fixam `compileSdk` mais antigo: dynamic_color → 34;
          # jni/jni_flutter → 35; `compileSdk = flutter.compileSdkVersion`
          # (Flutter 3.44.4) → 36. O patch do bootstrap eleva todos para 37, mas
          # estes ficam pinados como rede de segurança para quando a âncora do
          # `flutter create` mudar e o patch não aplicar (ele avisa, não quebra).
          # Levante com `grep -rn compileSdk` nos build.gradle dos plugins
          # resolvidos e pine o platform de cada valor novo que aparecer.
          platforms-android-34
          platforms-android-35
          platforms-android-36
          # Casa com `flutter.ndkVersion` do Flutter 3.44.4 (app usa
          # `ndkVersion = flutter.ndkVersion`); read-only => não auto-instala.
          ndk-28-2-13676358
          # Plugins com build nativo via CMake (ex.: jni_flutter) pedem esta
          # versão exata; sem ela o AGP tenta instalar na store read-only e falha.
          cmake-3-22-1
          emulator
        ]);

        # Deps de sistema para Flutter Linux desktop (GTK) + libsecret
        # (flutter_secure_storage no Linux usa libsecret/keyring) + sqlcipher
        # (cifra em repouso do store local, SPEC §6).
        linuxAppDeps = with pkgs; [
          gtk3
          glib
          pkg-config
          clang
          cmake
          ninja
          libsecret
          sqlcipher
          jsoncpp
          # Fase 2 abre o banco sem cifra de propósito (ver
          # app/lib/data/local/app_database.dart:8-16) via sqflite_common_ffi
          # puro, que faz dlopen de "libsqlite3.so" — sqlcipher acima só
          # exporta "libsqlcipher.so", então sem este pacote o app crasha ao
          # abrir o banco no desktop Linux. Quando a Fase 3 ligar SQLCipher
          # (sqlite3_flutter_libs + PRAGMA key), reavaliar se ainda precisa
          # dos dois.
          sqlite
        ];

        goDeps = with pkgs; [ go protobuf protoc-gen-go ];

        # go vet/test já cobrem correção; govulncheck audita CVEs conhecidas
        # nas dependências fixadas em go.sum (scripts/check-go.sh, SPEC §10.4).
        goSecurityDeps = [ pkgs.govulncheck ];
      in
      {
        devShells = {
          default = self.devShells.${system}.app-linux;

          # Flutter + deps de build do Linux (GTK, pkg-config, clang, cmake, ninja)
          app-linux = pkgs.mkShell {
            buildInputs = [ pkgs.flutter ] ++ linuxAppDeps;
            shellHook = ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath linuxAppDeps}:$LD_LIBRARY_PATH"
              echo "devShell app-linux: flutter $(flutter --version | head -n1)"
            '';
          };

          # Android SDK/NDK via github:tadfisher/android-nixpkgs (SPEC §13.2)
          android = pkgs.mkShell {
            # `jdk17`: o Gradle do build Android precisa de um JRE no PATH e de
            # JAVA_HOME (senão `assembleRelease` aborta com "JAVA_HOME is not
            # set and no 'java' command could be found"). AGP 9.x exige JDK 17.
            # O build Linux desktop (app-linux) não passa por Gradle/Java.
            buildInputs = [ pkgs.flutter androidSdk pkgs.jdk17 ] ++ linuxAppDeps;
            ANDROID_HOME = "${androidSdk}/share/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
            JAVA_HOME = "${pkgs.jdk17}";
            shellHook = ''
              echo "devShell android: ANDROID_HOME=$ANDROID_HOME"
              echo "devShell android: JAVA_HOME=$JAVA_HOME"

              # --- AAPT2 do Nix, não o do Maven ---------------------------------
              # O AGP baixa um aapt2 pré-compilado do Maven (aapt2-<agp>-linux) e o
              # executa direto. Esse binário é um ELF genérico, sem o interpretador
              # dinâmico do NixOS => "AAPT2 Daemon startup failed" em toda tarefa
              # :app:processReleaseResources. O aapt2 que vem do build-tools da SDK
              # do android-nixpkgs já está patchelf'ado, então apontamos o AGP pra
              # ele. Via `-Dorg.gradle.project.<prop>` (não gradle.properties) de
              # propósito: propriedade de sistema tem precedência sobre o
              # ~/.gradle/gradle.properties do usuário, então um override antigo
              # apontando pra um store path já coletado pelo GC não sequestra o
              # build. O caminho é derivado de androidBuildToolsVersion => nunca
              # aponta pra uma versão que não está pinada acima.
              export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/${androidBuildToolsVersion}/aapt2 ''${GRADLE_OPTS:-}"
              echo "devShell android: aapt2 (Nix) = $ANDROID_HOME/build-tools/${androidBuildToolsVersion}/aapt2"

              # --- Flutter Gradle tooling gravável (Gradle 9 / AGP 9.x) --------
              # O build Android faz `includeBuild(.../packages/flutter_tools/
              # gradle)`. O Gradle 9 exige que o projectDir de um included build
              # seja GRAVÁVEL — mas a SDK do Flutter vem read-only da /nix/store,
              # então o build aborta com "Configuring project ':' ... does not
              # exist, can't be written to or is not a directory" (na verdade é o
              # ramo "can't be written to"). Espelhamos a SDK com symlinks e
              # trocamos SÓ packages/flutter_tools/gradle por uma cópia gravável
              # (mantendo a posição relativa, senão o `../../../bin/internal/
              # engine.version` que esse build lê deixa de resolver). O espelho é
              # chaveado pelo hash da store da SDK => reconstruído só quando a SDK
              # muda. settings.gradle.kts lê FLUTTER_GRADLE_TOOLING (ver lá).
              flutter_root="${pkgs.flutter}"
              mirror_base="''${XDG_CACHE_HOME:-$HOME/.cache}/tpl_new_app/flutter-gradle-mirror"
              mirror="$mirror_base/$(basename "$flutter_root")"
              if [ ! -e "$mirror/.mirror-complete" ]; then
                rm -rf "$mirror"
                mkdir -p "$mirror"
                for e in "$flutter_root"/*; do ln -s "$e" "$mirror/"; done
                rm "$mirror/packages"
                mkdir "$mirror/packages"
                for e in "$flutter_root"/packages/*; do ln -s "$e" "$mirror/packages/"; done
                rm "$mirror/packages/flutter_tools"
                mkdir "$mirror/packages/flutter_tools"
                for e in "$flutter_root"/packages/flutter_tools/*; do
                  ln -s "$e" "$mirror/packages/flutter_tools/"
                done
                rm "$mirror/packages/flutter_tools/gradle"
                cp -rL "$flutter_root/packages/flutter_tools/gradle" \
                  "$mirror/packages/flutter_tools/gradle"
                chmod -R u+w "$mirror/packages/flutter_tools/gradle"
                touch "$mirror/.mirror-complete"
              fi
              export FLUTTER_GRADLE_TOOLING="$mirror/packages/flutter_tools/gradle"
              echo "devShell android: FLUTTER_GRADLE_TOOLING=$FLUTTER_GRADLE_TOOLING"
            '';
          };

          # Go para a CLI + protobuf (codegen compartilhado com o app Dart)
          cli = pkgs.mkShell {
            buildInputs = goDeps ++ goSecurityDeps;
            shellHook = ''
              echo "devShell cli: $(go version)"
            '';
          };

          # Ferramentas de segurança/qualidade que não pertencem a um único
          # alvo (app/cli): scripts/check-secrets.sh (gitleaks). Deliberadamente
          # sem Flutter/Go — só o suficiente para varrer o repo rápido no CI.
          tools = pkgs.mkShell {
            buildInputs = [ pkgs.gitleaks ];
            shellHook = ''
              echo "devShell tools: gitleaks $(gitleaks version)"
            '';
          };
        };

        packages = {
          # Binário da CLI Go. vendorHash é placeholder — depois de
          # `cd cli && go mod tidy`, rode `nix build .#cli` e cole o hash
          # real reportado pelo erro de mismatch.
          cli = pkgs.buildGoModule {
            pname = "tpl-new-app-cli";
            version = "0.1.0";
            src = ./cli;
            vendorHash = "sha256-sGk1jI+4/fZw7eSrR7fNJgwsHffhVbwwx53Hb8XAOj4=";
            env.CGO_ENABLED = "0";
            ldflags = [ "-s" "-w" ];
          };

          # Build Linux/Web do app Flutter: não são triviais de expressar como
          # derivação Nix pura (toolchain do Flutter não é hermética como o Go).
          # Padrão do template (SPEC §13.2, "Honestidade sobre Android"): builds
          # rodam via `flutter build ...` dentro do devShell correspondente,
          # não como `nix build`. Ver README.md "Início rápido".
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
