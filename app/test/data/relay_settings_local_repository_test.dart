import 'package:flutter_test/flutter_test.dart';
import 'package:tpl_new_app/data/local/app_database.dart';
import 'package:tpl_new_app/data/local/relay_settings_local_repository.dart';

void main() {
  late AppDatabase database;
  late RelaySettingsLocalRepository repository;

  setUp(() async {
    database = await AppDatabase.openInMemory();
    repository = RelaySettingsLocalRepository(database);
  });

  tearDown(() => database.close());

  test('sem relays salvos, usa os padrões (SPEC §7.3)', () async {
    final urls = await repository.watchRelays().first;
    expect(urls, defaultRelayUrls);
  });

  test('setRelays substitui a lista e watchRelays reflete a mudança', () async {
    await repository.setRelays(['wss://relay.example.org']);
    final urls = await repository.watchRelays().first;
    expect(urls, ['wss://relay.example.org']);
  });

  test('setRelays duas vezes atualiza a mesma linha (não duplica)', () async {
    await repository.setRelays(['wss://a.example.org']);
    await repository.setRelays(['wss://b.example.org', 'wss://c.example.org']);

    final urls = await repository.watchRelays().first;
    expect(urls, ['wss://b.example.org', 'wss://c.example.org']);
  });
}
