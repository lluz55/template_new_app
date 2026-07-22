/// Lista de relays configurável pelo usuário (SPEC §7.3). Como qualquer
/// outro estado de domínio, sincroniza entre os dispositivos do usuário via
/// o mesmo store CRDT — a UI só fala com o store local (ver
/// docs/okf/concepts/architecture.md).
abstract class RelaySettingsRepository {
  /// Emite a lista atual de relays sempre que ela mudar — inclusive quando
  /// a mudança vem de outro dispositivo via sync.
  Stream<List<String>> watchRelays();

  Future<void> setRelays(List<String> urls);
}
