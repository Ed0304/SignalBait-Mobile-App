
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF151515);
  static const Color neonGreen = Color(0xFF80FF80);
  static const Color muted = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SignalBait logo
                Image.asset(
                  'lib/assets/signalbait_logo.png',
                  height: 210,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      size: 120,
                      color: neonGreen,
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Welcome to SignalBait',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Your AI-powered companion for identifying '
                  'suspicious messages and potential scams.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 36),

                // FAQ button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/help'),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text('FAQ · First-time users'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: neonGreen,
                      side: const BorderSide(color: neonGreen),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Scan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/scan'),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Analyze a message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      foregroundColor: background,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'STAY ALERT. STAY PROTECTED.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
