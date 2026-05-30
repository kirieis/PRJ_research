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
import 'features/audio_room/view/audio_room_screen.dart';
import 'features/pro_dashboard/view/pro_dashboard_screen.dart';

/// Root application widget.
///
/// Sets up:
/// - [GoRouter] with declarative route definitions.
/// - [AppTheme.darkTheme] as the default theme.
/// - Navigation: /splash → /walkthrough → /home → /audio-room → /pro-dashboard
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
      GoRoute(
        path: '/audio-room',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AudioRoomScreen(
            roomId: extra['roomId'] as String? ?? '',
            channelName: extra['channelName'] as String? ?? '',
            userId: extra['userId'] as String? ?? '',
            displayName: extra['displayName'] as String? ?? 'Anonymous',
            agoraToken: extra['agoraToken'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/pro-dashboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProDashboardScreen(
            roomId: extra['roomId'] as String? ?? '',
            userId: extra['userId'] as String? ?? '',
            displayName: extra['displayName'] as String? ?? 'Anonymous',
            role: extra['role'] as String? ?? 'learner',
          );
        },
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
