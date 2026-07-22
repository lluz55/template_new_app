---
type: task
phase: 5
status: in-progress
---

# Fase 5 — Go CLI

## Escopo (SPEC §17)

Protobuf compartilhado + comandos de backup/export/import.

## Sub-tarefas

- [x] `keygen` — geração de chave, storage local (`cli/cmd/keygen.go`)
- [x] `backup` — arquiva eventos cifrados do relay sem decifrar
      (`cli/cmd/backup.go`)
- [ ] `push`/`pull` — serialização protobuf + cifra/decifra NIP-44 pendentes,
      mesma peça pendente do `SyncEngine` em Dart (`cli/cmd/push.go:26`,
      `cli/cmd/pull.go:73`; ver [04-sync-engine.md](04-sync-engine.md))
- [ ] `export`/`import` — dependem da mesma peça (`cli/cmd/export.go:22`,
      `cli/cmd/import.go:23`)

## Onde isso vive no código

`cli/cmd/`; `cli/internal/nostr/`; `cli/internal/protocol/`.

## Relacionado

[protocol.md](../concepts/protocol.md),
[04-sync-engine.md](04-sync-engine.md) (bloqueio compartilhado: protobuf +
NIP-44 real).
