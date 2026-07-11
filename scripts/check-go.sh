#!/usr/bin/env bash
# check-go.sh — checagens de performance/qualidade da CLI Go.
# - go vet
# - govulncheck (CVEs conhecidas nas deps fixadas em go.sum, SPEC §10.4)
# - benchmarks (regressão fica a cargo de benchstat, opcional)
# - tamanho do binário release (ldflags -s -w) vs orçamento
#
# Env:
#   CLI_BUDGET_MB      orçamento em MB do binário (default 20)
#   GOVULNCHECK_STRICT falha a checagem em vez de só avisar (default 0) —
#                       fica off por padrão porque um achado comum é uma CVE
#                       da toolchain Go do nixpkgs (corrige-se com
#                       `nix flake lock --update-input nixpkgs`, uma decisão
#                       deliberada — AGENTS.md pede para não mexer em
#                       flake.nix/lockfiles sem alinhar antes), não algo que
#                       o código deste repo possa corrigir sozinho.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/cli" 2>/dev/null || { echo "diretório cli/ não encontrado — pulando"; exit 0; }

BUDGET_MB="${CLI_BUDGET_MB:-20}"

if ! command -v go >/dev/null 2>&1; then
  # perf-check.sh pode ser chamado de dentro do devShell app-linux (sem go) —
  # reentra automaticamente no devShell cli em vez de pular a checagem
  # silenciosamente. TPL_NEW_APP_NO_REEXEC evita recursão caso ainda falte.
  if [ -z "${TPL_NEW_APP_NO_REEXEC:-}" ] && command -v nix >/dev/null 2>&1; then
    exec env TPL_NEW_APP_NO_REEXEC=1 nix develop "$ROOT#cli" -c bash "$ROOT/scripts/check-go.sh" "$@"
  fi
  echo "go não encontrado — pulando (entre no devShell cli)"; exit 0
fi

echo "go vet ./..."
go vet ./... || exit 1

if command -v govulncheck >/dev/null 2>&1; then
  echo "govulncheck ./..."
  if ! govulncheck ./...; then
    if [ "${GOVULNCHECK_STRICT:-0}" = "1" ]; then
      exit 1
    fi
    echo "(achado(s) acima — não fatal por padrão; ver GOVULNCHECK_STRICT no cabeçalho deste script)"
  fi
else
  echo "govulncheck não encontrado — pulando (disponível no devShell cli)"
fi

echo "go test -bench . -benchmem -run '^$' ./..."
go test -bench . -benchmem -run '^$' ./... || {
  echo "(sem benchmarks ou falha; benchmarks são recomendados nos hot paths)"
}

echo "build release (ldflags -s -w) ..."
tmp="$(mktemp)"
# Só o pacote raiz (.) é `main` — `./...` inclui cmd/ e internal/*, que são
# bibliotecas sem binário próprio, e `go build -o <arquivo> ./...` falha
# ("cannot write multiple packages to non-directory") quando há mais de um
# pacote `main` ou pacotes que não geram binário no conjunto.
CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o "$tmp" . || {
  echo "build da CLI falhou"; rm -f "$tmp"; exit 1; }

bytes=$(stat -c%s "$tmp" 2>/dev/null || stat -f%z "$tmp")
mb=$(( bytes / 1024 / 1024 ))
rm -f "$tmp"
echo "Binário CLI: ${mb} MB (orçamento ${BUDGET_MB} MB)"

if [ "$mb" -gt "$BUDGET_MB" ]; then
  echo "ACIMA do orçamento. Cheque deps pesadas; use -s -w e -trimpath."
  exit 1
fi
