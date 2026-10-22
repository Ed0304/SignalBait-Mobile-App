
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    //AppBar -> Application 'Header' in flutter
    return AppBar(
      title: const Row(
        //Additional items
        children: [
          Icon(Icons.shield_outlined),
          SizedBox(width: 8),
          Text('SignalBait'),
        ],
        //Similar to CSS, describe the colors, size, etc.
      ),
      backgroundColor: const Color(0xFF2459A9),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}
