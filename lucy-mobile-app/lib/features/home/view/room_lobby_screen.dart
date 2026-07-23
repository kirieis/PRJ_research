// lib/features/home/view/room_lobby_screen.dart
// ============================================================
// Project LUCY — Room Lobby Screen (Mobile-Optimized)
//
// Matches Web client (`lucy-web-client/src/app/page.tsx`):
//   - Animated cultural background themes (JA Sakura, ZH Lanterns)
//   - Target language selector modal ("WHAT DO YOU WANT TO LEARN?")
//   - Integrated LevelProgressBar in header
//   - Coin Wallet button ("Nạp Xu")
//   - Language chips & Certificate level filter pills (CEFR / JLPT / HSK)
//   - Bento-style cards with image backgrounds & live pulse status
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/language_theme.dart';
import '../../level/widget/level_progress_bar.dart';
import '../widget/language_selection_modal.dart';

/// Mock room data model.
class _Room {
  final int id;
  final String name;
  final String level;
  final String lang;
  final int users;
  final String status;
  final String desc;
  final String image;

  const _Room({
    required this.id,
    required this.name,
    required this.level,
    required this.lang,
    required this.users,
    required this.status,
    required this.desc,
    required this.image,
  });
}

// Mock data mirroring web page.tsx getLocalizedRooms()
const List<_Room> _mockRooms = [
  _Room(
    id: 101,
    name: 'Morning Conversation',
    level: 'B1',
    lang: 'en',
    users: 5,
    status: 'LIVE',
    desc: 'Practice reflexes with everyday topics. Focus on fluency and natural speech.',
    image: 'https://picsum.photos/seed/morning-studio/600/400',
  ),
  _Room(
    id: 102,
    name: 'Beginner Talk (日本語)',
    level: 'N5',
    lang: 'ja',
    users: 2,
    status: 'LIVE',
    desc: 'For absolute beginners learning Japanese. Slow-paced basic greetings.',
    image: 'https://picsum.photos/seed/kyoto-garden/600/400',
  ),
  _Room(
    id: 103,
    name: 'Advanced Discussion (中文)',
    level: 'HSK 4',
    lang: 'zh',
    users: 0,
    status: 'SCHEDULED',
    desc: 'Deep discussions on Chinese news and culture. Starts at 14:00.',
    image: 'https://picsum.photos/seed/forbidden-city/600/400',
  ),
  _Room(
    id: 104,
    name: 'Daily Vocabulary',
    level: 'A2',
    lang: 'en',
    users: 8,
    status: 'LIVE',
    desc: 'Learn essential vocabulary through real-life situations with flashcards.',
    image: 'https://picsum.photos/seed/minimal-library/600/400',
  ),
  _Room(
    id: 105,
    name: 'IELTS Speaking Club',
    level: 'B2',
    lang: 'en',
    users: 0,
    status: 'ENDED',
    desc: 'Practice IELTS Parts 2 & 3 with an AI examiner. Session completed.',
    image: 'https://picsum.photos/seed/oxford-exam/600/400',
  ),
];

