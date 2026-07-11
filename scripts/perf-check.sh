#!/usr/bin/env bash
# perf-check.sh — orquestra as checagens de performance/qualidade do repo.
# Roda cada checagem, agrega resultados e retorna != 0 se qualquer uma falhar.
#
# Uso:
#   scripts/perf-check.sh              # roda tudo
#   SKIP_APK=1 scripts/perf-check.sh   # pula a checagem de APK (Android)
#
# Orçamentos (env, com defaults):
#   WEB_BUDGET_KB=3072   APK_BUDGET_MB=25   CLI_BUDGET_MB=20
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Cores (desativa se não for TTY)
if [ -t 1 ]; then RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; RST=$'\e[0m'
else RED=""; GRN=""; YLW=""; RST=""; fi

FAILED=0
run() {
  local name="$1"; shift
  echo
  echo "==> ${name}"
  if "$@"; then
    echo "${GRN}✓ ${name} ok${RST}"
  else
    echo "${RED}✗ ${name} falhou${RST}"
    FAILED=1
  fi
}

run "Flutter analyze + const" bash scripts/check-flutter.sh
run "Anti-padrões (thread de UI)" bash scripts/check-antipatterns.sh
run "Bundle web (orçamento)" bash scripts/check-web-bundle.sh
[ "${SKIP_APK:-0}" = "1" ] || run "Tamanho do APK" bash scripts/check-apk-size.sh
run "Go (vet/bench/binário)" bash scripts/check-go.sh
run "Conformidade OKF" bash scripts/check-okf.sh
run "Paridade de protocolo (kinds.dart ↔ kinds.go)" bash scripts/check-protocol-parity.sh

echo
if [ "$FAILED" -ne 0 ]; then
  echo "${RED}Alguma checagem de performance falhou.${RST}"
  exit 1
fi
echo "${GRN}Todas as checagens passaram.${RST}"
