/// Constantes de protocolo compartilhadas com a CLI Go
/// (`cli/internal/protocol/kinds.go`) — fonte normativa em
/// `shared/PROTOCOL.md`. Mudar qualquer valor aqui é uma mudança de
/// protocolo: precisa ser coordenada nos dois lados e registrada lá.
const int templateSnapshotKind = 30078; // NIP-78, addressable
const int templateChangesetKind = 9411; // TEMPLATE_CHANGESET_KIND
const String snapshotDTag = 'tpl-new-app-snapshot';
const int currentSchemaVersion = 1;
