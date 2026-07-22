#!/usr/bin/env bash
# check-flutter.sh — análise estática/formatação de cada pacote Flutter/Dart
# do repo (app/ e packages/dl_concept/):
# - dart format --set-exit-if-changed (formatação consistente)
# - dart analyze --fatal-infos (com os lints de performance do analysis_options.yaml)
# - reforça que 'prefer_const_constructors' e afins estão ligados
#
# Requer, no analysis_options.yaml de cada pacote, algo como:
#   linter:
#     rules:
#       - prefer_const_constructors
#       - prefer_const_constructors_in_immutables
#       - prefer_const_literals_to_create_immutables
#       - avoid_unnecessary_containers
#       - sized_box_for_whitespace
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v dart >/dev/null 2>&1; then
  echo "dart não encontrado — pulando (entre no devShell app-linux)"; exit 0
fi

PACKAGES=(app packages/dl_concept)
status=0

for pkg in "${PACKAGES[@]}"; do
  dir="$ROOT/$pkg"
  if [ ! -d "$dir" ]; then
    echo "$pkg/ não encontrado — pulando"
    continue
  fi

  echo
  echo "==> $pkg"

  # Garante que os lints de performance existem na config
  opts="$dir/analysis_options.yaml"
  missing=0
  for rule in prefer_const_constructors avoid_unnecessary_containers; do
    if [ -f "$opts" ] && ! grep -q "$rule" "$opts"; then
      echo "AVISO: lint '$rule' ausente em $pkg/analysis_options.yaml (recomendado para performance)"
      missing=1
    fi
  done
  [ "$missing" -eq 1 ] && echo "(considere habilitar os lints de performance)"

  echo "dart format --set-exit-if-changed ($pkg)..."
  ( cd "$dir" && dart format --set-exit-if-changed . ) || status=1

  echo "dart analyze --fatal-infos ($pkg)..."
  ( cd "$dir" && dart analyze --fatal-infos ) || status=1
done

exit "$status"
