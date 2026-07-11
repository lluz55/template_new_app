#!/usr/bin/env bash
# gen-proto.sh — gera bindings Dart e Go a partir de shared/proto/*.proto.
# Fonte única do protocolo (SPEC §8, shared/PROTOCOL.md §5).
#
# Requer protoc + protoc-gen-dart (devShell app-linux) e protoc-gen-go
# (devShell cli). Rode a partir de qualquer devShell que já tenha os dois,
# ou rode este script duas vezes, uma em cada devShell.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROTO_DIR="shared/proto"
DART_OUT="app/lib/sync/proto"
GO_OUT="cli/internal/protocol"

if ! command -v protoc >/dev/null 2>&1; then
  echo "protoc não encontrado — entre em 'nix develop .#cli' ou '.#app-linux'"
  exit 1
fi

mkdir -p "$DART_OUT" "$GO_OUT"

if command -v protoc-gen-dart >/dev/null 2>&1; then
  echo "gerando bindings Dart em $DART_OUT ..."
  protoc --proto_path="$PROTO_DIR" \
    --dart_out="$DART_OUT" \
    "$PROTO_DIR"/*.proto
else
  echo "protoc-gen-dart não encontrado — pulando codegen Dart"
  echo "  (instale via 'dart pub global activate protoc_plugin' no devShell app-linux)"
fi

if command -v protoc-gen-go >/dev/null 2>&1; then
  echo "gerando bindings Go em $GO_OUT ..."
  protoc --proto_path="$PROTO_DIR" \
    --go_out="$GO_OUT" --go_opt=paths=source_relative \
    "$PROTO_DIR"/*.proto
else
  echo "protoc-gen-go não encontrado — pulando codegen Go (devShell cli já inclui)"
fi

echo "OK. Bindings gerados não são versionados (ver .gitignore)."
