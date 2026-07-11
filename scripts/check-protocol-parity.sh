#!/usr/bin/env bash
# check-protocol-parity.sh — as constantes de protocolo em
# app/lib/sync/nostr/kinds.dart e cli/internal/protocol/kinds.go precisam
# ter o mesmo valor (mesmo nome, case-insensitive: Dart usa camelCase, Go
# usa PascalCase). São a mesma fonte normativa (shared/PROTOCOL.md §4)
# duplicada nas duas linguagens porque não há codegen compartilhado para
# constantes escalares (só o protobuf do changeset tem, via
# scripts/gen-proto.sh) — essa checagem é o que evita as duas cópias
# divergirem silenciosamente.
#
# Não é o teste de interoperabilidade completo do SPEC §16 (esse precisa do
# protobuf real, Fase 4/5, ver knowledge/concepts/testing.md) — só garante
# que as constantes hoje presentes concordam.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DART_FILE="$ROOT/app/lib/sync/nostr/kinds.dart"
GO_FILE="$ROOT/cli/internal/protocol/kinds.go"

[ -f "$DART_FILE" ] && [ -f "$GO_FILE" ] || {
  echo "kinds.dart e/ou kinds.go não encontrados — pulando"; exit 0; }

extract_dart() {
  grep -E '^const ' "$DART_FILE" \
    | sed -E 's/^const [A-Za-z<>]+ ([A-Za-z0-9_]+) = ([^;]+);.*/\1=\2/'
}

extract_go() {
  awk '/^const \(/{f=1;next} /^\)/{f=0} f' "$GO_FILE" \
    | sed -E 's/\/\/.*$//' \
    | grep -E '=' \
    | sed -E 's/^[[:space:]]*([A-Za-z0-9_]+)[[:space:]]+=[[:space:]]+(.*[^[:space:]])[[:space:]]*$/\1=\2/'
}

status=0
declare -A dart_vals
while IFS='=' read -r name val; do
  [ -z "$name" ] && continue
  dart_vals["$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"]="$val"
done < <(extract_dart)

while IFS='=' read -r name val; do
  [ -z "$name" ] && continue
  key="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  if [ -z "${dart_vals[$key]+x}" ]; then
    echo "✗ $name (kinds.go) sem equivalente em kinds.dart"
    status=1
    continue
  fi
  # Go usa aspas duplas para string, Dart usa aspas simples — normaliza.
  dval="$(printf '%s' "${dart_vals[$key]}" | tr "'" '"')"
  gval="$(printf '%s' "$val" | tr "'" '"')"
  if [ "$dval" != "$gval" ]; then
    echo "✗ $name diverge: kinds.dart=${dart_vals[$key]} kinds.go=$val"
    status=1
  fi
  unset "dart_vals[$key]"
done < <(extract_go)

for key in "${!dart_vals[@]}"; do
  echo "✗ constante em kinds.dart ($key) sem equivalente em kinds.go"
  status=1
done

if [ "$status" -eq 0 ]; then
  echo "Constantes de protocolo (kinds.dart ↔ kinds.go) conferem."
fi
exit "$status"
