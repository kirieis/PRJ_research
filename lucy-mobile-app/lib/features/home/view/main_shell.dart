// lib/features/home/view/main_shell.dart
// ============================================================
// Project LUCY — Main Shell with Bottom Navigation Bar
//
// Replaces the old top-nav web pattern with a mobile-native
// bottom navigation bar. Houses 4 primary destinations:
//   Tab 0: Room Lobby (Home)
//   Tab 1: Podcast Library
//   Tab 2: Wallet
//   Tab 3: Profile/Settings
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/bloc/wallet_event.dart';
import '../../wallet/view/wallet_deposit_screen.dart';
import '../../podcast/view/podcast_library_screen.dart';
import 'room_lobby_screen.dart';
import 'profile_tab.dart';

/// Main shell widget that provides bottom navigation across
/// the 4 primary sections of the app. Audio Room and Pro Dashboard
/// are pushed as full-screen routes on top of this shell.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Lazily built tabs to preserve state across navigation
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const RoomLobbyScreen(),
      const PodcastLibraryScreen(userId: 'user_123', accountType: 'super'),
      BlocProvider(
        create: (_) => WalletBloc()..add(const WalletBalanceFetched()),
        child: const WalletDepositScreen(),
      ),
      const ProfileTab(),
    ];
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_rounded,
                activeIcon: Icons.explore_rounded,
                label: 'Explore',
                isActive: _currentIndex == 0,
                onTap: () => _onTabSelected(0),
              ),
              _NavItem(
                icon: Icons.podcasts_outlined,
                activeIcon: Icons.podcasts_rounded,
                label: 'Podcast',
                isActive: _currentIndex == 1,
                onTap: () => _onTabSelected(1),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Wallet',
                isActive: _currentIndex == 2,
                onTap: () => _onTabSelected(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: _currentIndex == 3,
                onTap: () => _onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual bottom nav item with 48dp minimum touch target,
/// smooth color transition, and active indicator pill.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 56, // >= 48dp touch target
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 32 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textHint,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
