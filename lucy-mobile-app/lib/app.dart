// lib/app.dart
// ============================================================
// Project LUCY — App Root Widget
// Configures MaterialApp with GoRouter and AppTheme.
// Navigation flow: Splash → Walkthrough → Home
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/view/splash_screen.dart';
import 'features/walkthrough/view/walkthrough_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/bloc/wallet_event.dart';
import 'features/wallet/view/wallet_deposit_screen.dart';
import 'features/audio_room/bloc/speak_queue_bloc.dart';
import 'features/audio_room/bloc/sub_level_timer_bloc.dart';
import 'features/audio_room/service/socket_service.dart';
import 'features/audio_room/view/audio_room_screen.dart';
import 'features/audio_room/view/pro_dashboard_screen.dart';
import 'features/podcast/view/podcast_library_screen.dart';

/// Root application widget.
///
/// Sets up:
/// - [GoRouter] with declarative route definitions.
/// - [AppTheme.darkTheme] as the default theme.
/// - Navigation: /splash → /walkthrough → /home → /wallet-deposit
///               /audio-room → /pro-dashboard
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
        path: '/wallet-deposit',
        builder: (context, state) => BlocProvider(
          create: (_) => WalletBloc()..add(const WalletBalanceFetched()),
          child: const WalletDepositScreen(),
        ),
      ),
      GoRoute(
        path: '/audio-room',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SpeakQueueBloc(socketService: SocketService()),
              ),
              BlocProvider(create: (_) => SubLevelTimerBloc()),
              BlocProvider(
                create: (_) => WalletBloc()..add(const WalletBalanceFetched()),
              ),
            ],
            child: AudioRoomScreen(
              roomId: extra['roomId'] ?? 'room_001',
              userId: extra['userId'] ?? 'user_001',
              roomName: extra['roomName'] ?? 'English Room',
              hostUserId: extra['hostUserId'] ?? 'host_001',
              jwtToken: extra['jwtToken'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/pro-dashboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SpeakQueueBloc(socketService: SocketService()),
              ),
              BlocProvider(create: (_) => SubLevelTimerBloc()),
            ],
            child: ProDashboardScreen(
              roomId: extra['roomId'] ?? 'room_001',
            ),
          );
        },
      ),
      GoRoute(
        path: '/podcast-library',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PodcastLibraryScreen(
            userId: extra['userId'] ?? 'user_123',
            accountType: extra['accountType'] ?? 'super',
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
