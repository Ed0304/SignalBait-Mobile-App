import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:signalbait_mobile/screens/scan_screen.dart';
import 'package:signalbait_mobile/screens/ticket_screen.dart';
import 'package:signalbait_mobile/screens/faq_screen.dart';
final GoRouter appRouter = GoRouter(
  initialLocation: '/scan',
  routes: [
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/tickets',
      builder: (context, state) => const TicketScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const FaqScreen(),
    ),
  ],
);