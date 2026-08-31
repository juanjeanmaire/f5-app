import 'package:flutter/material.dart';

import '../../features/groups/presentation/groups_list_screen.dart';
import '../../features/matches/presentation/my_matches_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../theme/app_theme.dart';

/// Shell con la barra de navegación inferior (perfil / mis partidos / home),
/// de borde a borde. Cambia de pestaña sin perder el estado de cada una
/// (IndexedStack) — las pantallas que se empujan desde adentro (ej. el
/// detalle de un grupo) tapan esta barra, como es esperable.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 2; // Home (grupos) seleccionado por defecto

  static const _screens = [
    ProfileScreen(),
    MyMatchesScreen(),
    GroupsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: 64,
        color: AppColors.navyDeep,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavIcon(
              icon: Icons.person_outline,
              tooltip: 'Mi perfil',
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _NavIcon(
              icon: Icons.schedule,
              tooltip: 'Mis partidos',
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _NavIcon(
              icon: Icons.home_filled,
              tooltip: 'Inicio',
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.size = 26,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(
        icon,
        size: size,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : AppColors.cream.withValues(alpha: 0.6),
      ),
    );
  }
}
