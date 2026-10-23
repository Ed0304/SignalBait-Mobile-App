
import 'package:flutter/material.dart';
import 'package:signalbait_mobile/router/app_router.dart';
void main() {
  // The main script to run the application.
  runApp(const SignalBaitApp());
}

class SignalBaitApp extends StatelessWidget {
  const SignalBaitApp({super.key});

  @override
  Widget build(BuildContext context) {
    //MaterialApp.router asks the app to use the defined router.
    //Normal MaterialApp uses 'home'
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'JetBrainsMono',
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF80FF80),
          surface: Color(0xFF151515),
        ),
      ),
      routerConfig: appRouter
    );
  }
}