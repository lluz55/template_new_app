import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tpl_new_app/data/local/app_database.dart';
import 'package:tpl_new_app/data/providers.dart';
import 'package:tpl_new_app/main.dart';

/// Cobre o requisito de UX em celular/tablet/desktop do SPEC §9: a shell de
/// navegação deve mostrar o widget certo em cada um dos três breakpoints.
void main() {
  late AppDatabase database;

  setUp(() async {
    database = await AppDatabase.openInMemory();
  });

  tearDown(() => database.close());

  /// Não usar `pumpAndSettle()` aqui: a seção de sync da tela (`ShowcaseScreen`)
  /// mostra um `CircularProgressIndicator` enquanto `itemsProvider` não
  /// emite o primeiro valor — é uma animação indeterminada (ticker que
  /// nunca para sozinho), então `pumpAndSettle()` trava indefinidamente
  /// enquanto o loading está de pé. Não é um deadlock do app: a shell de
  /// navegação (o que este teste verifica) já está montada e estável bem
  /// antes disso, então alguns `pump()` com frames explícitos bastam.
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const App(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('compact (celular) mostra NavigationBar', (tester) async {
    await pumpAtSize(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('medium (tablet) mostra NavigationRail', (tester) async {
    await pumpAtSize(tester, const Size(700, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('expanded (desktop) mostra NavigationDrawer', (tester) async {
    await pumpAtSize(tester, const Size(1000, 800));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
