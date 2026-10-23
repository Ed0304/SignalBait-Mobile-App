
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2459A9),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter
    );
  }
}