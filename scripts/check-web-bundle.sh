#!/usr/bin/env bash
# check-web-bundle.sh — build web e valida o tamanho (gzip) do bundle.
# Problema alvo: o first-load do Flutter web crescer sem controle.
#
# Env:
#   WEB_BUDGET_KB   orçamento em KB para o total gzip do bundle (default 3072)
#   SKIP_BUILD=1    usa build/web já existente, sem rebuildar
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app" 2>/dev/null || { echo "diretório app/ não encontrado — pulando"; exit 0; }

BUDGET_KB="${WEB_BUDGET_KB:-3072}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter não encontrado — pulando (entre no devShell app-linux)"; exit 0
fi

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  [ -d web ] || bash "$ROOT/scripts/bootstrap-platforms.sh"
  echo "flutter build web --release ..."
  flutter build web --release --wasm \
    || flutter build web --release \
    || { echo "build web falhou"; exit 1; }
fi

OUT="build/web"
[ -d "$OUT" ] || { echo "sem build/web"; exit 1; }

# Soma o tamanho gzip de JS/WASM/CSS/HTML (o que realmente vai pela rede)
total=0
while IFS= read -r -d '' f; do
  sz=$(gzip -c "$f" | wc -c)
  total=$((total + sz))
done < <(find "$OUT" -type f \( -name '*.js' -o -name '*.wasm' -o -name '*.css' -o -name '*.html' \) -print0)

total_kb=$(( total / 1024 ))
echo "Bundle web (gzip, aprox): ${total_kb} KB — orçamento ${BUDGET_KB} KB"

if [ "$total_kb" -gt "$BUDGET_KB" ]; then
  echo "ACIMA do orçamento. Investigue: ícones sem tree-shake, deps pesadas, assets."
  exit 1
fi
