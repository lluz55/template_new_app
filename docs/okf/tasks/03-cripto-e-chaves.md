---
type: task
phase: 3
status: in-progress
---

# Fase 3 — Cripto e chaves

## Escopo (SPEC §17)

Geração de chave, storage seguro por plataforma, NIP-44 (auto-cifra),
NIP-07/46 na web.

## Sub-tarefas

- [x] `KeyManager` — geração de chave (ver
      [security.md](../concepts/security.md))
- [ ] `KeyManager` na Web: hoje não deve ser usado — pendente NIP-07/46 (ver
      `app/lib/crypto/key_manager.dart:34`)
- [ ] `Nip44Cipher.encrypt`/`.decrypt` — interface existe, implementação é
      `Unimplemented*` (ver `app/lib/sync/nip44_cipher.dart:24-51`; **não
      escreva teste real contra o stub**, teste o contrato — ver
      [testing.md](../concepts/testing.md))
- [ ] Ligar SQLCipher no store local com a chave derivada daqui (item
      pendente de [02-store-local.md](02-store-local.md))

## Onde isso vive no código

`app/lib/crypto/`; `app/lib/sync/nip44_cipher.dart`.

## Relacionado

[security.md](../concepts/security.md),
[02-store-local.md](02-store-local.md), [04-sync-engine.md](04-sync-engine.md).
