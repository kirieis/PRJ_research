// lib/features/ai_suggestion/widget/suggestion_bubble.dart
// ============================================================
// Project LUCY — Suggestion Bubble Widget
//
// Bottom overlay that displays AI-generated suggestions.
// Slides up from the bottom 20% of the screen.
//
// UX specs:
//   - Position: Bottom 20% (collapsible)
//   - Max items: 2-3 suggestions
//   - Auto-hide: 8s after display
//   - Animation: slide-up + fade-in (200ms)
//   - Interaction: tap to expand vocab, long-press to save
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/ai_suggestion_bloc.dart';
import '../bloc/ai_suggestion_event.dart';
import '../bloc/ai_suggestion_state.dart';
import '../model/suggestion.dart';
import 'vocabulary_card.dart';

/// Overlay widget displaying AI suggestions in the audio room.
///
/// Place this widget in a [Stack] at the bottom of the audio room screen.
/// It automatically shows/hides based on [AiSuggestionBloc] state.
///
/// ```dart
/// Stack(
///   children: [
///     // ... room content ...
///     const Positioned(
///       left: 0,
///       right: 0,
///       bottom: 80, // above bottom bar
///       child: SuggestionBubble(),
///     ),
///   ],
/// )
/// ```
class SuggestionBubble extends StatelessWidget {
  const SuggestionBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiSuggestionBloc, AiSuggestionState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.suggestions != curr.suggestions,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: state.isShowingSuggestions
              ? _SuggestionContent(
                  key: ValueKey(state.suggestions.hashCode),
                  suggestions: state.suggestions,
                  latencyMs: state.lastLatencyMs,
                )
              : state.status == AiSuggestionStatus.loading
                  ? const _LoadingIndicator(key: ValueKey('loading'))
                  : const SizedBox.shrink(key: ValueKey('empty')),
        );
      },
    );
  }
}

/// Loading indicator while LLM processes.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'AI đang phân tích...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Main suggestion content with phrase cards and vocabulary.
class _SuggestionContent extends StatelessWidget {
  final List<AiSuggestion> suggestions;
  final int latencyMs;

  const _SuggestionContent({
    super.key,
    required this.suggestions,
    required this.latencyMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with dismiss button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text(
                      'AI Gợi ý',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (latencyMs > 0)
                Text(
                  '${latencyMs}ms',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context
                      .read<AiSuggestionBloc>()
                      .add(const AiSuggestionDismissed());
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textHint.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Suggestion phrases
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SuggestionPhraseCard(suggestion: suggestion),
              )),

          // Vocabulary section (from first suggestion with vocab)
          ..._buildVocabularySection(context),
        ],
      ),
    );
  }

  List<Widget> _buildVocabularySection(BuildContext context) {
    final allVocab =
        suggestions.expand((s) => s.vocabulary).take(2).toList();
    if (allVocab.isEmpty) return [];

    return [
      const Divider(
        color: AppColors.textHint,
        height: 16,
        thickness: 0.3,
      ),
      ...allVocab.map((vocab) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: VocabularyCard(
              item: vocab,
              onSave: () {
                context
                    .read<AiSuggestionBloc>()
                    .add(AiSuggestionVocabularySaved(word: vocab.word));
              },
            ),
          )),
    ];
  }
}

/// A single suggestion phrase card.
class _SuggestionPhraseCard extends StatelessWidget {
  final AiSuggestion suggestion;

  const _SuggestionPhraseCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💬', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '"${suggestion.phrase}"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (suggestion.contextHint != null)
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 2),
              child: Text(
                suggestion.contextHint!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating action button to manually trigger AI suggestions.
///
/// Place this button in the audio room bottom bar.
class AiSuggestionButton extends StatelessWidget {
  const AiSuggestionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiSuggestionBloc, AiSuggestionState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final isActive = state.isActive;
        final isLoading = state.status == AiSuggestionStatus.loading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  context
                      .read<AiSuggestionBloc>()
                      .add(const AiSuggestionManuallyRequested());
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.surfaceDark,
              border: Border.all(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.textHint.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text(
                      '💡',
                      style: TextStyle(
                        fontSize: isActive ? 20 : 18,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
