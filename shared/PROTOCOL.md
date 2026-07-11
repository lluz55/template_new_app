# PROTOCOL.md — Protocolo de sincronização via Nostr

Documento normativo do protocolo usado entre o app (Dart) e a CLI (Go).
Complementa o schema em [`proto/changeset.proto`](proto/changeset.proto) e a
visão geral em [SPEC.md §7-8](/SPEC.md#7-sincronização-via-nostr).

## 1. Kinds Nostr usados

| Evento     | Kind      | Addressable? | Retenção no relay | Payload           |
|------------|-----------|--------------|--------------------|--------------------|
| Snapshot   | `30078`   | sim (NIP-78) | só o mais recente  | `Snapshot` (proto), cifrado NIP-44 |
| Changeset  | `9411`    | não          | append/retido       | `Changeset` (proto), cifrado NIP-44 |

- `9411` é a constante do template, `TEMPLATE_CHANGESET_KIND` (definida em
  `app/lib/sync/nostr/kinds.dart` e `cli/internal/protocol/kinds.go`).
  Está na faixa regular (1000–9999) recomendada pela SPEC — **evite** a faixa
  efêmera (20000–29999), pois relays não a armazenam. Trocar esse número é
  uma mudança de protocolo: exige coordenar todos os dispositivos do usuário
  (ver §4 abaixo).
- Evento de snapshot usa a tag `d` (NIP-78) com valor fixo
  `tpl-new-app-snapshot` para ser endereçável e substituível por
  `pubkey` + `d` — cada novo snapshot substitui o anterior no relay.
- Poda de changesets antigos (após um novo snapshot) usa **NIP-09**
  (`kind: 5`, evento de deleção) referenciando os `id`s dos changesets
  cobertos pelo snapshot.

## 2. Estrutura do payload

Ambos os eventos carregam, no campo `content`, o resultado de:

1. Serializar a mensagem protobuf (`Changeset` ou `Snapshot`, ver
   `proto/changeset.proto`) em bytes binários.
2. Cifrar esses bytes com **NIP-44 v2** (ChaCha20 + HMAC-SHA256), usando a
   própria chave pública do usuário como par (**auto-cifra**): o remetente e
   o destinatário são a mesma identidade, entre os próprios dispositivos.
3. Codificar o resultado em base64 (conforme NIP-44) para caber no `content`
   de um evento Nostr.

```
content = base64( nip44_encrypt(secret_key, own_pubkey, protobuf_bytes) )
```

Nenhum dado é publicado em texto plano — nem mesmo metadados de domínio
(nomes de tabela/campo ficam dentro do payload cifrado).

## 3. Versionamento do schema (`schema_version`)

- `schema_version` (campo 1 de `Changeset` e `Snapshot`) começa em `1`.
- Mudanças **compatíveis** (novo campo opcional, nova tabela/campo de
  domínio dentro de `value_json`): não incrementam `schema_version`.
  Clientes antigos devem ignorar com segurança campos desconhecidos.
- Mudanças **incompatíveis** (remoção/renomeação de campo do proto, mudança
  de semântica de um campo existente): incrementam `schema_version`.
  Clientes leem `schema_version` antes de decodificar e recusam (ou migram)
  payloads de uma versão que não sabem tratar.

## 4. Constantes compartilhadas

| Constante                  | Valor   | Onde vive                                              |
|-----------------------------|---------|---------------------------------------------------------|
| `TEMPLATE_CHANGESET_KIND`   | `9411`  | `app/lib/sync/nostr/kinds.dart`, `cli/internal/protocol/kinds.go` |
| `TEMPLATE_SNAPSHOT_KIND`    | `30078` | idem (NIP-78 padrão)                                    |
| `SNAPSHOT_D_TAG`            | `tpl-new-app-snapshot` | idem                                       |
| `SCHEMA_VERSION` atual      | `1`     | primeiro campo de `Changeset`/`Snapshot`                |

## 5. Codegen

O `.proto` é a fonte única. Gerar bindings Dart e Go com:

```bash
scripts/gen-proto.sh
```

O script roda `protoc` (disponível nos devShells `app-linux`/`cli`, ver
`flake.nix`) com os plugins `protoc-gen-dart` e `protoc-gen-go`. Saída:
- Dart: `app/lib/sync/proto/` (gerado — não versionado, ver `.gitignore`)
- Go: `cli/internal/protocol/syncv1/` (gerado — não versionado)

## 6. Interoperabilidade

Um teste de interop (SPEC §16) gera um `Changeset` em Dart, serializa,
decifra e decodifica em Go (e vice-versa), garantindo que os dois lados
concordam byte a byte sobre o formato do payload.
