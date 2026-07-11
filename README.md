# tpl_new_app

Template multiplataforma (Android/Linux/Web) offline-first, com sincronização
descentralizada via Nostr. A especificação completa está em
[SPEC.md](SPEC.md); instruções para agentes de IA em [AGENTS.md](AGENTS.md).

## Início rápido

Requer [Nix](https://nixos.org/download) com flakes habilitados (ver
[SPEC §13.1](SPEC.md#131-nixos-como-ambiente-de-desenvolvimento-obrigatório)).

```bash
# Flutter + deps do Linux
nix develop .#app-linux
scripts/bootstrap-platforms.sh   # gera app/android, app/linux, app/web (primeira vez apenas; idempotente)
cd app
flutter pub get          # também gera app/lib/l10n/gen/ (flutter gen-l10n, ver l10n.yaml)
flutter run -d linux     # ou -d chrome

# Android (SDK/NDK vêm do flake input github:tadfisher/android-nixpkgs)
nix develop .#android
cd app && flutter build apk

# CLI Go
nix develop .#cli
cd cli && go build ./... && go run . keygen
```

## Estrutura

Ver [SPEC §5](SPEC.md#5-estrutura-do-repositório) para o mapa completo do
repositório. Resumo:

| Diretório     | Conteúdo                                              |
|---------------|--------------------------------------------------------|
| `app/`        | App Flutter (UI, domínio, store local, sync, cripto)   |
| `cli/`        | CLI Go opcional (backup/export/import via Nostr)       |
| `shared/`     | Protocolo compartilhado (protobuf) entre app e CLI     |
| `knowledge/`  | Bundle OKF — conhecimento do domínio                   |
| `scripts/`    | Checagens de performance/qualidade (rodam local e CI)  |

`app/android/`, `app/linux/` e `app/web/` (scaffolding nativa) não são
versionados — gerados por `scripts/bootstrap-platforms.sh` (idempotente,
roda automaticamente dentro dos scripts de checagem que precisam deles).

## Checagens antes de commitar

```bash
dart format . && dart analyze --fatal-infos   # dentro de app/, no devShell
scripts/perf-check.sh
scripts/check-secrets.sh
cd cli && go vet ./... && go test ./...
```

## Licença

[MIT](LICENSE).
