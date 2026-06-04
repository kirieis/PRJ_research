import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';

class PodcastPlayerScreen extends StatefulWidget {
  final String title;
  final String host;
  final String fileUrl;

  const PodcastPlayerScreen({
    super.key,
    required this.title,
    required this.host,
    required this.fileUrl,
  });

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer
          .setAudioSource(AudioSource.uri(Uri.parse(widget.fileUrl)));
      _audioPlayer.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text('File không khả dụng, vui lòng thử lại'),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _seekForward() {
    final current = _audioPlayer.position;
    _audioPlayer.seek(current + const Duration(seconds: 15));
  }

  void _seekBackward() {
    final current = _audioPlayer.position;
    var newPos = current - const Duration(seconds: 15);
    if (newPos < Duration.zero) newPos = Duration.zero;
    _audioPlayer.seek(newPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Đang phát",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: _hasError
          ? const Center(
              child: Text(
                "Không thể tải Podcast",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Artwork
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.podcasts_rounded,
                        size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 48),
                // Title and Host
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.host,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Slider
                StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return StreamBuilder<PositionData>(
                      stream: _positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data ??
                            PositionData(Duration.zero, Duration.zero);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4.0,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6.0),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14.0),
                                ),
                                child: Stack(
                                  children: [
                                    Slider(
                                      min: 0.0,
                                      max: duration.inMilliseconds.toDouble(),
                                      value: positionData
                                          .bufferedPosition.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                              0.0,
                                              duration.inMilliseconds
                                                  .toDouble()),
                                      onChanged: (value) {},
                                      activeColor:
                                          AppColors.textHint.withValues(alpha: 0.3),
                                      inactiveColor: AppColors.surfaceDark,
                                    ),
                                    Slider(
                                      min: 0.0,
                                      max: duration.inMilliseconds.toDouble(),
                                      value: positionData
                                          .position.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                              0.0,
                                              duration.inMilliseconds
                                                  .toDouble()),
                                      onChanged: (value) {
                                        _audioPlayer.seek(Duration(
                                            milliseconds: value.round()));
                                      },
                                      activeColor: AppColors.primary,
                                      inactiveColor: Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(positionData.position),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded,
                          color: AppColors.textPrimary, size: 36),
                      onPressed: _seekBackward,
                    ),
                    const SizedBox(width: 24),
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            width: 64.0,
                            height: 64.0,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          );
                        } else if (playing != true) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow_rounded),
                              iconSize: 48.0,
                              color: Colors.white,
                              onPressed: _audioPlayer.play,
                            ),
                          );
                        } else if (processingState !=
                            ProcessingState.completed) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.pause_rounded),
                              iconSize: 48.0,
                              color: Colors.white,
                              onPressed: _audioPlayer.pause,
                            ),
                          );
                        } else {
                          return IconButton(
                            icon: const Icon(Icons.replay_rounded),
                            iconSize: 48.0,
                            color: AppColors.textPrimary,
                            onPressed: () => _audioPlayer.seek(Duration.zero),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded,
                          color: AppColors.textPrimary, size: 36),
                      onPressed: _seekForward,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Stream<PositionData> get _positionDataStream => _audioPlayer.positionStream
      .map((position) => PositionData(position, _audioPlayer.bufferedPosition));

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  PositionData(this.position, this.bufferedPosition);
}
