import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpl_new_app/data/providers.dart';
import 'package:tpl_new_app/domain/item.dart';
import 'package:tpl_new_app/domain/item_repository.dart';
import 'package:tpl_new_app/l10n/gen/app_localizations.dart';
import 'package:tpl_new_app/ui/screens/items_screen.dart';

/// Repositório fake: `Stream` síncrona local, sem `sqflite_common_ffi`/
/// isolate nenhum. `ItemsScreen` só depende da interface [ItemRepository]
/// (SPEC — UI fala com o domínio, não com o store) — testar contra o fake
/// aqui é mais rápido e confiável do que subir um banco real por widget, e
/// evita um problema conhecido: `sqflite_common_ffi` resolve consultas num
/// isolate real, que o clock sintético de `tester.pump()` não avança de
/// forma confiável em `testWidgets` (o comportamento real do repositório já
/// é coberto por `app/test/data/item_local_repository_test.dart`, com
/// `test()` puro/async real, sem esse problema).
class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository(List<Item> initial) : _stream = Stream.value(initial);

  final Stream<List<Item>> _stream;

  @override
  Stream<List<Item>> watchAll() => _stream;

  @override
  Future<void> add(String title) async {}

  @override
  Future<void> rename(String id, String title) async {}

  @override
  Future<void> toggleDone(String id, {required bool done}) async {}

  @override
  Future<void> remove(String id) async {}
}

void main() {
  Widget buildApp(ItemRepository repository) => ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const ItemsScreen(),
        ),
      );

  testWidgets('lista com itens mostra Card + AppDismissibleListItem',
      (tester) async {
    final repository = _FakeItemRepository([
      const Item(id: '1', title: 'Comprar leite', done: false),
      const Item(id: '2', title: 'Lavar louça', done: true),
    ]);

    await tester.pumpWidget(buildApp(repository));
    await tester.pump();

    expect(find.byType(Card), findsNWidgets(2));
    expect(find.byType(AppDismissibleListItem), findsNWidgets(2));
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Comprar leite'), findsOneWidget);
    expect(find.text('Lavar louça'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsNothing);
  });

  testWidgets('lista vazia mostra AppEmptyState, sem Card', (tester) async {
    final repository = _FakeItemRepository(const []);

    await tester.pumpWidget(buildApp(repository));
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
