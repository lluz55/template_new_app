// Package protocol contém as constantes normativas do protocolo de sync
// (shared/PROTOCOL.md) — espelha app/lib/sync/nostr/kinds.dart. Mudar
// qualquer valor aqui é uma mudança de protocolo coordenada nos dois lados.
package protocol

const (
	TemplateSnapshotKind  = 30078 // NIP-78, addressable
	TemplateChangesetKind = 9411  // TEMPLATE_CHANGESET_KIND
	SnapshotDTag          = "tpl-new-app-snapshot"
	CurrentSchemaVersion  = 1
)
