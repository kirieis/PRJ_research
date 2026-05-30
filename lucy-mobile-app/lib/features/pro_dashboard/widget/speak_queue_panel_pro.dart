// lib/features/pro_dashboard/widget/speak_queue_panel_pro.dart
// ============================================================
// Project LUCY — Zone 2: Speaking Queue Panel (Pro/Moderator)
// Vertical list with approve/skip actions for each queued speaker.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../audio_room/widget/persona_data.dart';

/// Zone 2 — Speaking queue with moderator controls.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────┐
/// │ 🗣 Speaking Queue (3)               │
/// ├─────────────────────────────────────┤
/// │ 1. 🦊 Anonymous Fox  [✅] [❌]     │
/// │ 2. 🐱 Anonymous Cat  [✅] [❌]     │
/// │ 3. 🐻 Anonymous Bear [✅] [❌]     │
/// └─────────────────────────────────────┘
/// ```
class SpeakQueuePanelPro extends StatelessWidget {
  /// Ordered list of user IDs in the speaking queue.
  final List<String> speakQueue;

  /// Called when moderator approves a speaker.
  final void Function(String userId) onApprove;

  /// Called when moderator skips a speaker.
  final void Function(String userId) onSkip;

  const SpeakQueuePanelPro({
    super.key,
    required this.speakQueue,
    required this.onApprove,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Speaking Queue',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (speakQueue.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${speakQueue.length}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Queue List ─────────────────────────────────
          if (speakQueue.isEmpty)
            _buildEmptyState()
          else
            ...speakQueue.asMap().entries.map((entry) {
              final index = entry.key;
              final userId = entry.value;
              return _SpeakerRow(
                userId: userId,
                position: index + 1,
                personaIndex: userId.hashCode % 10,
                onApprove: () => onApprove(userId),
                onSkip: () => onSkip(userId),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 32,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'No one in queue',
            style: TextStyle(
              color: AppColors.textHint.withValues(alpha: 0.6),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row in the speaking queue.
class _SpeakerRow extends StatelessWidget {
  final String userId;
  final int position;
  final int personaIndex;
  final VoidCallback onApprove;
  final VoidCallback onSkip;

  const _SpeakerRow({
    required this.userId,
    required this.position,
    required this.personaIndex,
    required this.onApprove,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final persona = PersonaData.getPersona(personaIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Position badge.
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Avatar emoji.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(persona.colorHex).withValues(alpha: 0.15),
              border: Border.all(
                color: Color(persona.colorHex).withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(persona.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(width: 10),

          // Display name.
          Expanded(
            child: Text(
              persona.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Approve button.
          _ActionButton(
            icon: Icons.check_rounded,
            color: AppColors.success,
            tooltip: 'Approve',
            onTap: onApprove,
          ),

          const SizedBox(width: 6),

          // Skip button.
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppColors.error,
            tooltip: 'Skip',
            onTap: onSkip,
          ),
        ],
      ),
    );
  }
}

/// Small action button (approve/skip).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
