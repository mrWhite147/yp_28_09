import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/products')) currentIndex = 1;
    if (location.startsWith('/manufacturers')) currentIndex = 2;
    if (location.startsWith('/customers')) currentIndex = 3;

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
      const NavigationDestination(icon: Icon(Icons.devices), label: 'Товары'),
      const NavigationDestination(icon: Icon(Icons.business), label: 'Бренды'),
      const NavigationDestination(
        icon: Icon(Icons.people),
        label: 'Покупатели',
      ),
    ];

    void onNavigate(int index) {
      if (index == 0) context.go('/');
      if (index == 1) context.go('/products');
      if (index == 2) context.go('/manufacturers');
      if (index == 3) context.go('/customers');
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onNavigate,
                labelType: width > 1200
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected,
                destinations: destinations
                    .map(
                      (d) => NavigationRailDestination(
                        icon: d.icon,
                        label: Text(d.label),
                      ),
                    )
                    .toList(),
              ),
            if (!isMobile) const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onNavigate,
              destinations: destinations,
            )
          : null,
    );
  }
}
