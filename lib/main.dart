
import 'package:flutter/material.dart';
import 'package:signalbait_mobile/widgets/main_layout.dart';
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

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check suspicious messages before you trust them.',
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade100,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your account will be suspended. '
                    'Click this link immediately!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Scan message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
