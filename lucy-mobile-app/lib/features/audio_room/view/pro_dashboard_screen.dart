// lib/features/audio_room/view/pro_dashboard_screen.dart
// ============================================================
// Project LUCY — Pro Dashboard Screen (Dev 5 — T4)
//
// 3 zones:
//   Zone 1: Sub-level timer control (current stage, next button)
//   Zone 2: Speaker queue management (approve/reject)
//   Zone 3: Pinned resources list
//
// Zero-conflict: Chỉ dùng BLoC + service của Dev 5.
// API endpoints: pin-resource, moderator-hints (đã có trong Swagger)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/speak_queue_bloc.dart';
import '../bloc/speak_queue_state.dart';
import '../bloc/sub_level_timer_bloc.dart';
import '../bloc/sub_level_timer_event.dart';
import '../bloc/sub_level_timer_state.dart';
import '../widget/countdown_display.dart';

/// Pro Dashboard for Host/Mentor to manage the audio room.
///
/// Requires in widget tree:
///   - [SpeakQueueBloc]
///   - [SubLevelTimerBloc]
class ProDashboardScreen extends StatefulWidget {
  final String roomId;

  const ProDashboardScreen({super.key, required this.roomId});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  // Mock pinned resources — in production comes from API.
  final List<Map<String, String>> _pinnedResources = [
    {'label': 'Grammar Chart - Week 2', 'type': 'image', 'url': 'https://example.com/chart.png'},
    {'label': 'Vocabulary List', 'type': 'url', 'url': 'https://example.com/vocab'},
  ];

  // Mock moderator hints.
  final List<String> _hints = [
    'Hỏi về trải nghiệm cuối tuần',
    'Gợi ý: So sánh văn hóa chào hỏi',
    'Icebreaker: Bạn thích ăn gì?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Pro Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CountdownDisplay(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimerControlZone(),
            const SizedBox(height: 20),
            _buildSpeakerQueueZone(),
            const SizedBox(height: 20),
            _buildPinnedResourcesZone(),
            const SizedBox(height: 20),
            _buildModeratorHintsZone(),
          ],
        ),
      ),
    );
  }

  // ── ZONE 1: Timer Control ──────────────────────────────────

  Widget _buildTimerControlZone() {
    return _DashboardCard(
      title: 'Điều khiển Sub-Level',
      icon: Icons.timer_rounded,
      child: BlocBuilder<SubLevelTimerBloc, SubLevelTimerState>(
        builder: (context, state) {
          return Column(
            children: [
              // Current stage info.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.isRunning ? Icons.play_circle : Icons.pause_circle,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.stageName.isEmpty
                                ? 'Chưa bắt đầu'
                                : state.stageName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            state.formattedTime,
                            style: TextStyle(
                              color: state.isWarning
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Control buttons.
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Stage 1 (10 phút)',
                      icon: Icons.looks_one_rounded,
                      onTap: () {
                        final bloc = context.read<SubLevelTimerBloc>();
                        bloc.add(const TimerReset());
                        bloc.add(const TimerStarted(
                          durationSeconds: 600,
                          stageName: 'Stage 1',
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Stage 2 (10 phút)',
                      icon: Icons.looks_two_rounded,
                      onTap: () {
                        final bloc = context.read<SubLevelTimerBloc>();
                        bloc.add(const TimerReset());
                        bloc.add(const TimerStarted(
                          durationSeconds: 600,
                          stageName: 'Stage 2',
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Stage 3 (20 phút)',
                      icon: Icons.looks_3_rounded,
                      onTap: () {
                        final bloc = context.read<SubLevelTimerBloc>();
                        bloc.add(const TimerReset());
                        bloc.add(const TimerStarted(
                          durationSeconds: 1200,
                          stageName: 'Stage 3',
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── ZONE 2: Speaker Queue ──────────────────────────────────

  Widget _buildSpeakerQueueZone() {
    return _DashboardCard(
      title: 'Danh sách chờ phát biểu',
      icon: Icons.record_voice_over_rounded,
      child: BlocBuilder<SpeakQueueBloc, SpeakQueueState>(
        buildWhen: (p, c) => p.queue != c.queue,
        builder: (context, state) {
          if (state.queue.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text(
                  'Chưa có ai giơ tay',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.queue.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.textHint,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final user = state.queue[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  user['displayName']?.toString() ??
                      user['userId']?.toString() ??
                      'Unknown',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: AppColors.success),
                      onPressed: () {
                        // TODO: Approve speaker via Socket
                      },
                      tooltip: 'Duyệt',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel,
                          color: AppColors.error),
                      onPressed: () {
                        // TODO: Reject speaker via Socket
                      },
                      tooltip: 'Từ chối',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── ZONE 3: Pinned Resources ───────────────────────────────

  Widget _buildPinnedResourcesZone() {
    return _DashboardCard(
      title: 'Tài liệu đã ghim',
      icon: Icons.push_pin_rounded,
      child: Column(
        children: [
          ..._pinnedResources.map((res) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  res['type'] == 'image'
                      ? Icons.image_rounded
                      : Icons.link_rounded,
                  color: AppColors.accent,
                ),
                title: Text(
                  res['label'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  res['url'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () {
                    setState(() => _pinnedResources.remove(res));
                  },
                ),
              )),
          const SizedBox(height: 8),
          _ActionButton(
            label: 'Ghim tài liệu mới',
            icon: Icons.add_rounded,
            onTap: () {
              // TODO: Gọi POST /api/rooms/{id}/pin-resource
            },
          ),
        ],
      ),
    );
  }

  // ── Moderator Hints ────────────────────────────────────────

  Widget _buildModeratorHintsZone() {
    return _DashboardCard(
      title: 'Gợi ý Moderator',
      icon: Icons.lightbulb_rounded,
      child: Column(
        children: _hints
            .map((hint) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hint,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Reusable card wrapper for dashboard zones.
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Small action button for dashboard controls.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
