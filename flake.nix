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
          build-tools-34-0-0
          platform-tools
          platforms-android-34
          ndk-26-1-10909125
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
              echo "devShell app-linux: flutter $(flutter --version | head -n1)"
            '';
          };

          # Android SDK/NDK via github:tadfisher/android-nixpkgs (SPEC §13.2)
          android = pkgs.mkShell {
            buildInputs = [ pkgs.flutter androidSdk ] ++ linuxAppDeps;
            ANDROID_HOME = "${androidSdk}/share/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
            shellHook = ''
              echo "devShell android: ANDROID_HOME=$ANDROID_HOME"
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
