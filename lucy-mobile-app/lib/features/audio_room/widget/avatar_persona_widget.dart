// lib/features/audio_room/widget/avatar_persona_widget.dart
// ============================================================
// Project LUCY — Avatar Persona Widget
// Displays a single participant with emoji avatar,
// ripple speaking animation, and mic status badge.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/room_user.dart';
import 'persona_data.dart';
import 'ripple_painter.dart';

/// Widget displaying a single participant in the audio room grid.
///
/// Layout:
/// ```
///   ╭─── ripple rings (when speaking) ───╮
///   │        ┌──────────┐                │
///   │        │  🦊 emoji │                │
///   │        └──────────┘                │
///   ╰────────────────────────────────────╯
///          "Anonymous Fox"
///            🎤 / 🔇
/// ```
///
/// The ripple animation is driven by an internal [AnimationController]
/// that starts/stops based on [RoomUser.isSpeaking].
class AvatarPersonaWidget extends StatefulWidget {
  /// The participant data to display.
  final RoomUser user;

  /// Whether this is the current (local) user.
  final bool isCurrentUser;

  const AvatarPersonaWidget({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  State<AvatarPersonaWidget> createState() => _AvatarPersonaWidgetState();
}

class _AvatarPersonaWidgetState extends State<AvatarPersonaWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animation if already speaking.
    if (widget.user.isSpeaking) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(AvatarPersonaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start or stop ripple animation based on speaking state change.
    if (widget.user.isSpeaking && !oldWidget.user.isSpeaking) {
      _rippleController.repeat();
    } else if (!widget.user.isSpeaking && oldWidget.user.isSpeaking) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persona = PersonaData.getPersona(widget.user.personaIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar with Ripple ──────────────────────────
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple rings (only visible when speaking).
              if (widget.user.isSpeaking)
                AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(90, 90),
                      painter: RipplePainter(
                        progress: _rippleController.value,
                        color: AppColors.accent,
                      ),
                    );
                  },
                ),

              // Avatar circle with emoji.
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(persona.colorHex).withOpacity(0.2),
                  border: Border.all(
                    color: widget.user.isSpeaking
                        ? AppColors.accent
                        : widget.isCurrentUser
                            ? AppColors.primary
                            : Color(persona.colorHex).withOpacity(0.5),
                    width: widget.user.isSpeaking ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    persona.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),

              // Mic status badge (bottom-right).
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.user.isMuted
                        ? AppColors.error.withOpacity(0.9)
                        : AppColors.success.withOpacity(0.9),
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.user.isMuted ? Icons.mic_off : Icons.mic,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ── Display Name ────────────────────────────────
        Text(
          widget.user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.isCurrentUser
                ? AppColors.primary
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight:
                widget.isCurrentUser ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),

        // "You" label for current user.
        if (widget.isCurrentUser) ...[
          const SizedBox(height: 2),
          Text(
            '(You)',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
