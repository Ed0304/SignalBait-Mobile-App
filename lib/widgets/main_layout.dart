
import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  //underline before name turns this function to private.
  void _onTabTapped(int index) {
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
    //Scaffold: The app's skeleton, describes the structure of the UI.
    return Scaffold(
      appBar: const Header(),
      body: widget.child,
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
