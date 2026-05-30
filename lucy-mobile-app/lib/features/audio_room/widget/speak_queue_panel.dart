// lib/features/audio_room/widget/speak_queue_panel.dart
// ============================================================
// Project LUCY — Speaking Queue Panel
// Horizontal scrollable list of users waiting to speak.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/room_user.dart';
import 'persona_data.dart';

/// Horizontal scrollable panel showing the hand-raise queue.
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────────┐
/// │  🗣 Speaking Queue                        │
/// │  [🦊 Fox] [🐱 Cat] [🐻 Bear] →          │
/// └──────────────────────────────────────────┘
/// ```
///
/// Each item shows a small avatar circle (40px) with the user's
/// persona emoji and name below. The panel auto-updates when
/// the BLoC emits a new [handQueue].
class SpeakQueuePanel extends StatelessWidget {
  /// Ordered list of user IDs in the speaking queue.
  final List<String> handQueue;

  /// All users in the room (to look up display info by userId).
  final List<RoomUser> users;

  const SpeakQueuePanel({
    super.key,
    required this.handQueue,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.6),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Speaking Queue',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (handQueue.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${handQueue.length}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Queue List ─────────────────────────────────
          SizedBox(
            height: 60,
            child: handQueue.isEmpty
                ? Center(
                    child: Text(
                      'No one in queue — tap ✋ to raise your hand',
                      style: TextStyle(
                        color: AppColors.textHint.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: handQueue.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final userId = handQueue[index];
                      final user = _findUser(userId);
                      final persona = PersonaData.getPersona(
                        user?.personaIndex ?? index,
                      );

                      return _QueueItem(
                        emoji: persona.emoji,
                        name: user?.displayName ?? 'User',
                        colorHex: persona.colorHex,
                        position: index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Finds a user by ID from the users list.
  RoomUser? _findUser(String userId) {
    try {
      return users.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }
}

/// Single item in the speaking queue.
class _QueueItem extends StatelessWidget {
  final String emoji;
  final String name;
  final int colorHex;
  final int position;

  const _QueueItem({
    required this.emoji,
    required this.name,
    required this.colorHex,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle with position badge.
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(colorHex).withOpacity(0.15),
                border: Border.all(
                  color: Color(colorHex).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),

            // Position number badge.
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: Text(
            name.replaceAll('Anonymous ', ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
