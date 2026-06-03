import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'podcast_player_screen.dart';

class PodcastLibraryScreen extends StatefulWidget {
  final String userId;
  final String accountType; // "super" expected

  const PodcastLibraryScreen({super.key, required this.userId, required this.accountType});

  @override
  State<PodcastLibraryScreen> createState() => _PodcastLibraryScreenState();
}

class _PodcastLibraryScreenState extends State<PodcastLibraryScreen> {
  List<Map<String, dynamic>> recordings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.accountType == "super") {
      fetchRecordings();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRecordings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      if (!mounted) return;
      setState(() {
        // Tích hợp data từ lucy-podcast-app (React)
        recordings = [
          {
            "id": "1",
            "title": "Nghệ thuật giao tiếp đa ngôn ngữ",
            "host": "MC Gia Huy",
            "duration": "06:12",
            "fileUrl": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            "createdAt": "2026-05-28T10:00:00Z",
            "listens": 12450,
          },
          {
            "id": "2",
            "title": "Bí quyết luyện phát âm tiếng Anh",
            "host": "MC Minh Nhật",
            "duration": "08:05",
            "fileUrl": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
            "createdAt": "2026-05-25T09:30:00Z",
            "listens": 8932,
          },
          {
            "id": "3",
            "title": "Tư duy phản biện trong học ngôn ngữ",
            "host": "MC Trí Thiện",
            "duration": "04:58",
            "fileUrl": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
            "createdAt": "2026-05-30T15:20:00Z",
            "listens": 15200,
          },
          {
            "id": "4",
            "title": "Văn hoá Nhật Bản qua lăng kính Gen Z",
            "host": "MC Bảo Tuấn",
            "duration": "10:10",
            "fileUrl": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
            "createdAt": "2026-05-20T20:00:00Z",
            "listens": 6780,
          },
        ];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accountType != "super") {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text("Tủ sách Podcast"),
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "Tính năng này chỉ dành cho tài khoản Super.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          "Super Podcast Library",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final rec = recordings[index];
                return _buildRecordingCard(rec);
              },
            ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> rec) {
    // Fix: Kiểm tra null an toàn cho ngày tháng
    String dateStr = "N/A";
    if (rec['createdAt'] != null) {
      try {
        final date = DateTime.parse(rec['createdAt']);
        dateStr = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {}
    }

    final listens = NumberFormat('#,###', 'vi_VN').format(rec['listens'] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PodcastPlayerScreen(
                  title: rec['title'] ?? 'Unknown',
                  host: rec['host'] ?? 'Unknown Host',
                  fileUrl: rec['fileUrl'] ?? '',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.podcasts_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['title'] ?? 'Unknown Episode',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rec['host'] ?? '',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            rec['duration'] ?? '00:00',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.headset_rounded, size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            listens,
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Play button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
