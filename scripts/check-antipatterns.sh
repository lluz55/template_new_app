#!/usr/bin/env bash
# check-antipatterns.sh — heurística estática para trabalho pesado na thread
# de UI do Flutter. Não substitui profiling, mas pega os erros comuns cedo.
#
# Falha se encontrar padrões de risco fora de isolates. Anote exceções
# legítimas com o comentário `// perf-ok` na mesma linha.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/app/lib"
[ -d "$LIB" ] || { echo "app/lib não encontrado — pulando"; exit 0; }

# padrão::mensagem
PATTERNS=(
  'File(.*)\.readAsStringSync::I/O de arquivo síncrono na thread de UI'
  'File(.*)\.writeAsStringSync::I/O de arquivo síncrono na thread de UI'
  'jsonDecode(::JSON decode grande deve ir para compute()/isolate'
  '\.sublist(0, *[0-9]{4,}::cópia grande de lista na build'
  'sqlite3\.open(::abrir DB fora de camada de dados (bloqueia UI)'
)

status=0
for entry in "${PATTERNS[@]}"; do
  pat="${entry%%::*}"
  msg="${entry##*::}"
  # -n número de linha; ignora linhas marcadas com perf-ok
  hits=$(grep -rnE "$pat" "$LIB" --include='*.dart' 2>/dev/null | grep -v 'perf-ok' || true)
  if [ -n "$hits" ]; then
    echo "⚠  $msg"
    echo "$hits" | sed 's/^/    /'
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "Nenhum anti-padrão conhecido encontrado."
fi
exit "$status"
