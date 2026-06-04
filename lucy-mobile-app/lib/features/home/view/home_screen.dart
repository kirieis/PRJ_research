// lib/features/home/view/home_screen.dart
// ============================================================
// Project LUCY — Home Screen
// Navigation target after successful splash initialization.
// Includes debug menu to access completed modules.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'LUCY Home',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'App Ready',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All features integrated successfully.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Developer Menu (Dev 5)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildNavButton(
              context,
              label: 'Audio Room Screen',
              icon: Icons.headset_mic_rounded,
              color: AppColors.primary,
              route: '/audio-room',
            ),
            _buildNavButton(
              context,
              label: 'Pro Dashboard',
              icon: Icons.dashboard_customize_rounded,
              color: AppColors.accent,
              route: '/pro-dashboard',
            ),
            _buildNavButton(
              context,
              label: 'Podcast Library',
              icon: Icons.podcasts_rounded,
              color: AppColors.secondary,
              route: '/podcast-library',
            ),
            _buildNavButton(
              context,
              label: 'Wallet Deposit',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.success,
              route: '/wallet-deposit',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
