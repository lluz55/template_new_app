#!/usr/bin/env bash
# rename-template.sh — instancia o template: troca o nome do projeto (hoje
# "tpl_new_app") em todo o repo de uma vez. Uso único, ao começar um projeto
# de verdade a partir deste template — não é algo para rodar repetidamente.
#
# Troca três formas do nome, derivadas de um único argumento snake_case:
#   snake_case  meu_app          pacote Dart (pubspec.yaml, imports), módulo
#               Go, título/appTitle, nome do arquivo do banco local
#   kebab-case  meu-app          binário/usage da CLI, package protobuf,
#               d-tag do snapshot Nostr (shared/PROTOCOL.md §1), diretório
#               da keystore da CLI
#   org         dev.meu_app      id do pacote Android/domínio reverso
#               (default: dev.<snake_case>; sobrescreva com --org)
#
# Uso:
#   scripts/rename-template.sh novo_nome [--org com.empresa] [--dry-run]
#
# novo_nome: minúsculas, dígitos e "_", começando com letra (mesma regra de
# nome de pacote Dart/Go). Exemplo: scripts/rename-template.sh minha_lista
#
# --org       domínio reverso para Android. Default: dev.<novo_nome>.
# --dry-run   só mostra quais arquivos mudariam, sem escrever nada.
#
# Depois de rodar (passos manuais, de propósito — nada disso é automático):
#   - Se app/android|linux|web já existirem localmente (gerados por
#     scripts/bootstrap-platforms.sh), apague e regenere: eles têm o nome
#     antigo embutido e não são versionados (ver .gitignore).
#       rm -rf app/android app/linux app/web && scripts/bootstrap-platforms.sh
#   - cd app && flutter pub get   (o nome do pacote Dart mudou)
#   - cd cli && go build ./...    (confere que o módulo Go recompila)
#   - vendorHash em flake.nix (packages.cli) NÃO muda — as dependências Go
#     externas continuam as mesmas, só o nome do módulo local mudou.
#   - Revise o `git diff` e o histórico do CHANGELOG.md/README.md manualmente
#     — este script troca literais de código, não prosa livre sobre o
#     projeto.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OLD_SNAKE="tpl_new_app"
OLD_KEBAB="tpl-new-app"
OLD_ORG="dev.tpl_new_app"

usage() {
  echo "Uso: $0 <novo_nome_snake_case> [--org com.empresa] [--dry-run]" >&2
  exit 1
}

[ $# -ge 1 ] || usage
NEW_SNAKE="$1"
shift

NEW_ORG=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --org)
      NEW_ORG="${2:-}"
      [ -n "$NEW_ORG" ] || usage
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if ! [[ "$NEW_SNAKE" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "✗ nome inválido: '$NEW_SNAKE' — use snake_case (minúsculas, dígitos, _), começando com letra." >&2
  exit 1
fi
if [ "$NEW_SNAKE" = "$OLD_SNAKE" ]; then
  echo "✗ '$NEW_SNAKE' é o nome atual do template — nada a fazer." >&2
  exit 1
fi

NEW_KEBAB="${NEW_SNAKE//_/-}"
NEW_ORG="${NEW_ORG:-dev.$NEW_SNAKE}"

echo "Renomeando o template:"
echo "  snake_case : $OLD_SNAKE -> $NEW_SNAKE"
echo "  kebab-case : $OLD_KEBAB -> $NEW_KEBAB"
echo "  org        : $OLD_ORG -> $NEW_ORG"
[ "$DRY_RUN" -eq 1 ] && echo "  (--dry-run: nada será escrito)"
echo

# Lista explícita (não um grep -r cego no repo inteiro) — mais previsível e
# não arrisca tocar em .git/, flake.lock, pubspec.lock, go.sum (não têm o
# nome do projeto, só hashes/versões de dependências externas).
FILES=(
  README.md
  flake.nix
  app/pubspec.yaml
  app/lib/data/local/app_database.dart
  app/lib/l10n/app_pt.arb
  app/lib/l10n/app_en.arb
  app/lib/sync/nostr/kinds.dart
  app/test/data/item_local_repository_test.dart
  app/test/data/relay_settings_local_repository_test.dart
  app/test/sync/relay_pool_test.dart
  app/test/widget/adaptive_nav_test.dart
  cli/main.go
  cli/cmd/root.go
  cli/cmd/backup.go
  cli/cmd/keygen.go
  cli/cmd/pull.go
  cli/internal/keystore/keystore.go
  cli/internal/protocol/kinds.go
  cli/go.mod
  shared/proto/changeset.proto
  shared/PROTOCOL.md
  knowledge/concepts/protocol.md
  scripts/bootstrap-platforms.sh
)

changed=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  if ! grep -qF -e "$OLD_SNAKE" -e "$OLD_KEBAB" -e "$OLD_ORG" "$f"; then
    continue
  fi
  changed=$((changed + 1))
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "seria alterado: $f"
    continue
  fi
  # Ordem importa: substitui a forma mais específica (org) primeiro, senão
  # a troca do snake_case já consome o "tpl_new_app" dentro de "dev.tpl_new_app"
  # antes da troca de org rodar, e um --org customizado não aplicaria certo.
  content="$(cat "$f")"
  content="${content//$OLD_ORG/$NEW_ORG}"
  content="${content//$OLD_KEBAB/$NEW_KEBAB}"
  content="${content//$OLD_SNAKE/$NEW_SNAKE}"
  printf '%s\n' "$content" > "$f"
  echo "alterado: $f"
done

if [ "$changed" -eq 0 ]; then
  echo "Nada encontrado com '$OLD_SNAKE'/'$OLD_KEBAB'/'$OLD_ORG' — já renomeado antes?"
  exit 0
fi

[ "$DRY_RUN" -eq 1 ] && exit 0

echo
echo "Pronto — $changed arquivo(s) alterado(s). Próximos passos (manuais):"
echo "  1. rm -rf app/android app/linux app/web && scripts/bootstrap-platforms.sh"
echo "     (só se essas pastas já existirem localmente — têm o nome antigo)"
echo "  2. cd app && flutter pub get"
echo "  3. cd cli && go build ./..."
echo "  4. git diff — revise antes de commitar."
