#!/usr/bin/env bash
# list-todos.sh — agrupa por fase (SPEC §17) o trabalho pendente marcado no
# código (`TODO(fase-N, ...)` em Dart, comentários/erros "Fase N" em Go),
# para dar uma visão rápida do que já está implementado vs. stub sem
# precisar grepar o repo inteiro arquivo por arquivo.
#
# Uso:
#   scripts/list-todos.sh          # agrupado por fase
#   scripts/list-todos.sh --count  # só a contagem por fase
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DIRS=(app cli shared)
EXISTING_DIRS=()
for d in "${DIRS[@]}"; do
  [ -d "$d" ] && EXISTING_DIRS+=("$d")
done

count_only=0
[ "${1:-}" = "--count" ] && count_only=1

any=0
for phase in 1 2 3 4 5 6; do
  hits=$(grep -rnE "[Ff]ase[ -]?${phase}([^0-9]|$)" \
    --include='*.dart' --include='*.go' \
    "${EXISTING_DIRS[@]}" 2>/dev/null || true)
  [ -z "$hits" ] && continue
  any=1
  n=$(printf '%s\n' "$hits" | wc -l)
  echo "== Fase $phase — $n ocorrência(s) =="
  [ "$count_only" -eq 1 ] || printf '%s\n' "$hits" | sed 's/^/  /'
  echo
done

if [ "$any" -eq 0 ]; then
  echo "Nenhum marcador de fase pendente encontrado (TODO(fase-N/\"Fase N\")."
fi
