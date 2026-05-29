// lib/features/splash/view/splash_screen.dart
// ============================================================
// Project LUCY — Splash Screen
// Displays branding for 2 seconds while loading mock data.
// On success: navigates to /home via go_router.
// On failure: shows retry button (no navigation).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../mock/mock_repository.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

/// Splash screen — entry point of the app.
///
/// Uses [SplashBloc] to manage the init flow:
/// 1. Shows animated LUCY branding.
/// 2. Waits 2 seconds, loads mock data.
/// 3. Navigates to `/home` on success or shows retry on failure.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashBloc(mockRepository: MockRepository())
        ..add(const SplashStarted()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // Navigate to walkthrough on successful data load.
        if (state.status == SplashStatus.success) {
          context.go('/walkthrough');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<SplashBloc, SplashState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ── App Logo / Branding ──────────────────
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── App Name ─────────────────────────────
                    const Text(
                      'LUCY',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Language Unity & Collaborative Youth',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Status Indicator ─────────────────────
                    _buildStatusWidget(context, state),

                    const Spacer(flex: 1),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the bottom section based on current [SplashStatus].
  Widget _buildStatusWidget(BuildContext context, SplashState state) {
    switch (state.status) {
      case SplashStatus.initial:
      case SplashStatus.loading:
        // Show loading spinner.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preparing your learning experience...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        );

      case SplashStatus.failure:
        // Show error message + retry button.
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong.\nPlease try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                width: 160,
                onPressed: () {
                  context
                      .read<SplashBloc>()
                      .add(const SplashRetryRequested());
                },
              ),
            ],
          ),
        );

      case SplashStatus.success:
        // Brief success state (listener handles navigation).
        return const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 36,
        );
    }
  }
}
