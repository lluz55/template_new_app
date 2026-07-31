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

        # Versões pinadas explicitamente — nunca "latest" implícito
        # (SPEC §13.2). Atualize com:
        #   nix flake lock --update-input android-nixpkgs
        # e faça o bump das versões abaixo deliberadamente.
        androidSdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          # build-tools/platform 36: exigidos pelo AGP 9.x e por
          # `compileSdk = flutter.compileSdkVersion` (Flutter 3.44.4 → SDK 36).
          # A SDK é read-only na store, então o AGP não auto-instala o que falta —
          # cada componente usado por app/plugin precisa vir pinado aqui.
          build-tools-36-0-0
          platform-tools
          platforms-android-36
          # Plugins fixam `compileSdk` mais antigo: dynamic_color/package_info_plus
          # → 34; jni/jni_flutter → 35. Levante com `grep -rn compileSdk` nos
          # build.gradle dos plugins resolvidos e pine o platform de cada valor.
          # (Ao adicionar plugins como flutter_webrtc [31] você pinará mais aqui.)
          platforms-android-34
          platforms-android-35
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
