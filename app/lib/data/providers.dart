import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/item.dart';
import '../domain/item_repository.dart';
import '../domain/relay_settings_repository.dart';
import 'local/app_database.dart';
import 'local/item_local_repository.dart';
import 'local/relay_settings_local_repository.dart';

/// Sobrescrito em `main.dart` com a instância já aberta (SPEC: abrir o
/// banco é assíncrono e acontece antes de `runApp`, para a UI já nascer
/// com dados locais disponíveis — sem tela de loading no caminho feliz).
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
      'appDatabaseProvider deve ser sobrescrito em main()'),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemLocalRepository(ref.watch(appDatabaseProvider)),
);

final itemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(itemRepositoryProvider).watchAll(),
);

final relaySettingsRepositoryProvider = Provider<RelaySettingsRepository>(
  (ref) => RelaySettingsLocalRepository(ref.watch(appDatabaseProvider)),
);

final relaysProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(relaySettingsRepositoryProvider).watchRelays(),
);
