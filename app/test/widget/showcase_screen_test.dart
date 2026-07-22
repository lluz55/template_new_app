import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpl_new_app/data/providers.dart';
import 'package:tpl_new_app/domain/item.dart';
import 'package:tpl_new_app/domain/item_repository.dart';
import 'package:tpl_new_app/l10n/gen/app_localizations.dart';
import 'package:tpl_new_app/ui/screens/showcase_screen.dart';

/// Repositório fake: `Stream` síncrona local, sem `sqflite_common_ffi`/
/// isolate nenhum. `ShowcaseScreen` só depende da interface
/// [ItemRepository] pra sua seção de lista com sync — testar contra o fake
/// aqui é mais rápido e confiável do que subir um banco real por widget, e
/// evita um problema conhecido: `sqflite_common_ffi` resolve consultas num
/// isolate real, que o clock sintético de `tester.pump()` não avança de
/// forma confiável em `testWidgets` (ver
/// `docs/okf/concepts/testing.md`).
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
          home: const ShowcaseScreen(),
        ),
      );

  // A tela tem várias seções empilhadas num ListView — num viewport padrão
  // de teste (800x600), as últimas ficam fora da área visível e o Flutter
  // não monta elementos fora do viewport (nem no ListView(children:) não-
  // lazy). Um viewport bem alto evita depender de scroll pra encontrar
  // widgets das seções finais (ex.: a lista com sync).
  Future<void> pumpTall(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pump();
  }

  testWidgets('mostra todas as seções do showcase', (tester) async {
    final repository = _FakeItemRepository(const []);

    await pumpTall(tester, buildApp(repository));

    expect(find.byType(AppSectionHeader), findsNWidgets(6));
    expect(find.byType(FilledButton), findsWidgets);
    expect(find.byType(OutlinedButton), findsWidgets);
    expect(find.byType(FilterChip), findsNWidgets(3));
    expect(find.byType(AppBadge), findsNWidgets(3));
  });

  testWidgets('lista com itens mostra Card + AppDismissibleListItem',
      (tester) async {
    final repository = _FakeItemRepository([
      const Item(id: '1', title: 'Comprar leite', done: false),
      const Item(id: '2', title: 'Lavar louça', done: true),
    ]);

    await pumpTall(tester, buildApp(repository));

    expect(find.byType(AppDismissibleListItem), findsNWidgets(2));
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Comprar leite'), findsOneWidget);
    expect(find.text('Lavar louça'), findsOneWidget);
  });

  testWidgets('lista vazia mostra AppEmptyState pra seção de sync',
      (tester) async {
    final repository = _FakeItemRepository(const []);

    await pumpTall(tester, buildApp(repository));

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(AppDismissibleListItem), findsNothing);
  });

  testWidgets('chip de exemplo alterna seleção ao tocar', (tester) async {
    final repository = _FakeItemRepository(const []);

    await pumpTall(tester, buildApp(repository));

    final chip2 = find.widgetWithText(FilterChip, 'Chip 2');
    expect(tester.widget<FilterChip>(chip2).selected, isFalse);

    await tester.tap(chip2);
    await tester.pump();

    expect(tester.widget<FilterChip>(chip2).selected, isTrue);
  });
}
