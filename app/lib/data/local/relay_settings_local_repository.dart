import 'dart:convert';

import '../../domain/relay_settings_repository.dart';
import 'app_database.dart';

/// Relays sensatos por padrão (SPEC §7.3) — mesmos da CLI Go
/// (`cli/cmd/push.go`, flag `--relays`). Não é protocolo compartilhado
/// (não precisa bater byte a byte entre app e CLI), só uma escolha razoável
/// replicada nos dois lugares.
const defaultRelayUrls = ['wss://relay.damus.io', 'wss://nos.lol'];

const _settingsRowId = 'app';

/// Implementação do [RelaySettingsRepository] sobre o store local CRDT
/// (`AppDatabase`) — mesmo tratamento de [ItemLocalRepository]: única
/// camada que sabe falar SQL para esta configuração.
class RelaySettingsLocalRepository implements RelaySettingsRepository {
  RelaySettingsLocalRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<String>> watchRelays() {
    return _db.crdt
        .watch('SELECT relay_urls FROM settings WHERE id = ?1',
            () => [_settingsRowId])
        .map((rows) {
      if (rows.isEmpty) return defaultRelayUrls;
      return (jsonDecode(rows.single['relay_urls'] as String) as List<dynamic>)
          .cast<String>();
    });
  }

  @override
  Future<void> setRelays(List<String> urls) async {
    final json = jsonEncode(urls);
    await _db.crdt.execute(
      '''
      INSERT INTO settings (id, relay_urls) VALUES (?1, ?2)
      ON CONFLICT(id) DO UPDATE SET relay_urls = excluded.relay_urls
      ''',
      [_settingsRowId, json],
    );
  }
}
