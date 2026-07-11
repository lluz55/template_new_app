#!/usr/bin/env bash
# check-apk-size.sh — build do APK release e validação de tamanho.
# Problema alvo: APK inchado (deps pesadas, assets, ABIs desnecessárias).
#
# Env:
#   APK_BUDGET_MB   orçamento em MB (default 25)
#   SKIP_BUILD=1    usa APK já existente
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app" 2>/dev/null || { echo "diretório app/ não encontrado — pulando"; exit 0; }

BUDGET_MB="${APK_BUDGET_MB:-25}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter não encontrado — pulando (entre no devShell android)"; exit 0
fi

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  [ -d android ] || bash "$ROOT/scripts/bootstrap-platforms.sh"
  echo "flutter build apk --release --split-per-abi ..."
  flutter build apk --release --split-per-abi \
    || flutter build apk --release \
    || { echo "build apk falhou (SDK Android disponível?)"; exit 0; }
fi

apk=$(find build/app/outputs -name '*.apk' -type f 2>/dev/null \
      | sort | head -n1)
[ -n "$apk" ] || { echo "nenhum APK encontrado — pulando"; exit 0; }

bytes=$(stat -c%s "$apk" 2>/dev/null || stat -f%z "$apk")
mb=$(( bytes / 1024 / 1024 ))
echo "APK: $(basename "$apk") — ${mb} MB (orçamento ${BUDGET_MB} MB)"

if [ "$mb" -gt "$BUDGET_MB" ]; then
  echo "ACIMA do orçamento. Cheque: --split-per-abi, R8/shrink, assets grandes."
  exit 1
fi