class RoomLobbyScreen extends StatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen>
    with TickerProviderStateMixin {
  String _activeLang = 'en';
  String _activeLevel = '';
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late AnimationController _heroAnimCtrl;
  late AnimationController _bgAnimCtrl;

  @override
  void initState() {
    super.initState();
    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _heroAnimCtrl.forward();
  }

  @override
  void dispose() {
    _heroAnimCtrl.dispose();
    _bgAnimCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  LanguageConfig get _currentConfig => LanguageConfig.get(_activeLang);

  List<String> get _levelOptions => _currentConfig.levels;

  Color get _themeAccent => _currentConfig.accentColor;

  List<_Room> get _filteredRooms {
    return _mockRooms.where((room) {
      final matchesLang = room.lang == _activeLang;
      final matchesLevel = _activeLevel.isEmpty || room.level == _activeLevel;
      final matchesSearch = _searchQuery.isEmpty ||
          room.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.desc.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesLang && matchesLevel && matchesSearch;
    }).toList();
  }

  void _switchLang(String lang) {
    if (lang == _activeLang) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _activeLang = lang;
      _activeLevel = '';
      _searchQuery = '';
      _searchCtrl.clear();
    });
    _heroAnimCtrl.reset();
    _heroAnimCtrl.forward();
  }

  void _openLanguageModal() {
    LanguageSelectionModal.show(
      context,
      currentLang: _activeLang,
      onLanguageSelected: _switchLang,
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _joinRoom(int roomId) {
    HapticFeedback.lightImpact();
    context.push('/room-config', extra: {
      'roomId': 'room_$roomId',
      'userId': 'user_001',
      'roomName': _mockRooms.firstWhere((r) => r.id == roomId).name,
      'hostUserId': 'host_001',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Animated Background Canvas per Language (JA: Sakura, ZH: Lanterns)
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              if (_activeLang == 'ja') {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SakuraBackgroundPainter(
                    animationValue: _bgAnimCtrl.value * 10,
                  ),
                );
              } else if (_activeLang == 'zh') {
                return CustomPaint(
                  size: Size.infinite,
                  painter: LanternBackgroundPainter(
                    animationValue: _bgAnimCtrl.value * 5,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                // Level progress bar header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: LevelProgressBar(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: _themeAccent,
                    backgroundColor: AppColors.surfaceDark,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeroCard()),
                        SliverToBoxAdapter(child: _buildFilterSection()),
                        _buildRoomList(),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // Brand & Language Trigger
          GestureDetector(
            onTap: _openLanguageModal,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'LUCY',
                          style: TextStyle(
                            color: _themeAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentConfig.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    Text(
                      '${_currentConfig.label} ARCHIVE',
                      style: TextStyle(
                        color: _themeAccent.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: _themeAccent,
                  size: 20,
                ),
              ],
            ),
          ),
          const Spacer(),

          // Coin Wallet Button
          GestureDetector(
            onTap: () => context.push('/wallet-deposit'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Text('🪙', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text(
                    'Nạp Xu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Language Switcher Chips
          _buildLangChips(),
        ],
      ),
    );
  }

  Widget _buildLangChips() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['en', 'ja', 'zh'].map((code) {
          final isSelected = code == _activeLang;
          final cfg = LanguageConfig.get(code);

          return GestureDetector(
            onTap: () => _switchLang(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? cfg.accentColor.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: cfg.accentColor, width: 1)
                    : null,
              ),
              child: Text(
                cfg.flag,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── HERO CARD ───────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _themeAccent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _themeAccent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _themeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentConfig.certificateName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _themeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'SPEAK ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'WITHOUT FEAR.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _themeAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Phòng luyện tập ${_currentConfig.nativeLabel} thời gian thực với trí tuệ nhân tạo gợi ý từ vựng tức thì.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER SECTION ──────────────────────────────────────────

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "ALL" Filter Pill
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeLevel = '');
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _activeLevel.isEmpty
                      ? _themeAccent.withValues(alpha: 0.2)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeLevel.isEmpty
                        ? _themeAccent
                        : AppColors.textHint.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _activeLevel.isEmpty
                        ? _themeAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Certificate Level Pills
            ..._levelOptions.map((level) {
              final isSelected = _activeLevel == level;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activeLevel = level);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _themeAccent.withValues(alpha: 0.2)
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _themeAccent
                          : AppColors.textHint.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? _themeAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── ROOM LIST ───────────────────────────────────────────────

  Widget _buildRoomList() {
    final rooms = _filteredRooms;

    if (rooms.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.textHint.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            children: [
              Text('💬', style: TextStyle(fontSize: 32)),
              SizedBox(height: 12),
              Text(
                'Không tìm thấy phòng phù hợp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final room = rooms[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoomCard(
                room: room,
                accentColor: _themeAccent,
                flag: _currentConfig.flag,
                onJoin: () => _joinRoom(room.id),
              ),
            );
          },
          childCount: rooms.length,
        ),
      ),
    );
  }
}

/// Bento-style room card matching Web design.
class _RoomCard extends StatelessWidget {
  final _Room room;
  final Color accentColor;
  final String flag;
  final VoidCallback onJoin;

  const _RoomCard({
    required this.room,
    required this.accentColor,
    required this.flag,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = room.status == 'LIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? accentColor.withValues(alpha: 0.3)
              : AppColors.textHint.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            room.level,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          flag,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLive ? AppColors.accent : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isLive ? AppColors.accent : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            room.desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Footer: Users + Join button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '[ ${room.users} USERS ]',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textHint,
                ),
              ),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'THAM GIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
