import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../src/core/providers/providers.dart';
import '../../../../src/core/widgets/responsive_layout.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/journals')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/export')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0; // Default to Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/journals');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/export');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return ResponsiveLayout(
      mobile: Scaffold(
        body: child,
        bottomNavigationBar: selectedIndex < 5
            ? NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (idx) => _onItemTapped(idx, context),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined),
                    selectedIcon: Icon(Icons.auto_stories_rounded),
                    label: 'Journals',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.download_outlined),
                    selectedIcon: Icon(Icons.download_rounded),
                    label: 'Export',
                  ),
                ],
              )
            : null,
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Journal Hub',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // User Profile info
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              child: Text(user.fullName[0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Navigation Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _SidebarMenuItem(
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard_rounded,
                          label: 'Dashboard',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onItemTapped(0, context),
                        ),
                        _SidebarMenuItem(
                          icon: Icons.auto_stories_outlined,
                          selectedIcon: Icons.auto_stories_rounded,
                          label: 'Journal Entries',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onItemTapped(1, context),
                        ),
                        _SidebarMenuItem(
                          icon: Icons.calendar_month_outlined,
                          selectedIcon: Icons.calendar_month_rounded,
                          label: 'Calendar View',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onItemTapped(2, context),
                        ),
                        _SidebarMenuItem(
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          isSelected: selectedIndex == 3,
                          onTap: () => _onItemTapped(3, context),
                        ),
                        _SidebarMenuItem(
                          icon: Icons.download_outlined,
                          selectedIcon: Icons.download_rounded,
                          label: 'Export Data',
                          isSelected: selectedIndex == 4,
                          onTap: () => _onItemTapped(4, context),
                        ),
                        _SidebarMenuItem(
                          icon: Icons.settings_outlined,
                          selectedIcon: Icons.settings_rounded,
                          label: 'Settings',
                          isSelected: selectedIndex == 5,
                          onTap: () => _onItemTapped(5, context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Logout action button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Expanded content on right side
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: isSelected,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
        selectedColor: theme.colorScheme.primary,
        iconColor: theme.colorScheme.onSurface.withOpacity(0.6),
        textColor: theme.colorScheme.onSurface.withOpacity(0.7),
        leading: Icon(isSelected ? selectedIcon : icon),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
