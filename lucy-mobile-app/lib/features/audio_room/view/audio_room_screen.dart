// lib/features/audio_room/view/audio_room_screen.dart
// ============================================================
// Project LUCY — Audio Room Screen (Dev 5 — T2)
//
// Màn hình chính phòng học audio ẩn danh:
//   - AppBar: Room name + CountdownDisplay timer
//   - Body: Avatar Persona grid với ripple animation
//   - Bottom Bar: Mic toggle, Raise hand, Gift, Leave
//
// Zero-conflict: Chỉ dùng BLoC + service của Dev 5.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/speak_queue_bloc.dart';
import '../bloc/speak_queue_event.dart';
import '../bloc/speak_queue_state.dart';
import '../bloc/sub_level_timer_bloc.dart';
import '../widget/countdown_display.dart';
import '../../wallet/widget/gift_button.dart';

/// Audio room screen — main learning room interface.
///
/// Requires in widget tree:
///   - [SpeakQueueBloc] — speaking queue & socket state
///   - [SubLevelTimerBloc] — countdown timer
class AudioRoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String roomName;
  final String hostUserId;
  final String? jwtToken;

  const AudioRoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.roomName,
    required this.hostUserId,
    this.jwtToken,
  });

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  final GlobalKey _hostAvatarKey = GlobalKey();

  // Mock participants — in production, comes from socket events.
  final List<Map<String, String>> _participants = [
    {'userId': 'host', 'name': 'Host', 'avatar': '🎓'},
    {'userId': 'p1', 'name': 'Learner 1', 'avatar': '🧑'},
    {'userId': 'p2', 'name': 'Learner 2', 'avatar': '👩'},
    {'userId': 'p3', 'name': 'Learner 3', 'avatar': '🧔'},
    {'userId': 'p4', 'name': 'Learner 4', 'avatar': '👧'},
    {'userId': 'p5', 'name': 'Learner 5', 'avatar': '🧒'},
  ];

  @override
  void initState() {
    super.initState();
    // Join room via BLoC → Socket → Server.
    context.read<SpeakQueueBloc>().add(SpeakQueueRoomJoined(
          roomId: widget.roomId,
          userId: widget.userId,
          jwtToken: widget.jwtToken,
        ));
  }

  void _leaveRoom() {
    context.read<SpeakQueueBloc>().add(const SpeakQueueRoomLeft());
    Navigator.of(context).pop();
  }

  void _raiseHand() {
    HapticFeedback.mediumImpact();
    context.read<SpeakQueueBloc>().add(const SpeakQueueHandRaised());
  }

  void _toggleMic() {
    final bloc = context.read<SpeakQueueBloc>();
    final newMuted = !bloc.state.isMuted;
    HapticFeedback.lightImpact();
    bloc.add(SpeakQueueMicToggled(isMuted: newMuted));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Connection status banner.
          _buildConnectionBanner(),
          // Avatar grid.
          Expanded(child: _buildAvatarGrid()),
          // Bottom control bar.
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: _leaveRoom,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.roomName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          BlocBuilder<SpeakQueueBloc, SpeakQueueState>(
            buildWhen: (p, c) => p.queueLength != c.queueLength,
            builder: (context, state) => Text(
              '${_participants.length} người · ${state.queueLength} đang chờ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: CountdownDisplay(),
        ),
      ],
    );
  }

  Widget _buildConnectionBanner() {
    return BlocBuilder<SpeakQueueBloc, SpeakQueueState>(
      buildWhen: (p, c) => p.isConnected != c.isConnected,
      builder: (context, state) {
        if (state.isConnected || state.roomId == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.error.withValues(alpha: 0.15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Mất kết nối — đang thử lại...',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.75,
        ),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final p = _participants[index];
          final isHost = index == 0;
          return _AvatarTile(
            key: isHost ? _hostAvatarKey : null,
            name: p['name']!,
            emoji: p['avatar']!,
            isHost: isHost,
            isSpeaking: index <= 1, // Mock: host + first user speaking
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mic toggle.
            BlocBuilder<SpeakQueueBloc, SpeakQueueState>(
              buildWhen: (p, c) => p.isMuted != c.isMuted,
              builder: (context, state) => _ControlButton(
                icon: state.isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: state.isMuted ? 'Bật mic' : 'Tắt mic',
                color: state.isMuted
                    ? AppColors.error
                    : AppColors.success,
                onTap: _toggleMic,
              ),
            ),

            // Raise hand.
            _ControlButton(
              icon: Icons.back_hand_rounded,
              label: 'Giơ tay',
              color: AppColors.accent,
              onTap: _raiseHand,
            ),

            // Gift button.
            GiftButton(
              toUserId: widget.hostUserId,
              hostAvatarKey: _hostAvatarKey,
            ),

            // Leave room.
            _ControlButton(
              icon: Icons.call_end_rounded,
              label: 'Rời phòng',
              color: AppColors.error,
              onTap: _leaveRoom,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single avatar tile with ripple animation when speaking.
class _AvatarTile extends StatefulWidget {
  final String name;
  final String emoji;
  final bool isHost;
  final bool isSpeaking;

  const _AvatarTile({
    super.key,
    required this.name,
    required this.emoji,
    required this.isHost,
    required this.isSpeaking,
  });

  @override
  State<_AvatarTile> createState() => _AvatarTileState();
}

class _AvatarTileState extends State<_AvatarTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );

    if (widget.isSpeaking) {
      _rippleCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AvatarTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _rippleCtrl.repeat();
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _rippleCtrl.stop();
      _rippleCtrl.reset();
    }
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with ripple.
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple rings — only visible when speaking.
              if (widget.isSpeaking)
                AnimatedBuilder(
                  animation: _rippleAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(80, 80),
                      painter: _RipplePainter(
                        progress: _rippleAnim.value,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              // Avatar circle.
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.isHost
                        ? [const Color(0xFFFFD700), const Color(0xFFF5A623)]
                        : [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.accent.withValues(alpha: 0.2),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: widget.isSpeaking
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              // Host badge.
              if (widget.isHost)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFD700),
                    ),
                    child: const Icon(Icons.star, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Name.
        Text(
          widget.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.isHost)
          const Text(
            'Host',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// CustomPainter for ripple animation circles.
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final p = ((progress + i * 0.33) % 1.0);
      final radius = 25.0 + (p * 15.0);
      final opacity = (1.0 - p).clamp(0.0, 0.4);
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Bottom bar control button.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
