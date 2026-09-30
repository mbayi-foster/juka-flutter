import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';

/// Coquille de l'application : héberge les onglets et la barre de navigation
/// inférieure. Chaque onglet conserve son propre historique et son état.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  /// Branche courante fournie par `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    _ShellDestination(
      label: 'Comptes',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    _ShellDestination(
      label: 'Opérations',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz_rounded,
    ),
    _ShellDestination(
      label: 'Paramètres',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: AppColors.border,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }

  /// Bascule vers l'onglet demandé ; un second appui réinitialise l'onglet.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Description d'un onglet de la barre de navigation.
class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
