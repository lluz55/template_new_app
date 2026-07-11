import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'breakpoint.dart';

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Shell de navegação única (SPEC §9): decide `NavigationBar` (compact),
/// `NavigationRail` (medium) ou `NavigationDrawer` fixa (expanded) por
/// `LayoutBuilder`, preservando o estado das abas via
/// `StatefulNavigationShell` do go_router.
///
/// Alvos de toque ≥48dp em compact/medium; em expanded, o conteúdo ganha
/// largura máxima e a navegação vira sidebar fixa (list-detail friendly).
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<AdaptiveDestination> destinations;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = breakpointForWidth(constraints.maxWidth);
        switch (breakpoint) {
          case AppBreakpoint.compact:
            return _CompactLayout(
              navigationShell: navigationShell,
              destinations: destinations,
              onDestinationSelected: _onDestinationSelected,
            );
          case AppBreakpoint.medium:
            return _RailLayout(
              navigationShell: navigationShell,
              destinations: destinations,
              extended: false,
              onDestinationSelected: _onDestinationSelected,
            );
          case AppBreakpoint.expanded:
            return _DrawerLayout(
              navigationShell: navigationShell,
              destinations: destinations,
              onDestinationSelected: _onDestinationSelected,
            );
        }
      },
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.navigationShell,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.navigationShell,
    required this.destinations,
    required this.extended,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final List<AdaptiveDestination> destinations;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: extended ? null : NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _DrawerLayout extends StatelessWidget {
  const _DrawerLayout({
    required this.navigationShell,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: NavigationDrawer(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: onDestinationSelected,
              children: [
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
