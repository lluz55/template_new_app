#!/usr/bin/env bash
# bump-version.sh — atualiza a versão do template (SPEC §15: fonte única em
# app/pubspec.yaml, formato X.Y.Z+build) e move o conteúdo de
# CHANGELOG.md "## [Unreleased]" para uma seção datada, deixando um
# "[Unreleased]" novo e vazio no topo (Keep a Changelog).
#
# NÃO cria/publica tag ou release sozinho por padrão — isso é "pergunte
# antes" no AGENTS.md. Só prepara os arquivos; o comando de tag/release fica
# de exemplo no final. Use --tag para criar (local, sem push) a tag
# vX.Y.Z correspondente à versão atual do pubspec.
#
# Uso:
#   scripts/bump-version.sh 0.2.0        # bump para 0.2.0+<build atual + 1>
#   scripts/bump-version.sh 0.2.0+3      # build explícito
#   scripts/bump-version.sh --tag        # cria a tag git vX.Y.Z (local) para
#                                         # a versão já presente em pubspec.yaml
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PUBSPEC="app/pubspec.yaml"
FLAKE="flake.nix"
CHANGELOG="CHANGELOG.md"

usage() {
  cat >&2 <<'EOF'
Uso:
  scripts/bump-version.sh X.Y.Z[+build]   # bump de versão (SemVer)
  scripts/bump-version.sh --tag           # cria tag git vX.Y.Z (local, sem
                                           # push) para a versão atual do
                                           # pubspec.yaml
EOF
  exit 1
}

current_version_line() {
  grep -m1 '^version:' "$PUBSPEC" || true
}

[ -f "$PUBSPEC" ] || { echo "✗ $PUBSPEC não encontrado — rode da raiz do repo." >&2; exit 1; }
[ $# -ge 1 ] || usage

if [ "$1" = "--tag" ]; then
  line="$(current_version_line)"
  [ -n "$line" ] || { echo "✗ não consegui ler 'version:' de $PUBSPEC" >&2; exit 1; }
  cur_ver="$(printf '%s' "$line" | sed -E 's/version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  tag="v${cur_ver}"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "✗ tag $tag já existe." >&2
    exit 1
  fi
  git tag -a "$tag" -m "$tag"
  echo "Tag local $tag criada (SPEC §15: versão do pubspec deve bater com a tag)."
  echo "Sem push automático — revise e rode: git push origin $tag"
  exit 0
fi

NEW_FULL="$1"
if ! [[ "$NEW_FULL" =~ ^([0-9]+\.[0-9]+\.[0-9]+)(\+([0-9]+))?$ ]]; then
  echo "✗ versão inválida: '$NEW_FULL' — use SemVer X.Y.Z ou X.Y.Z+build." >&2
  exit 1
fi
NEW_VER="${BASH_REMATCH[1]}"
NEW_BUILD="${BASH_REMATCH[3]:-}"

line="$(current_version_line)"
[ -n "$line" ] || { echo "✗ não consegui ler 'version:' de $PUBSPEC" >&2; exit 1; }
cur_ver="$(printf '%s' "$line" | sed -E 's/version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
cur_build="$(printf '%s' "$line" | sed -E 's/.*\+([0-9]+).*/\1/; t; s/.*//')"

if [ -z "$NEW_BUILD" ]; then
  if [ "$cur_ver" = "$NEW_VER" ] && [ -n "$cur_build" ]; then
    NEW_BUILD=$((cur_build + 1))
  else
    NEW_BUILD=1
  fi
fi

echo "Versão: ${cur_ver}${cur_build:++$cur_build} -> ${NEW_VER}+${NEW_BUILD}"

# 1) app/pubspec.yaml — fonte única da versão (SPEC §15)
sed -i -E "s/^version:.*/version: ${NEW_VER}+${NEW_BUILD}/" "$PUBSPEC"
echo "atualizado: $PUBSPEC"

# 2) flake.nix — packages.cli.version, mesmo release da CLI (SPEC §15)
if grep -qE '^\s*version = "[0-9]+\.[0-9]+\.[0-9]+";' "$FLAKE"; then
  sed -i -E "s/^(\s*version = )\"[0-9]+\.[0-9]+\.[0-9]+\";/\1\"${NEW_VER}\";/" "$FLAKE"
  echo "atualizado: $FLAKE"
else
  echo "⚠ não achei 'version = \"X.Y.Z\";' em $FLAKE — confira manualmente."
fi

# 3) CHANGELOG.md — Keep a Changelog: [Unreleased] datado + novo [Unreleased] vazio.
# Só carimba uma seção nova se [Unreleased] tiver conteúdo de fato — senão,
# bumps repetidos (ex.: só o build number, sem entradas novas) empilhariam
# cabeçalhos de versão vazios e duplicados.
if [ -f "$CHANGELOG" ]; then
  if grep -q '^## \[Unreleased\]$' "$CHANGELOG"; then
    unreleased_body="$(awk '/^## \[Unreleased\]$/{f=1; next} /^## /{f=0} f' "$CHANGELOG" | tr -d '[:space:]')"
    if [ -z "$unreleased_body" ]; then
      echo "⚠ [Unreleased] está vazio em $CHANGELOG — não criei seção [${NEW_VER}]." \
           "Adicione entradas antes do próximo bump."
    else
      today="$(date +%F)"
      sed -i "s/^## \[Unreleased\]\$/## [Unreleased]\n\n## [${NEW_VER}] - ${today}/" "$CHANGELOG"
      echo "atualizado: $CHANGELOG (## [${NEW_VER}] - ${today})"
    fi
  else
    echo "⚠ não achei uma seção '## [Unreleased]' em $CHANGELOG — confira manualmente."
  fi
fi

echo
echo "Pronto. Revise o git diff antes de commitar. Depois, para taguear/publicar:"
echo "  scripts/bump-version.sh --tag   # cria vX.Y.Z local"
echo "  git push origin \"v${NEW_VER}\"   # dispara o job de release do CI"
