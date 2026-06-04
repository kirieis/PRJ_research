// lib/features/walkthrough/view/walkthrough_screen.dart
// ============================================================
// Project LUCY — Walkthrough / Onboarding Screen
// A swipeable 3-page introduction to the app's key features.
// Uses BLoC for page state and navigates to /home on completion.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/walkthrough_bloc.dart';
import '../bloc/walkthrough_event.dart';
import '../bloc/walkthrough_state.dart';

/// Walkthrough screen — shown on first launch after splash.
///
/// Features:
/// - 3 swipeable pages with animated transitions.
/// - Dot indicators for current page.
/// - "Skip" button and "Next" / "Get Started" CTA.
class WalkthroughScreen extends StatelessWidget {
  const WalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalkthroughBloc(),
      child: const _WalkthroughView(),
    );
  }
}

class _WalkthroughView extends StatefulWidget {
  const _WalkthroughView();

  @override
  State<_WalkthroughView> createState() => _WalkthroughViewState();
}

class _WalkthroughViewState extends State<_WalkthroughView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalkthroughBloc, WalkthroughState>(
      listenWhen: (prev, curr) => curr.isCompleted && !prev.isCompleted,
      listener: (context, state) {
        // Navigate to home when walkthrough is finished.
        context.go('/home');
      },
      child: BlocConsumer<WalkthroughBloc, WalkthroughState>(
        listenWhen: (prev, curr) =>
            prev.currentPage != curr.currentPage && !curr.isCompleted,
        listener: (context, state) {
          // Animate PageView when BLoC changes page (from button tap).
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              state.currentPage,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.backgroundDark,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Skip Button ─────────────────────────
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 16),
                        child: TextButton(
                          onPressed: () {
                            context
                                .read<WalkthroughBloc>()
                                .add(const WalkthroughCompleted());
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Page Content ────────────────────────
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: state.totalPages,
                        onPageChanged: (index) {
                          context
                              .read<WalkthroughBloc>()
                              .add(WalkthroughPageChanged(index));
                        },
                        itemBuilder: (context, index) {
                          return _WalkthroughPage(
                            data: state.pages[index],
                            isActive: index == state.currentPage,
                          );
                        },
                      ),
                    ),

                    // ── Dot Indicators ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          state.totalPages,
                          (index) => _DotIndicator(
                            isActive: index == state.currentPage,
                          ),
                        ),
                      ),
                    ),

                    // ── Navigation Buttons ──────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Row(
                        children: [
                          // Back button (hidden on first page)
                          if (!state.isFirstPage)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _SecondaryButton(
                                  label: 'Back',
                                  onPressed: () {
                                    context
                                        .read<WalkthroughBloc>()
                                        .add(const WalkthroughBackPressed());
                                  },
                                ),
                              ),
                            ),

                          // Next / Get Started button
                          Expanded(
                            flex: state.isFirstPage ? 1 : 1,
                            child: PrimaryButton(
                              label: state.isLastPage ? 'Get Started' : 'Next',
                              icon: state.isLastPage
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              onPressed: () {
                                context
                                    .read<WalkthroughBloc>()
                                    .add(const WalkthroughNextPressed());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// WALKTHROUGH PAGE CONTENT
// ────────────────────────────────────────────────────────────────

class _WalkthroughPage extends StatelessWidget {
  final WalkthroughPageData data;
  final bool isActive;

  const _WalkthroughPage({
    required this.data,
    required this.isActive,
  });

  IconData _resolveIcon(IconType type) {
    switch (type) {
      case IconType.listen:
        return Icons.headphones_rounded;
      case IconType.community:
        return Icons.people_rounded;
      case IconType.ai:
        return Icons.auto_awesome_rounded;
    }
  }

  List<Color> _resolveGradient(IconType type) {
    switch (type) {
      case IconType.listen:
        return AppColors.primaryGradient;
      case IconType.community:
        return [AppColors.secondary, const Color(0xFFFFB347)];
      case IconType.ai:
        return [AppColors.accent, const Color(0xFF6C63FF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),

            // ── Icon Container ─────────────────────────
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _resolveGradient(data.icon),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: _resolveGradient(data.icon).first.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _resolveIcon(data.icon),
                size: 64,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 48),

            // ── Title ──────────────────────────────────
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ────────────────────────────
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// DOT INDICATOR
// ────────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// SECONDARY BUTTON (outline style for "Back")
// ────────────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
