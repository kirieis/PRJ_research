// lib/features/walkthrough/bloc/walkthrough_state.dart
// ============================================================
// Project LUCY — Walkthrough BLoC States
// ============================================================

import 'package:equatable/equatable.dart';

/// Data model for a single walkthrough page.
class WalkthroughPageData extends Equatable {
  final String title;
  final String description;
  final IconType icon;

  const WalkthroughPageData({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  List<Object?> get props => [title, description, icon];
}

/// Icon types for walkthrough pages (avoids importing Flutter in state).
enum IconType { listen, community, ai }

/// Immutable state for the Walkthrough BLoC.
class WalkthroughState extends Equatable {
  /// Current page index (0-based).
  final int currentPage;

  /// Total number of walkthrough pages.
  final int totalPages;

  /// Whether the walkthrough has been completed/skipped.
  final bool isCompleted;

  /// Pre-defined walkthrough page content.
  final List<WalkthroughPageData> pages;

  const WalkthroughState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.isCompleted = false,
    this.pages = const [
      WalkthroughPageData(
        title: 'Listen & Learn',
        description:
            'Immerse yourself in real conversations. '
            'Practice listening skills with AI-powered audio lessons '
            'tailored to your level.',
        icon: IconType.listen,
      ),
      WalkthroughPageData(
        title: 'Connect & Speak',
        description:
            'Join a vibrant community of language learners. '
            'Practice speaking with peers and native speakers '
            'in live audio rooms.',
        icon: IconType.community,
      ),
      WalkthroughPageData(
        title: 'AI-Powered Growth',
        description:
            'Get personalized feedback from our AI tutor. '
            'Track your progress and unlock new levels as you '
            'master each skill.',
        icon: IconType.ai,
      ),
    ],
  });

  /// Whether the current page is the last one.
  bool get isLastPage => currentPage >= totalPages - 1;

  /// Whether the current page is the first one.
  bool get isFirstPage => currentPage == 0;

  /// Creates a copy of this state with optional field overrides.
  WalkthroughState copyWith({
    int? currentPage,
    bool? isCompleted,
  }) {
    return WalkthroughState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
      isCompleted: isCompleted ?? this.isCompleted,
      pages: pages,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, isCompleted, pages];
}
