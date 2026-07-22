---
type: task
phase: 2
status: in-progress
---

# Fase 2 — Store local

## Escopo (SPEC §17)

`sqlite_crdt` + SQLCipher; CRUD com merge CRDT.

## Sub-tarefas

- [x] `sqlite_crdt` integrado — HLC + LWW por campo, tombstones para soft
      delete (ver [data-model.md](../concepts/data-model.md))
- [x] CRUD funcional sobre o store local (ex.:
      `app/lib/data/item_local_repository.dart`)
- [ ] SQLCipher: banco hoje abre **sem cifra** de propósito — bloqueado até o
      `KeyManager` (Fase 3) gerir a chave derivada. Ver comentário em
      `app/lib/data/local/app_database.dart:8-16` (inclui os passos exatos
      para ligar: `sqlite3_flutter_libs` com suporte a SQLCipher + `PRAGMA
      key = '<derivado do KeyManager>'` como primeira instrução da conexão)

## Onde isso vive no código

`app/lib/data/local/app_database.dart`; `app/lib/data/`.

## Relacionado

[data-model.md](../concepts/data-model.md),
[03-cripto-e-chaves.md](03-cripto-e-chaves.md) (dependência do item pendente).
