
import 'package:go_router/go_router.dart';
import 'package:signalbait_mobile/screens/scan_screen.dart';
import 'package:signalbait_mobile/screens/ticket_screen.dart';
import 'package:signalbait_mobile/screens/faq_screen.dart';
import 'package:signalbait_mobile/widgets/main_layout.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/scan',
  routes: [
    GoRoute(
      path: '/scan',
      builder: (context, state) => const MainLayout(
        child: ScanScreen(),
      ),
    ),
    GoRoute(
      path: '/tickets',
      builder: (context, state) => const MainLayout(
        child: TicketScreen(),
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
