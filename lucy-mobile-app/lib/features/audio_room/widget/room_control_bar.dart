// lib/features/audio_room/widget/room_control_bar.dart
// ============================================================
// Project LUCY — Room Bottom Control Bar
// Mic toggle, raise hand, and leave room buttons.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Bottom control bar for the audio room.
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────────┐
/// │  [🎤 Mic]    [✋ Hand (count)]    [🚪 Leave] │
/// └──────────────────────────────────────────┘
/// ```
///
/// All callbacks are provided by the parent widget, which dispatches
/// BLoC events on button press.
class RoomControlBar extends StatelessWidget {
  /// Whether the user's microphone is currently on.
  final bool isMicOn;

  /// Whether the user has raised their hand.
  final bool isHandRaised;

  /// Number of users in the hand-raise queue.
  final int handQueueCount;

  /// Called when mic toggle is pressed.
  final VoidCallback onMicToggle;

  /// Called when raise/lower hand is pressed.
  final VoidCallback onHandToggle;

  /// Called when leave room is pressed.
  final VoidCallback onLeaveRoom;

  const RoomControlBar({
    super.key,
    required this.isMicOn,
    required this.isHandRaised,
    required this.handQueueCount,
    required this.onMicToggle,
    required this.onHandToggle,
    required this.onLeaveRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ── Mic Toggle ────────────────────────────────
            _ControlButton(
              icon: isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: isMicOn ? 'Mute' : 'Unmute',
              color: isMicOn ? AppColors.success : AppColors.error,
              isActive: isMicOn,
              onTap: onMicToggle,
            ),

            // ── Raise Hand ────────────────────────────────
            _ControlButton(
              icon: Icons.pan_tool_rounded,
              label: 'Hand',
              color: isHandRaised ? AppColors.warning : AppColors.textHint,
              isActive: isHandRaised,
              badgeCount: handQueueCount,
              onTap: onHandToggle,
            ),

            // ── Leave Room ────────────────────────────────
            _ControlButton(
              icon: Icons.exit_to_app_rounded,
              label: 'Leave',
              color: AppColors.error,
              isActive: false,
              onTap: () => _showLeaveConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before leaving the room.
  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Room?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You will be disconnected from the audio session.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onLeaveRoom();
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single control button with icon, label, and optional badge.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Button circle.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color.withOpacity(0.2)
                      : AppColors.cardDark,
                  border: Border.all(
                    color: isActive
                        ? color
                        : AppColors.textHint.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              // Badge count (for hand queue).
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
