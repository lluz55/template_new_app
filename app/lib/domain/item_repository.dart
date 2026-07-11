import 'item.dart';

/// Caso de uso / porta do domínio para o scaffold de itens. A implementação
/// concreta (`app/lib/data/local/item_local_repository.dart`) fala com o
/// store local — nunca com a rede diretamente (ver
/// knowledge/concepts/architecture.md: "a UI só fala com o store local").
abstract class ItemRepository {
  /// Emite a lista atual sempre que o store local mudar — inclusive quando
  /// a mudança vem de um changeset remoto aplicado pelo sync engine.
  Stream<List<Item>> watchAll();

  Future<void> add(String title);

  Future<void> rename(String id, String title);

  Future<void> toggleDone(String id, {required bool done});

  /// Soft delete (tombstone) — necessário para propagar a remoção para
  /// outros dispositivos (SPEC §6).
  Future<void> remove(String id);
}
