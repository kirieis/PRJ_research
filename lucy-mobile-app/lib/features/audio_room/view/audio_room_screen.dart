// lib/features/audio_room/view/audio_room_screen.dart
// ============================================================
// Project LUCY — Audio Room Screen (Redesigned matching Web App)
//
// Features:
//   - Left panel (User List) with Waveform for speaking users.
//   - Center panel (Topic, Sublevel progress, Timer, Raise Hand).
//   - Bottom Bar (Mic, AI Suggestion 💡, Gift, Leave).
//   - AI Real-time Suggestion Bubble overlay (<2s latency).
//   - Post-session Feedback report flow on Leave.
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../ai_suggestion/bloc/ai_suggestion_bloc.dart';
import '../../ai_suggestion/bloc/ai_suggestion_event.dart';
import '../../ai_suggestion/widget/suggestion_bubble.dart';
import '../../post_session/model/session_report.dart';
import '../bloc/speak_queue_bloc.dart';
import '../bloc/speak_queue_event.dart';
import '../bloc/speak_queue_state.dart';
import '../widget/countdown_display.dart';
import '../../wallet/widget/gift_button.dart';
import '../widget/particle_background.dart';

class Participant {
  final String id;
  final String name;
  final String role; // 'moderator', 'pro', 'anonymous'
  bool mic;
  bool speaking;
  bool handRaised;

  Participant({
    required this.id,
    required this.name,
    required this.role,
    this.mic = false,
    this.speaking = false,
    this.handRaised = false,
  });
}

class AudioRoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String roomName;
  final String hostUserId;
  final String? jwtToken;
  final bool isAvatarHidden;
  final String voiceFilter;

  const AudioRoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.roomName,
    required this.hostUserId,
    this.jwtToken,
    this.isAvatarHidden = false,
    this.voiceFilter = 'normal',
  });

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  final GlobalKey _hostAvatarKey = GlobalKey();

  // Mock participants matching web app
  late List<Participant> _participants;
  Timer? _simTimer1;
  Timer? _simTimer2;
  Timer? _simTimer3;

  @override
  void initState() {
    super.initState();

    _participants = [
      Participant(id: '1', name: 'Minh Tú', role: 'moderator', mic: true, speaking: true, handRaised: false),
      Participant(id: '2', name: 'Lan Anh', role: 'pro', mic: true, speaking: false, handRaised: false),
      Participant(id: '3', name: 'Khách #3', role: 'anonymous', mic: false, speaking: false, handRaised: false),
      Participant(id: '4', name: 'Hoàng Duy', role: 'pro', mic: false, speaking: false, handRaised: true),
      Participant(id: '5', name: 'Thanh Mai', role: 'pro', mic: true, speaking: false, handRaised: false),
    ];

    // Join room via BLoC → Socket → Server.
    context.read<SpeakQueueBloc>().add(SpeakQueueRoomJoined(
          roomId: widget.roomId,
          userId: widget.userId,
          jwtToken: widget.jwtToken,
        ));

    // Start AI Suggestion Pipeline
    context.read<AiSuggestionBloc>().add(AiSuggestionSessionStarted(
          topic: widget.roomName,
          level: 'A1',
          language: 'en',
        ));

    _startMockSimulation();
  }

  void _startMockSimulation() {
    // 8s: Lan Anh starts speaking
    _simTimer1 = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      setState(() {
        final u = _participants.cast<Participant?>().firstWhere((p) => p?.id == '2', orElse: () => null);
        if (u != null) u.speaking = true;
      });
    });

    // 12s: Phương Linh joins
    _simTimer2 = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() {
        _participants.add(Participant(id: '6', name: 'Phương Linh', role: 'anonymous'));
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text('Phương Linh vừa tham gia phòng'),
        ]),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    });

    // 18s: Lan Anh stops speaking
    _simTimer3 = Timer(const Duration(seconds: 18), () {
      if (!mounted) return;
      setState(() {
        final u = _participants.cast<Participant?>().firstWhere((p) => p?.id == '2', orElse: () => null);
        if (u != null) u.speaking = false;
      });
    });
  }

  @override
  void dispose() {
    _simTimer1?.cancel();
    _simTimer2?.cancel();
    _simTimer3?.cancel();
    super.dispose();
  }

  void _leaveRoom() {
    context.read<AiSuggestionBloc>().add(const AiSuggestionSessionEnded());
    context.read<SpeakQueueBloc>().add(const SpeakQueueRoomLeft());

    // Generate mock report and navigate to PostSession Screen
    final report = SessionReport.mock(
      roomId: widget.roomId,
      topic: widget.roomName,
    );
    context.go('/post-session', extra: report);
  }

  void _toggleRaiseHand() {
    HapticFeedback.mediumImpact();
    setState(() {
      final me = _participants.firstWhere((p) => p.id == '1');
      me.handRaised = !me.handRaised;
    });
    context.read<SpeakQueueBloc>().add(const SpeakQueueHandRaised());
  }

  void _toggleMic() {
    HapticFeedback.lightImpact();
    final bloc = context.read<SpeakQueueBloc>();
    final newMuted = !bloc.state.isMuted;
    bloc.add(SpeakQueueMicToggled(isMuted: newMuted));
    setState(() {
      final me = _participants.firstWhere((p) => p.id == '1');
      me.mic = !newMuted;
      me.speaking = !newMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const ParticleBackground(),
          Column(
            children: [
              _buildConnectionBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopicArea(),
                      const SizedBox(height: 16),
                      _buildUserListPanel(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),

          // AI Suggestion Bubble overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 95,
            child: SuggestionBubble(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: _leaveRoom,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.roomName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${_participants.length} người đang tham gia',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner() {
    return BlocBuilder<SpeakQueueBloc, SpeakQueueState>(
      buildWhen: (p, c) => p.isConnected != c.isConnected,
      builder: (context, state) {
        if (state.isConnected || state.roomId == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: AppColors.error.withValues(alpha: 0.15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Mất kết nối — đang thử lại...',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('1', style: TextStyle(color: AppColors.backgroundDark, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'GREETING STRANGERS',
                  style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.roomName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tự giới thiệu bản thân và chia sẻ lý do bạn tham gia buổi học hôm nay.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const CountdownDisplay(),
          const SizedBox(height: 16),
          _buildRaiseHandButton(),
        ],
      ),
    );
  }

  Widget _buildRaiseHandButton() {
    final me = _participants.firstWhere((p) => p.id == '1', orElse: () => _participants.first);
    final isRaised = me.handRaised;

    return GestureDetector(
      onTap: _toggleRaiseHand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRaised 
                ? [AppColors.accent, const Color(0xFF00B89C)]
                : [const Color(0xFFF4A435), const Color(0xFFE8963A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (isRaised ? AppColors.accent : const Color(0xFFF4A435)).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRaised ? Icons.pan_tool_rounded : Icons.back_hand_rounded,
              color: AppColors.backgroundDark,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isRaised ? 'Đã giơ tay' : 'Giơ tay phát biểu',
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ĐANG THAM GIA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_participants.length}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final u = _participants[index];
              return _buildUserCard(u);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Participant user) {
    Color roleColor = AppColors.textSecondary;
    String roleText = 'Học viên';
    if (user.role == 'moderator') {
      roleColor = AppColors.primary;
      roleText = 'Moderator';
    } else if (user.role == 'pro') {
      roleColor = AppColors.accent;
      roleText = 'Pro';
    }

    return Container(
      decoration: BoxDecoration(
        color: user.speaking ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.speaking ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  key: user.id == widget.hostUserId ? _hostAvatarKey : null,
                  radius: 24,
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  child: Text(
                    user.name.substring(0, 1),
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                roleText,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (user.speaking)
            const Positioned(
              top: 48,
              right: 8,
              child: WaveformIndicator(),
            ),
          if (user.handRaised)
            Positioned(
              top: -4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4A435),
                  shape: BoxShape.circle,
                ),
                child: const Text('✋', style: TextStyle(fontSize: 12)),
              ),
            ),
          if (!user.mic && !user.speaking)
            Positioned(
              top: 48,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 1.5),
                ),
                child: const Icon(Icons.mic_off_rounded, size: 10, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isMuted = context.watch<SpeakQueueBloc>().state.isMuted;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Leave Room
            GestureDetector(
              onTap: _leaveRoom,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.call_end_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 6),
                    Text('Rời phòng', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // AI Suggestion Button 💡
            const AiSuggestionButton(),

            // Mic Toggle
            GestureDetector(
              onTap: _toggleMic,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMuted ? AppColors.error : AppColors.surfaceDark,
                  border: Border.all(color: isMuted ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    if (isMuted)
                      BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                  ],
                ),
                child: Icon(
                  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: isMuted ? Colors.white : AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),

            // Gift Button
            GiftButton(
              toUserId: widget.hostUserId,
              hostAvatarKey: _hostAvatarKey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Waveform indicator for speaking users
class WaveformIndicator extends StatefulWidget {
  const WaveformIndicator({super.key});

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.backgroundDark, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBar(0),
          const SizedBox(width: 1.5),
          _buildBar(0.25),
          const SizedBox(width: 1.5),
          _buildBar(0.5),
        ],
      ),
    );
  }

  Widget _buildBar(double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final progress = (_ctrl.value + delay) % 1.0;
        final height = 3.0 + 7.0 * (math.sin(progress * math.pi * 2).abs());
        return Container(
          width: 2,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}
