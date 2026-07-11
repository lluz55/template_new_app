#!/usr/bin/env bash
# check-secrets.sh — varre o repositório (histórico Git incluído) em busca
# de segredos commitados por engano (AGENTS.md proíbe explicitamente: nunca
# versionar chave privada Nostr/nsec/segredo do SQLCipher). Usa `gitleaks`
# (nixpkgs) — sem dependência de serviço externo ou licença.
#
# Uso:
#   scripts/check-secrets.sh                 # varre todo o histórico
#   scripts/check-secrets.sh --staged        # só o que está staged (pre-commit)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks não encontrado no PATH — rode dentro de um devShell do flake" \
    "(ele está disponível em qualquer um) ou instale via 'nix run nixpkgs#gitleaks'." >&2
  exit 1
fi

if [ "${1:-}" = "--staged" ]; then
  exec gitleaks protect --staged --redact --verbose
fi

exec gitleaks detect --redact --verbose
