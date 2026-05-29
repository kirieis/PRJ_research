// lib/app.dart
// ============================================================
// Project LUCY — App Root Widget
// Configures MaterialApp with GoRouter and AppTheme.
// Navigation flow: Splash → Walkthrough → Home
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/view/splash_screen.dart';
import 'features/walkthrough/view/walkthrough_screen.dart';
import 'features/home/view/home_screen.dart';

/// Root application widget.
///
/// Sets up:
/// - [GoRouter] with declarative route definitions.
/// - [AppTheme.darkTheme] as the default theme.
/// - Navigation: /splash → /walkthrough → /home
class LucyApp extends StatelessWidget {
  LucyApp({super.key});

  /// GoRouter configuration — single source of truth for navigation.
  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/walkthrough',
        builder: (context, state) => const WalkthroughScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LUCY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
