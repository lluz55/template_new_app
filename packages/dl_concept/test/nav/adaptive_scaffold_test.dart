import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildTestRouter() => GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AdaptiveScaffold(
            navigationShell: navigationShell,
            destinations: const [
              AdaptiveDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'A',
              ),
              AdaptiveDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'B',
              ),
            ],
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/a',
                  builder: (context, state) =>
                      const Scaffold(body: Text('tela A')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/b',
                  builder: (context, state) =>
                      const Scaffold(body: Text('tela B')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _buildTestRouter()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('compact mostra NavigationBar', (tester) async {
    await pumpAtSize(tester, const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('medium mostra NavigationRail', (tester) async {
    await pumpAtSize(tester, const Size(700, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('expanded mostra NavigationDrawer', (tester) async {
    await pumpAtSize(tester, const Size(1000, 800));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
