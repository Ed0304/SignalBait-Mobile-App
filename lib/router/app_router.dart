
import 'package:go_router/go_router.dart';
import 'package:signalbait_mobile/screens/scan_screen.dart';
import 'package:signalbait_mobile/screens/ticket_screen.dart';
import 'package:signalbait_mobile/screens/faq_screen.dart';
import 'package:signalbait_mobile/widgets/main_layout.dart';
import 'package:signalbait_mobile/screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const MainLayout(
        child: SplashScreen()
      ),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const MainLayout(
        child: ScanScreen()
      ),
    ),
    GoRoute(
      path: '/tickets',
      builder: (context, state) => const MainLayout(
        child: TicketScreen()
      ),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const MainLayout(
        child: FaqScreen(),
      ),
    ),
  ],
);
