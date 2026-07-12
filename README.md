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

## Usando este template para um projeto novo

```bash
# renomeia tpl_new_app -> nome do seu projeto em todo o repo (pacote Dart,
# módulo Go, binário/usage da CLI, d-tag do protocolo Nostr, keystore, etc.)
scripts/rename-template.sh --dry-run meu_projeto   # veja o que mudaria antes
scripts/rename-template.sh meu_projeto             # [--org com.empresa] opcional
```

Depois de renomear: se `app/android|linux|web` já existiam localmente, apague
e rode `scripts/bootstrap-platforms.sh` de novo (têm o nome antigo embutido
e não são versionados — ver "Estrutura" abaixo).

```bash
# bump de versão (SPEC §15: fonte única em app/pubspec.yaml) + CHANGELOG.md
scripts/bump-version.sh 0.2.0      # atualiza pubspec.yaml, flake.nix, CHANGELOG.md
scripts/bump-version.sh --tag      # cria a tag git vX.Y.Z local (sem push)
```

Nenhum dos dois scripts commita ou dá push sozinho — revise o `git diff`
antes. Detalhes/opções no cabeçalho de cada script.

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
