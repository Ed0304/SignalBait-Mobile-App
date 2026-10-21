
import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';

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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
