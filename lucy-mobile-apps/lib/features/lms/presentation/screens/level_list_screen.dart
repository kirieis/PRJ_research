import 'package:flutter/material.dart';
import '../../data/models/level_model.dart';
import '../../data/repositories/lms_repository.dart';
import '../../../../shared/widgets/loading_widget.dart';

/// Màn hình danh sách Levels – GET /api/levels.
///
/// Hiển thị danh sách levels theo ngôn ngữ, mỗi level có thể mở rộng
/// để xem sub-levels bên trong.
///
/// Phụ trách: Dev 3 (Trần Quốc Thịnh) – Backend
///            Dev 1 (Nguyễn Trí Thiện) – Mobile
class LevelListScreen extends StatefulWidget {
  const LevelListScreen({super.key});

  @override
  State<LevelListScreen> createState() => _LevelListScreenState();
}

class _LevelListScreenState extends State<LevelListScreen> {
  final LmsRepository _lmsRepository = LmsRepository();
  List<LevelModel> _levels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final levels = await _lmsRepository.getLevels(isPublished: true);
      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLevels,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải danh sách bài học...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLevels,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_levels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có bài học nào', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLevels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final level = _levels[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6C63FF),
                child: Text(
                  '${level.levelNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                level.topicName ?? 'Level ${level.levelNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Stage ${level.stageNumber} • ${level.subLevels.length} bài nhỏ',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              children: level.subLevels.map((subLevel) {
                return ListTile(
                  leading: Text(
                    subLevel.contentTypeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(subLevel.title ?? 'Bài ${subLevel.orderIndex}'),
                  subtitle: Text(
                    '${subLevel.contentType} • ${subLevel.durationMinutes ?? '?'} phút',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.play_circle_outline),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
