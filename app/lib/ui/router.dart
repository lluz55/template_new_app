import 'package:dl_concept/dl_concept.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import 'screens/showcase_screen.dart';
import 'screens/settings_screen.dart';

/// `go_router` com `ShellRoute` (SPEC §9): uma única shell de navegação
/// adaptativa decide o widget de navegação por breakpoint, preservando o
/// estado de cada aba (`StatefulShellRoute.indexedStack`). Rótulos vêm do
/// sistema de i18n (SPEC §9.2) — nunca string literal aqui.
final appRouter = GoRouter(
  initialLocation: '/showcase',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final l10n = AppLocalizations.of(context)!;
        return AdaptiveScaffold(
          navigationShell: navigationShell,
          destinations: [
            AdaptiveDestination(
              icon: Icons.widgets_outlined,
              selectedIcon: Icons.widgets,
              label: l10n.navShowcase,
            ),
            AdaptiveDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.navSettings,
            ),
          ],
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/showcase',
                builder: (context, state) => const ShowcaseScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen()),
          ],
        ),
      ],
    ),
  ],
);
