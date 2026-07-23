// lib/features/audio_room/widget/avatar_toggle.dart
// ============================================================
// Project LUCY — Avatar Toggle Widget
//
// Animated toggle switch for hiding/showing user avatar:
//   - When OFF: Shows real avatar (emoji-based in current version)
//   - When ON: Avatar transitions to a cute animated icon with
//     artistic blur overlay, confirming anonymous mode.
//   - Smooth spring animation on toggle
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A preview widget showing avatar in its current visibility state.
///
/// [isHidden] — when true, shows the anonymized avatar.
/// [userName] — display name for the initials fallback.
class AvatarPreview extends StatelessWidget {
  final bool isHidden;
  final String userName;

  const AvatarPreview({
    super.key,
    required this.isHidden,
    this.userName = 'MT',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: isHidden
          ? _buildAnonymousAvatar()
          : _buildRealAvatar(),
    );
  }

  Widget _buildRealAvatar() {
    return Container(
      key: const ValueKey('real_avatar'),
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty
              ? userName.substring(0, math.min(2, userName.length)).toUpperCase()
              : '🧑',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousAvatar() {
    return Container(
      key: const ValueKey('anon_avatar'),
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceDark,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blurred background pattern
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
            // Cute anonymous icon
            const _BouncingAnonymousIcon(),
          ],
        ),
      ),
    );
  }
}

/// Animated bouncing anonymous icon.
class _BouncingAnonymousIcon extends StatefulWidget {
  const _BouncingAnonymousIcon();

  @override
  State<_BouncingAnonymousIcon> createState() => _BouncingAnonymousIconState();
}

class _BouncingAnonymousIconState extends State<_BouncingAnonymousIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnim.value),
          child: child,
        );
      },
      child: const Text(
        '🦊',
        style: TextStyle(fontSize: 40),
      ),
    );
  }
}
