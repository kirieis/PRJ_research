// lib/app.dart
// ============================================================
// Project LUCY — App Root Widget
// Configures MaterialApp with GoRouter and AppTheme.
//
// Navigation flow:
//   Splash → Walkthrough → Login/Register → /main (ShellRoute with BottomNav)
//   Full-screen overlays: /audio-room, /pro-dashboard
//
// Mobile-first restructuring:
//   - /main → MainShell with BottomNavigationBar
//   - Removed direct routes to podcast/wallet (now inside tabs)
//   - Audio Room & Pro Dashboard are full-screen push routes
//   - Auth flow: /login ↔ /register inserted before /main
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/level/bloc/level_bloc.dart';
import 'features/level/bloc/level_event.dart';
import 'features/splash/view/splash_screen.dart';
import 'features/walkthrough/view/walkthrough_screen.dart';
import 'features/home/view/main_shell.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/bloc/wallet_event.dart';
import 'features/audio_room/bloc/speak_queue_bloc.dart';
import 'features/audio_room/bloc/sub_level_timer_bloc.dart';
import 'features/audio_room/service/socket_service.dart';
import 'features/audio_room/bloc/room_config_bloc.dart';
import 'features/audio_room/view/audio_room_screen.dart';
import 'features/audio_room/view/room_config_screen.dart';
import 'features/audio_room/view/pro_dashboard_screen.dart';
import 'features/ai_suggestion/bloc/ai_suggestion_bloc.dart';
import 'features/post_session/model/session_report.dart';
import 'features/post_session/view/post_session_screen.dart';
import 'features/wallet/view/wallet_deposit_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/register_screen.dart';

/// Root application widget.
///
/// Sets up:
/// - [GoRouter] with declarative route definitions.
/// - [AppTheme.darkTheme] as the default theme.
/// - Navigation: /splash → /walkthrough → /main (BottomNav shell)
///               /audio-room, /pro-dashboard (full-screen overlays)
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

      // ── Auth Routes ──────────────────────────────────────────
      // Login and Register screens sit between Walkthrough and Main.
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main Shell (Bottom Navigation) ──────────────────────
      // This is the primary navigation hub with 4 tabs:
      // Home (Room Lobby), Podcast, Wallet, Profile
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainShell(),
      ),

      // Legacy route — redirect /home to /main for backward compat
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/main',
      ),

      // ── Full-Screen Overlay Routes ──────────────────────────
      // These routes push on TOP of the MainShell (no bottom nav)

      // Room Config — pre-room settings (avatar, voice filter)
      GoRoute(
        path: '/room-config',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BlocProvider(
            create: (_) => RoomConfigBloc(),
            child: RoomConfigScreen(
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
              BlocProvider(create: (_) => AiSuggestionBloc()),
            ],
            child: AudioRoomScreen(
              roomId: extra['roomId'] ?? 'room_001',
              userId: extra['userId'] ?? 'user_001',
              roomName: extra['roomName'] ?? 'English Room',
              hostUserId: extra['hostUserId'] ?? 'host_001',
              jwtToken: extra['jwtToken'],
              isAvatarHidden: extra['isAvatarHidden'] ?? false,
              voiceFilter: extra['voiceFilter'] ?? 'normal',
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

      // ── Post-Session Feedback ──────────────────────────────
      GoRoute(
        path: '/post-session',
        builder: (context, state) {
          final report = state.extra as SessionReport? ??
              SessionReport.mock();
          return PostSessionScreen(report: report);
        },
      ),

      // ── Wallet Deposit (VietQR) ─────────────────────────────
      GoRoute(
        path: '/wallet-deposit',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => WalletBloc()..add(const WalletBalanceFetched()),
            child: const WalletDepositScreen(),
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LevelBloc()..add(const LevelProgressLoaded()),
        ),
      ],
      child: MaterialApp.router(
        title: 'LUCY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
