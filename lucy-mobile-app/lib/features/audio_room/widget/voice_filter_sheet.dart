// lib/features/audio_room/widget/voice_filter_sheet.dart
// ============================================================
// Project LUCY — Voice Filter Bottom Sheet
//
// A modal bottom sheet presenting voice filter presets:
//   - Normal (no filter), Warm, Robot, Cartoon, Deep, Echo
//   - Each preset shows: icon, name, description, sample waveform
//   - Currently selected filter is highlighted
//   - Includes "Thử giọng" (Test Voice) button with progress
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/room_config_bloc.dart';
import '../bloc/room_config_event.dart';
import '../bloc/room_config_state.dart';

class VoiceFilterSheet extends StatelessWidget {
  const VoiceFilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<RoomConfigBloc>(),
        child: const VoiceFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thay đổi giọng nói',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chọn bộ lọc giọng phù hợp với bạn',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Filter grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<RoomConfigBloc, RoomConfigState>(
                buildWhen: (p, c) => p.selectedFilter != c.selectedFilter,
                builder: (context, state) {
                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: VoiceFilterType.values.map((filter) {
                          return _VoiceFilterCard(
                            filter: filter,
                            isSelected: state.selectedFilter == filter,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<RoomConfigBloc>().add(
                                    RoomConfigVoiceFilterSelected(filter: filter),
                                  );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
          // Test Voice Button
          _buildTestVoiceSection(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTestVoiceSection(BuildContext context) {
    return BlocBuilder<RoomConfigBloc, RoomConfigState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Progress bar (visible during testing)
              if (state.isTestingVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      // Animated waveform
                      const _TestVoiceWaveform(),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.testProgress,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              // Test Voice button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: state.isTestingVoice
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          context.read<RoomConfigBloc>().add(
                                const RoomConfigTestVoiceStarted(),
                              );
                        },
                  icon: Icon(
                    state.isTestingVoice
                        ? Icons.hourglass_top_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 22,
                  ),
                  label: Text(
                    state.isTestingVoice
                        ? 'Đang phát thử...'
                        : 'Thử giọng (Test Voice)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: state.isTestingVoice
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SafeArea(
                top: false,
                child: SizedBox(height: 8),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual voice filter preset card.
class _VoiceFilterCard extends StatelessWidget {
  final VoiceFilterType filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _VoiceFilterCard({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _filterMeta(filter);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? meta.color.withValues(alpha: 0.15)
              : AppColors.backgroundDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? meta.color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: meta.color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? meta.color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  meta.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              meta.label,
              style: TextStyle(
                color: isSelected ? meta.color : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Description
            Text(
              meta.desc,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Selected checkmark
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: meta.color,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Metadata for each voice filter preset.
class _FilterMeta {
  final String emoji;
  final String label;
  final String desc;
  final Color color;

  const _FilterMeta({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
  });
}

_FilterMeta _filterMeta(VoiceFilterType type) {
  switch (type) {
    case VoiceFilterType.normal:
      return const _FilterMeta(
        emoji: '🎙️',
        label: 'Bình thường',
        desc: 'Giọng gốc',
        color: AppColors.textSecondary,
      );
    case VoiceFilterType.warm:
      return const _FilterMeta(
        emoji: '☀️',
        label: 'Giọng ấm',
        desc: 'Ấm áp, trầm',
        color: Color(0xFFF4A435),
      );
    case VoiceFilterType.robot:
      return const _FilterMeta(
        emoji: '🤖',
        label: 'Giọng Robot',
        desc: 'Cơ khí, tương lai',
        color: AppColors.accent,
      );
    case VoiceFilterType.cartoon:
      return const _FilterMeta(
        emoji: '🐱',
        label: 'Hoạt hình',
        desc: 'Vui, dễ thương',
        color: AppColors.secondary,
      );
    case VoiceFilterType.deep:
      return const _FilterMeta(
        emoji: '🎭',
        label: 'Trầm sâu',
        desc: 'Bass, mạnh mẽ',
        color: AppColors.primaryDark,
      );
    case VoiceFilterType.echo:
      return const _FilterMeta(
        emoji: '🏔️',
        label: 'Echo',
        desc: 'Vọng núi',
        color: Color(0xFF7C6FE0),
      );
  }
}

/// Animated waveform visualization during voice testing.
class _TestVoiceWaveform extends StatefulWidget {
  const _TestVoiceWaveform();

  @override
  State<_TestVoiceWaveform> createState() => _TestVoiceWaveformState();
}

class _TestVoiceWaveformState extends State<_TestVoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (i) {
              final phase = (_ctrl.value + i * 0.05) % 1.0;
              final h = 8.0 + 20.0 * (math.sin(phase * math.pi * 2).abs());
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.4 + 0.6 * (math.sin(phase * math.pi).abs()),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
