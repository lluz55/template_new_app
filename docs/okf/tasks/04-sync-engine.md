---
type: task
phase: 4
status: in-progress
---

# Fase 4 — Sync engine

## Escopo (SPEC §17)

Publicação/recepção de changesets + snapshots; pool de relays; bootstrap.

## Sub-tarefas

- [x] `RelayPool` — esqueleto de conexão a múltiplos relays (ver
      [sync.md](../concepts/sync.md))
- [ ] `RelayPool`: backoff/reconexão e confirmação de publicação (ver
      `app/lib/sync/nostr/relay_pool.dart:64`)
- [ ] `SyncEngine.push` — serializar `changeset` como protobuf + cifrar
      NIP-44 antes de publicar (`app/lib/sync/sync_engine.dart:42-47`,
      bloqueado por [03-cripto-e-chaves.md](03-cripto-e-chaves.md))
- [ ] `SyncEngine.pull`/`watchRemoteChanges` — consumir eventos do
      `RelayPool`, verificar assinatura **antes** de decifrar/aplicar
      (`app/lib/sync/sync_engine.dart:69-89`; ver
      [security.md](../concepts/security.md) sobre não confiar em relays)
- [ ] `EventVerifier.verify` — implementação é `Unimplemented*`
      (`app/lib/sync/event_verifier.dart:16-26`)

## Onde isso vive no código

`app/lib/sync/`; `app/lib/sync/nostr/`.

## Relacionado

[sync.md](../concepts/sync.md), [protocol.md](../concepts/protocol.md),
[03-cripto-e-chaves.md](03-cripto-e-chaves.md),
[05-go-cli.md](05-go-cli.md) (mesma peça pendente do lado Go).
