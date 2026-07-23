// lib/features/audio_room/view/room_config_screen.dart
// ============================================================
// Project LUCY — Room Configuration Screen
//
// Pre-room settings screen where users configure:
//   ✅ Feature 1: Room configuration UI (this screen)
//   ✅ Feature 2: "Ẩn Avatar" toggle with live preview
//   ✅ Feature 3: "Thay đổi giọng nói" voice filter selector
//   ✅ Feature 4: "Thử giọng" test voice button
//
// Navigation flow:
//   Room Lobby → Room Config → Audio Room
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/room_config_bloc.dart';
import '../bloc/room_config_event.dart';
import '../bloc/room_config_state.dart';
import '../widget/avatar_toggle.dart';
import '../widget/voice_filter_sheet.dart';

class RoomConfigScreen extends StatelessWidget {
  final String roomId;
  final String userId;
  final String roomName;
  final String hostUserId;
  final String? jwtToken;

  const RoomConfigScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.roomName,
    required this.hostUserId,
    this.jwtToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình phòng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Thiết lập trước khi vào phòng',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room info card
            _buildRoomInfoCard(),
            const SizedBox(height: 24),

            // Section: Avatar Settings
            _buildSectionLabel('THIẾT LẬP DANH TÍNH'),
            const SizedBox(height: 12),
            _buildAvatarSection(context),
            const SizedBox(height: 28),

            // Section: Voice Settings
            _buildSectionLabel('THIẾT LẬP GIỌNG NÓI'),
            const SizedBox(height: 12),
            _buildVoiceFilterSection(context),
            const SizedBox(height: 12),
            _buildTestVoiceButton(context),
            const SizedBox(height: 32),

            // Enter room button
            _buildEnterRoomButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surfaceDark.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.headset_mic_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE · Room $roomId',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── FEATURE 2: Avatar Toggle ───────────────────────────────

  Widget _buildAvatarSection(BuildContext context) {
    return BlocBuilder<RoomConfigBloc, RoomConfigState>(
      buildWhen: (p, c) => p.isAvatarHidden != c.isAvatarHidden,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.isAvatarHidden
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              // Avatar Preview
              AvatarPreview(
                isHidden: state.isAvatarHidden,
                userName: 'Minh Tú',
              ),
              const SizedBox(height: 20),

              // Toggle Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: state.isAvatarHidden
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.isAvatarHidden
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: state.isAvatarHidden
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        state.isAvatarHidden
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: state.isAvatarHidden
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ẩn Avatar',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.isAvatarHidden
                                ? 'Đang ẩn — hiển thị biểu tượng hoạt hình'
                                : 'Avatar thật sẽ hiển thị cho người khác',
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.isAvatarHidden,
                      onChanged: (value) {
                        HapticFeedback.mediumImpact();
                        context.read<RoomConfigBloc>().add(
                              RoomConfigAvatarToggled(isHidden: value),
                            );
                      },
                      activeThumbColor: AppColors.accent,
                      activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.textHint,
                      inactiveTrackColor:
                          AppColors.textHint.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),

              // Info text when hidden
              if (state.isAvatarHidden)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Người khác sẽ thấy biểu tượng hoạt hình thay vì avatar thật của bạn. Tên hiển thị vẫn được giữ nguyên.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── FEATURE 3: Voice Filter ────────────────────────────────

  Widget _buildVoiceFilterSection(BuildContext context) {
    return BlocBuilder<RoomConfigBloc, RoomConfigState>(
      buildWhen: (p, c) => p.selectedFilter != c.selectedFilter,
      builder: (context, state) {
        final filterLabel = _getFilterLabel(state.selectedFilter);
        final filterEmoji = _getFilterEmoji(state.selectedFilter);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              VoiceFilterSheet.show(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.selectedFilter != VoiceFilterType.normal
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  // Filter icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: state.selectedFilter != VoiceFilterType.normal
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        filterEmoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thay đổi giọng nói',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: state.selectedFilter !=
                                        VoiceFilterType.normal
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                filterLabel,
                                style: TextStyle(
                                  color: state.selectedFilter !=
                                          VoiceFilterType.normal
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── FEATURE 4: Test Voice ──────────────────────────────────

  Widget _buildTestVoiceButton(BuildContext context) {
    return BlocBuilder<RoomConfigBloc, RoomConfigState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.isTestingVoice
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              // Test voice button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: state.isTestingVoice
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          context.read<RoomConfigBloc>().add(
                                const RoomConfigTestVoiceStarted(),
                              );
                        },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Animated icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: state.isTestingVoice
                                ? const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  )
                                : null,
                            color: state.isTestingVoice
                                ? null
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              state.isTestingVoice
                                  ? Icons.graphic_eq_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: state.isTestingVoice
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.isTestingVoice
                                    ? 'Đang phát thử...'
                                    : 'Thử giọng (Test Voice)',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.isTestingVoice
                                    ? 'Nghe giọng "${_getFilterLabel(state.selectedFilter)}"'
                                    : 'Nghe thử giọng nói đã biến đổi',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.isTestingVoice)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: state.testProgress,
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Progress bar
              if (state.isTestingVoice)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.testProgress,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Enter Room CTA ─────────────────────────────────────────

  Widget _buildEnterRoomButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: () {
          HapticFeedback.mediumImpact();

          // Confirm settings
          context.read<RoomConfigBloc>().add(const RoomConfigConfirmed());

          // Read config state to pass to audio room
          final configState = context.read<RoomConfigBloc>().state;

          // Navigate to audio room with config
          context.push('/audio-room', extra: {
            'roomId': roomId,
            'userId': userId,
            'roomName': roomName,
            'hostUserId': hostUserId,
            'jwtToken': jwtToken,
            'isAvatarHidden': configState.isAvatarHidden,
            'voiceFilter': configState.selectedFilter.name,
          });
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_rounded, size: 22),
            SizedBox(width: 10),
            Text('Vào phòng'),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _getFilterLabel(VoiceFilterType type) {
    switch (type) {
      case VoiceFilterType.normal:
        return 'Bình thường';
      case VoiceFilterType.warm:
        return 'Giọng ấm';
      case VoiceFilterType.robot:
        return 'Giọng Robot';
      case VoiceFilterType.cartoon:
        return 'Hoạt hình';
      case VoiceFilterType.deep:
        return 'Trầm sâu';
      case VoiceFilterType.echo:
        return 'Echo';
    }
  }

  String _getFilterEmoji(VoiceFilterType type) {
    switch (type) {
      case VoiceFilterType.normal:
        return '🎙️';
      case VoiceFilterType.warm:
        return '☀️';
      case VoiceFilterType.robot:
        return '🤖';
      case VoiceFilterType.cartoon:
        return '🐱';
      case VoiceFilterType.deep:
        return '🎭';
      case VoiceFilterType.echo:
        return '🏔️';
    }
  }
}
