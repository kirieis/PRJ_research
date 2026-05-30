// lib/features/pro_dashboard/view/pro_dashboard_screen.dart
// ============================================================
// Project LUCY — Pro Dashboard Screen
// Main screen composing 3 zones: sub-level, speak queue, pin.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../audio_room/service/socket_service.dart';
import '../bloc/pro_dashboard_bloc.dart';
import '../bloc/pro_dashboard_event.dart';
import '../bloc/pro_dashboard_state.dart';
import '../model/auth_state.dart';
import '../service/pro_api_service.dart';
import '../widget/pin_resource_panel.dart';
import '../widget/speak_queue_panel_pro.dart';
import '../widget/sublevel_control_panel.dart';

/// Pro Dashboard screen — moderator control panel for audio rooms.
///
/// Receives room params via GoRouter extras.
/// Creates [ProDashboardBloc] and dispatches [ProDashboardStarted].
///
/// Layout:
/// ```
/// ┌─────────────────────────────────┐
/// │ AppBar: Pro Dashboard    [LIVE] │
/// ├─────────────────────────────────┤
/// │ Zone 1: SubLevel Control        │ ← Only if canModerate
/// │ Zone 2: Speaking Queue          │
/// │ Zone 3: Pinned Resources        │
/// └─────────────────────────────────┘
/// ```
class ProDashboardScreen extends StatelessWidget {
  final String roomId;
  final String userId;
  final String displayName;
  final String role;

  const ProDashboardScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final authState = AuthState(
      userId: userId,
      displayName: displayName,
      role: role,
    );

    return BlocProvider(
      create: (_) => ProDashboardBloc(
        socketService: SocketService(),
        apiService: ProApiService(),
      )..add(ProDashboardStarted(
          roomId: roomId,
          authState: authState,
        )),
      child: const _ProDashboardView(),
    );
  }
}

class _ProDashboardView extends StatelessWidget {
  const _ProDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProDashboardBloc, ProDashboardState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage &&
          curr.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(context),
        body: BlocBuilder<ProDashboardBloc, ProDashboardState>(
          builder: (context, state) {
            if (state.status == ProDashboardStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Zone 1: Sub-level Control ────────────
                  if (state.canModerate)
                    SublevelControlPanel(
                      currentSublevel: state.currentSublevel,
                      isCooldown: state.isNextCooldown,
                      isLastSublevel:
                          state.currentSublevel?.isLast ?? false,
                      onNextPressed: () {
                        context.read<ProDashboardBloc>().add(
                              const ProDashboardNextSublevelPressed(),
                            );
                      },
                    ),

                  // ── Zone 2: Speaking Queue ───────────────
                  SpeakQueuePanelPro(
                    speakQueue: state.speakQueue,
                    onApprove: (userId) {
                      context.read<ProDashboardBloc>().add(
                            ProDashboardSpeakerApproved(userId),
                          );
                    },
                    onSkip: (userId) {
                      context.read<ProDashboardBloc>().add(
                            ProDashboardSpeakerSkipped(userId),
                          );
                    },
                  ),

                  // ── Zone 3: Pin Resources ────────────────
                  PinResourcePanel(
                    pinnedResources: state.pinnedResources,
                    isPinning: state.isPinning,
                    onPinResource: (url, type) {
                      context.read<ProDashboardBloc>().add(
                            ProDashboardResourcePinned(
                              resourceUrl: url,
                              type: type,
                            ),
                          );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        color: AppColors.textSecondary,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      centerTitle: true,
      title: BlocBuilder<ProDashboardBloc, ProDashboardState>(
        buildWhen: (prev, curr) => prev.roomId != curr.roomId,
        builder: (context, state) {
          return Column(
            children: [
              const Text(
                'Pro Dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Room: ${state.roomId.isEmpty ? '...' : state.roomId}',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // LIVE indicator.
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsatingDot(),
              SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pulsating red dot for LIVE indicator.
class _PulsatingDot extends StatefulWidget {
  const _PulsatingDot();

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(
              alpha: 0.5 + (_controller.value * 0.5),
            ),
          ),
        );
      },
    );
  }
}
