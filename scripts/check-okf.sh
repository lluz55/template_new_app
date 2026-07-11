#!/usr/bin/env bash
# check-okf.sh — conformidade mínima do bundle OKF em knowledge/.
# Regras OKF v0.1 checadas:
#   1) frontmatter YAML presente e parseável
#   2) campo `type` presente em cada conceito
#   3) arquivos reservados index.md e log.md existem
#   4) cross-links relativos (`[...](outro.md)`, `[...](/caminho.md)`)
#      resolvem para um arquivo existente
#
# Se `okf-lint` estiver instalado, ele é usado no lugar (mais completo).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/knowledge"
[ -d "$BUNDLE" ] || { echo "knowledge/ não encontrado — pulando"; exit 0; }

# Ferramenta oficial, se existir
if command -v okf-lint >/dev/null 2>&1; then
  echo "okf-lint $BUNDLE"
  exec okf-lint "$BUNDLE"
fi

status=0

# Regra 3: reservados
for f in index.md log.md; do
  if [ ! -f "$BUNDLE/$f" ]; then
    echo "✗ arquivo reservado ausente: knowledge/$f"
    status=1
  fi
done

# Regras 1 e 2: frontmatter + type em cada conceito
have_py=0
command -v python3 >/dev/null 2>&1 && have_py=1

while IFS= read -r -d '' md; do
  rel="${md#"$ROOT"/}"
  first_line=$(head -n1 "$md")
  if [ "$first_line" != "---" ]; then
    echo "✗ sem frontmatter YAML: $rel"; status=1; continue
  fi
  # extrai bloco entre o primeiro e o segundo '---'
  fm=$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$md")
  if [ "$have_py" -eq 1 ]; then
    if ! printf '%s\n' "$fm" | python3 -c 'import sys,yaml; yaml.safe_load(sys.stdin)' 2>/dev/null; then
      echo "✗ frontmatter YAML inválido: $rel"; status=1; continue
    fi
  fi
  if ! printf '%s\n' "$fm" | grep -qE '^type:[[:space:]]*\S'; then
    echo "✗ campo obrigatório 'type' ausente: $rel"; status=1
  fi
done < <(find "$BUNDLE" -type f -name '*.md' ! -name 'index.md' ! -name 'log.md' -print0)

# Regra 4: cross-links relativos (`(outro.md)`) ou raiz do repo (`(/caminho)`)
# precisam apontar para um arquivo que existe — evita que o bundle vire uma
# fonte de navegação não confiável para quem (humano ou agente) segue os
# links de index.md/AGENTS.md. Ignora URLs externas e âncoras puras (#foo).
while IFS= read -r -d '' md; do
  rel="${md#"$ROOT"/}"
  dir="$(dirname "$md")"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*) continue ;;
    esac
    target="${target%%#*}"
    [ -z "$target" ] && continue
    if [ "${target#/}" != "$target" ]; then
      resolved="$ROOT$target"
    else
      resolved="$dir/$target"
    fi
    if [ ! -e "$resolved" ]; then
      echo "✗ link quebrado em $rel: $target"
      status=1
    fi
  done < <(grep -ohE '\]\([^)]+\)' "$md" | sed -E 's/^\]\(//; s/\)$//')
done < <(find "$BUNDLE" -type f -name '*.md' -print0)

if [ "$status" -eq 0 ]; then
  echo "Bundle OKF conforme (regras mínimas)."
fi
exit "$status"
