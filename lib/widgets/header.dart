
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 8),
          Text('SignalBait'),
        ],
      ),
      backgroundColor: const Color(0xFF2459A9),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}
