// lib/features/audio_room/view/audio_room_screen.dart
// ============================================================
// Project LUCY — Audio Room Screen
// Main screen composing avatar grid, speak queue, and controls.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/audio_room_bloc.dart';
import '../bloc/audio_room_event.dart';
import '../bloc/audio_room_state.dart';
import '../service/agora_service.dart';
import '../service/socket_service.dart';
import '../widget/avatar_persona_widget.dart';
import '../widget/room_control_bar.dart';
import '../widget/speak_queue_panel.dart';

/// Main audio room screen.
///
/// Receives room parameters via constructor (from GoRouter extras).
/// Creates [AudioRoomBloc] with injected services and dispatches
/// [AudioRoomJoinRequested] on init.
///
/// Layout:
/// ```
/// ┌─────────────────────────────┐
/// │ AppBar: Room title          │
/// ├─────────────────────────────┤
/// │                             │
/// │   GridView (2 columns)      │
/// │   with AvatarPersonaWidget  │
/// │                             │
/// ├─────────────────────────────┤
/// │ SpeakQueuePanel             │
/// ├─────────────────────────────┤
/// │ RoomControlBar              │
/// └─────────────────────────────┘
/// ```
class AudioRoomScreen extends StatelessWidget {
  final String roomId;
  final String channelName;
  final String userId;
  final String displayName;
  final String? agoraToken;

  const AudioRoomScreen({
    super.key,
    required this.roomId,
    required this.channelName,
    required this.userId,
    required this.displayName,
    this.agoraToken,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AudioRoomBloc(
        agoraService: AgoraService(),
        socketService: SocketService(),
      )..add(AudioRoomJoinRequested(
          roomId: roomId,
          channelName: channelName,
          userId: userId,
          displayName: displayName,
          agoraToken: agoraToken,
        )),
      child: const _AudioRoomView(),
    );
  }
}

class _AudioRoomView extends StatelessWidget {
  const _AudioRoomView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioRoomBloc, AudioRoomState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // Navigate back when intentionally disconnected.
        if (state.status == AudioRoomStatus.disconnected) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }

        // Show error snackbar.
        if (state.status == AudioRoomStatus.error &&
            state.errorMessage != null) {
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
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: _buildAppBar(context),
        body: BlocBuilder<AudioRoomBloc, AudioRoomState>(
          builder: (context, state) {
            return Column(
              children: [
                // ── Connection Status Banner ──────────────
                if (state.status == AudioRoomStatus.connecting)
                  _buildConnectingBanner(),

                // ── Avatar Grid ───────────────────────────
                Expanded(
                  child: state.users.isEmpty
                      ? _buildEmptyState(state)
                      : _buildAvatarGrid(context, state),
                ),

                // ── Speaking Queue Panel ──────────────────
                SpeakQueuePanel(
                  handQueue: state.handQueue,
                  users: state.users,
                ),

                // ── Bottom Control Bar ────────────────────
                RoomControlBar(
                  isMicOn: state.isMicOn,
                  isHandRaised: state.isHandRaised,
                  handQueueCount: state.handQueue.length,
                  onMicToggle: () {
                    context
                        .read<AudioRoomBloc>()
                        .add(const AudioRoomMicToggled());
                  },
                  onHandToggle: () {
                    context
                        .read<AudioRoomBloc>()
                        .add(const AudioRoomHandToggled());
                  },
                  onLeaveRoom: () {
                    context
                        .read<AudioRoomBloc>()
                        .add(const AudioRoomLeaveRequested());
                  },
                ),
              ],
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
      leading: const SizedBox.shrink(), // No back button (use Leave)
      centerTitle: true,
      title: BlocBuilder<AudioRoomBloc, AudioRoomState>(
        buildWhen: (prev, curr) =>
            prev.roomId != curr.roomId ||
            prev.users.length != curr.users.length,
        builder: (context, state) {
          return Column(
            children: [
              const Text(
                'Audio Room',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${state.users.length} participant${state.users.length != 1 ? 's' : ''}',
                style: TextStyle(
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
        // Live indicator.
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
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

  Widget _buildConnectingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.primary.withOpacity(0.15),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Connecting to room...',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AudioRoomState state) {
    final isConnecting = state.status == AudioRoomStatus.connecting;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnecting
                ? Icons.wifi_tethering_rounded
                : Icons.people_outline_rounded,
            size: 48,
            color: AppColors.textHint.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isConnecting
                ? 'Joining room...'
                : 'Waiting for participants...',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(BuildContext context, AudioRoomState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return AvatarPersonaWidget(
          user: user,
          isCurrentUser: user.userId == state.currentUserId,
        );
      },
    );
  }
}
