// lib/features/ai_suggestion/widget/vocabulary_card.dart
// ============================================================
// Project LUCY — Vocabulary Card Widget
//
// Expandable card showing word details:
//   word /pronunciation/ (pos) = Vietnamese meaning
//   Example sentence
//   [Save to Notebook] button
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../model/vocabulary_item.dart';

/// Compact vocabulary card displayed inside the suggestion bubble.
///
/// Features:
/// - Tap to expand/collapse detailed view
/// - Long-press to save to vocabulary notebook
/// - Smooth expand animation
class VocabularyCard extends StatefulWidget {
  final VocabularyItem item;
  final VoidCallback? onSave;

  const VocabularyCard({
    super.key,
    required this.item,
    this.onSave,
  });

  @override
  State<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<VocabularyCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isExpanded = !_isExpanded);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onSave?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.item.isSaved
                ? AppColors.accent.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: word + pronunciation + part of speech
            Row(
              children: [
                Icon(
                  widget.item.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.menu_book_rounded,
                  size: 14,
                  color: widget.item.isSaved
                      ? AppColors.accent
                      : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.item.word,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        if (widget.item.pronunciation != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: widget.item.pronunciation!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (widget.item.partOfSpeech != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '(${widget.item.partOfSpeech})',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),

            // Meaning (always visible)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                '= ${widget.item.meaning}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Expanded: example + save button
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 20, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.item.example != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '"${widget.item.example}"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (!widget.item.isSaved)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onSave?.call();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_add_outlined,
                                size: 12,
                                color: AppColors.accent.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Lưu vào sổ tay',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
