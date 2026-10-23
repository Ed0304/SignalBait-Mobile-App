
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'header.dart';
import 'footer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  // Navigate to the route associated with the selected tab.
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/scan');
        break;
      case 1:
        context.go('/tickets');
        break;
      case 2:
        context.go('/help');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the selected tab from the current route.
    final path = GoRouterState.of(context).uri.path;

    final currentIndex = switch (path) {
      '/tickets' => 1,
      '/help' => 2,
      _ => 0,
    };

    return Scaffold(
      appBar: const Header(),
      body: child,
      bottomNavigationBar: Footer(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
      ),
    );
  }
}
