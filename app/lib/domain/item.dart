/// Modelo de domínio do scaffold de referência (SPEC §1): uma lista simples
/// de itens (criar/editar/apagar) que sincroniza entre dispositivos.
///
/// Não depende de Flutter, SQLite ou Nostr — camada de domínio pura
/// (ver knowledge/concepts/architecture.md).
class Item {
  const Item({
    required this.id,
    required this.title,
    required this.done,
  });

  final String id;
  final String title;
  final bool done;

  Item copyWith({String? title, bool? done}) => Item(
        id: id,
        title: title ?? this.title,
        done: done ?? this.done,
      );

  /// Constrói a partir de uma linha do store local (`Map` retornado por
  /// `sqlite_crdt`). Colunas de metadados CRDT (`hlc`, `modified`,
  /// `is_deleted`) são geridas pelo store, não pelo domínio.
  factory Item.fromRow(Map<String, Object?> row) => Item(
        id: row['id'] as String,
        title: row['title'] as String,
        done: (row['done'] as int) == 1,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'done': done ? 1 : 0,
      };
}
