// lib/features/home/view/profile_tab.dart
// ============================================================
// Project LUCY — Profile Tab (Placeholder)
//
// Minimal profile/settings screen for the bottom nav's 4th tab.
// Contains user info, debug navigation, and app settings.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Profile tab shown in the bottom navigation bar.
/// Provides quick access to user settings and debug navigation.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + Name
            _buildProfileHeader(),
            const SizedBox(height: 32),

            // Quick Actions
            _buildSectionLabel('DEVELOPMENT'),
            const SizedBox(height: 12),
            _buildNavTile(
              context,
              icon: Icons.headset_mic_rounded,
              label: 'Audio Room (Debug)',
              color: AppColors.primary,
              onTap: () => context.push('/audio-room'),
            ),
            _buildNavTile(
              context,
              icon: Icons.dashboard_customize_rounded,
              label: 'Pro Dashboard (Debug)',
              color: AppColors.accent,
              onTap: () => context.push('/pro-dashboard'),
            ),
            const SizedBox(height: 24),

            // Settings Section
            _buildSectionLabel('SETTINGS'),
            const SizedBox(height: 12),
            _buildNavTile(
              context,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              color: AppColors.warning,
              onTap: () {},
            ),
            _buildNavTile(
              context,
              icon: Icons.language_rounded,
              label: 'Language',
              color: AppColors.secondary,
              onTap: () {},
            ),
            _buildNavTile(
              context,
              icon: Icons.info_outline_rounded,
              label: 'About LUCY',
              color: AppColors.textSecondary,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                'MT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minh Tú',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'LEARNER · B1 English',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: AppColors.textHint,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textHint,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textHint,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
