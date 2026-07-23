// lib/features/post_session/view/post_session_screen.dart
// ============================================================
// Project LUCY — Post-Session Feedback Screen
//
// AI-generated session summary with:
//   - XP earned animation
//   - Engagement breakdown (speaking ratio, response speed...)
//   - Confidence score with trend arrow
//   - Mistakes list with corrections
//   - New vocabulary list
//   - AI summary text
//   - Level progress bar
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../model/session_report.dart';

/// Post-session feedback screen showing AI-generated report.
///
/// Navigation: Audio Room → Post-Session → Lobby
class PostSessionScreen extends StatefulWidget {
  final SessionReport report;

  const PostSessionScreen({super.key, required this.report});

  @override
  State<PostSessionScreen> createState() => _PostSessionScreenState();
}

class _PostSessionScreenState extends State<PostSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _xpAnimCtrl;
  late Animation<double> _xpAnimation;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // XP count-up animation
    _xpAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _xpAnimation = Tween<double>(
      begin: 0,
      end: widget.report.xpResult.totalXp.toDouble(),
    ).animate(CurvedAnimation(
      parent: _xpAnimCtrl,
      curve: Curves.easeOutCubic,
    ));

    // Fade-in for content
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeIn,
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _xpAnimCtrl.forward();
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _xpAnimCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '🎉',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  report.completedFullSession
                      ? 'Buổi học hoàn thành!'
                      : 'Bạn đã rời phòng sớm',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${report.topic} · ${report.durationFormatted}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // XP Earned Card
              _buildXpCard(report),
              const SizedBox(height: 16),

              // Engagement Breakdown
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildEngagementCard(report),
                    const SizedBox(height: 16),

                    // Confidence Score
                    _buildConfidenceCard(report),
                    const SizedBox(height: 16),

                    // AI Summary
                    if (report.aiSummary.isNotEmpty)
                      _buildAiSummaryCard(report),
                    if (report.aiSummary.isNotEmpty)
                      const SizedBox(height: 16),

                    // Mistakes
                    if (report.mistakes.isNotEmpty)
                      _buildMistakesCard(report),
                    if (report.mistakes.isNotEmpty)
                      const SizedBox(height: 16),

                    // New Vocabulary
                    if (report.newVocabulary.isNotEmpty)
                      _buildVocabularyCard(report),

                    const SizedBox(height: 32),

                    // Return to Lobby button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.go('/main');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Quay về Lobby',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpCard(SessionReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'XP Earned',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _xpAnimation,
            builder: (context, child) {
              return Text(
                '+${_xpAnimation.value.round()}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Engagement: ${report.xpResult.engagementPercentage}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          if (!report.completedFullSession)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Rời sớm: chỉ nhận 30% XP',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(SessionReport report) {
    final metrics = report.metrics;
    return _buildSection(
      title: '📊 Engagement',
      child: Column(
        children: [
          _buildMetricRow(
            'Speaking Ratio',
            '${(metrics.speakingRatio * 100).round()}%',
            metrics.speakingRatio,
            AppColors.accent,
          ),
          const SizedBox(height: 10),
          _buildMetricRow(
            'Response Speed',
            '${metrics.averageResponseTime.toStringAsFixed(1)}s avg',
            metrics.responseSpeedScore,
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildMetricRow(
            'Vocabulary Usage',
            '${metrics.vocabularyUsed}/${metrics.vocabularySuggested} words',
            metrics.vocabularyRatio,
            AppColors.warning,
          ),
          const SizedBox(height: 10),
          _buildMetricRow(
            'Peer Interaction',
            '${metrics.peerInteractions} exchanges',
            metrics.peerInteractionScore,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceCard(SessionReport report) {
    return _buildSection(
      title: '💪 Confidence Score',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            report.confidencePercentage,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: report.isConfidenceImproved
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  report.isConfidenceImproved
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: report.isConfidenceImproved
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  report.confidenceChangeFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: report.isConfidenceImproved
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummaryCard(SessionReport report) {
    return _buildSection(
      title: '🤖 AI Nhận xét',
      child: Text(
        report.aiSummary,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMistakesCard(SessionReport report) {
    return _buildSection(
      title: '✏️ Lỗi cần sửa (${report.mistakes.length})',
      child: Column(
        children: report.mistakes.map((mistake) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        mistake.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '✗ ',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                      TextSpan(
                        text: mistake.original,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '✓ ',
                        style:
                            TextStyle(color: AppColors.success, fontSize: 12),
                      ),
                      TextSpan(
                        text: mistake.correction,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mistake.explanation,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVocabularyCard(SessionReport report) {
    return _buildSection(
      title: '📖 Từ vựng mới (${report.newVocabulary.length})',
      child: Column(
        children: report.newVocabulary.map((vocab) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•', style: TextStyle(color: AppColors.accent)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: vocab.word,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        if (vocab.pronunciation != null)
                          TextSpan(
                            text: ' ${vocab.pronunciation}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        TextSpan(
                          text: ' — ${vocab.meaning}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
