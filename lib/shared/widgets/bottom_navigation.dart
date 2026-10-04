import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

/// Barre de navigation principale de l'application (5 onglets), partagée par
/// tous les écrans racine pour éviter les 5 copies divergentes qui existaient
/// avant (icônes actives manquantes sur certains onglets, libellés
/// incohérents...).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool enabled;
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.enabled = true,
  });

  static const _destinations = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      route: RouteNames.home,
    ),
    (
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Parcourir',
      route: RouteNames.browse,
    ),
    (
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Vendre',
      route: RouteNames.publish,
    ),
    (
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
      route: RouteNames.messages,
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      route: RouteNames.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: !enabled
          ? null
          : (index) {
              if (index == currentIndex) return;
              context.go(_destinations[index].route);
            },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF6B7F4D),
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: [
        for (final d in _destinations)
          BottomNavigationBarItem(
            icon: Icon(d.icon),
            activeIcon: Icon(d.activeIcon),
            label: d.label,
          ),
      ],
    );
  }
}
