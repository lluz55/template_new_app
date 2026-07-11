#!/usr/bin/env bash
# check-flutter.sh — análise estática focada em performance no código Dart.
# - dart analyze (com os lints de performance do analysis_options.yaml)
# - reforça que 'prefer_const_constructors' e afins estão ligados
#
# Requer, no app/analysis_options.yaml, algo como:
#   linter:
#     rules:
#       - prefer_const_constructors
#       - prefer_const_constructors_in_immutables
#       - prefer_const_literals_to_create_immutables
#       - avoid_unnecessary_containers
#       - sized_box_for_whitespace
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app" 2>/dev/null || { echo "diretório app/ não encontrado — pulando"; exit 0; }

if ! command -v dart >/dev/null 2>&1; then
  echo "dart não encontrado — pulando (entre no devShell app-linux)"; exit 0
fi

# Garante que os lints de performance existem na config
opts="analysis_options.yaml"
missing=0
for rule in prefer_const_constructors avoid_unnecessary_containers; do
  if [ -f "$opts" ] && ! grep -q "$rule" "$opts"; then
    echo "AVISO: lint '$rule' ausente em $opts (recomendado para performance)"
    missing=1
  fi
done
[ "$missing" -eq 1 ] && echo "(considere habilitar os lints de performance)"

echo "dart analyze --fatal-infos ..."
dart analyze --fatal-infos
