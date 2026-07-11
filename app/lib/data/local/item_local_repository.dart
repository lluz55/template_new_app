import 'package:uuid/uuid.dart';

import '../../domain/item.dart';
import '../../domain/item_repository.dart';
import 'app_database.dart';

/// Implementação do [ItemRepository] sobre o store local CRDT
/// (`AppDatabase`). Única camada que sabe falar SQL — domínio e UI não
/// dependem de `sqlite_crdt` diretamente.
class ItemLocalRepository implements ItemRepository {
  ItemLocalRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<Item>> watchAll() {
    return _db.crdt
        .watch(
            'SELECT id, title, done FROM items WHERE is_deleted = 0 ORDER BY title')
        .map((rows) => rows.map(Item.fromRow).toList(growable: false));
  }

  @override
  Future<void> add(String title) async {
    final id = _uuid.v4();
    await _db.crdt.execute(
      'INSERT INTO items (id, title, done) VALUES (?1, ?2, 0)',
      [id, title],
    );
  }

  @override
  Future<void> rename(String id, String title) async {
    await _db.crdt.execute(
      'UPDATE items SET title = ?1 WHERE id = ?2',
      [title, id],
    );
  }

  @override
  Future<void> toggleDone(String id, {required bool done}) async {
    await _db.crdt.execute(
      'UPDATE items SET done = ?1 WHERE id = ?2',
      [done ? 1 : 0, id],
    );
  }

  @override
  Future<void> remove(String id) async {
    // Soft delete: sqlite_crdt marca is_deleted=1 automaticamente para
    // DELETE — a linha continua existindo como tombstone (SPEC §6).
    await _db.crdt.execute('DELETE FROM items WHERE id = ?1', [id]);
  }
}
