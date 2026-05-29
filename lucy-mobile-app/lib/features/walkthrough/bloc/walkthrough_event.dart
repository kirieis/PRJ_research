// lib/features/walkthrough/bloc/walkthrough_event.dart
// ============================================================
// Project LUCY — Walkthrough BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

/// Base class for all Walkthrough-related events.
sealed class WalkthroughEvent extends Equatable {
  const WalkthroughEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the user taps "Next" to advance one page.
class WalkthroughNextPressed extends WalkthroughEvent {
  const WalkthroughNextPressed();
}

/// Fired when the user taps "Back" or swipes to go back.
class WalkthroughBackPressed extends WalkthroughEvent {
  const WalkthroughBackPressed();
}

/// Fired when the user taps "Skip" or "Get Started" to finish.
class WalkthroughCompleted extends WalkthroughEvent {
  const WalkthroughCompleted();
}

/// Fired when the page changes via swipe gesture.
class WalkthroughPageChanged extends WalkthroughEvent {
  final int pageIndex;
  const WalkthroughPageChanged(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}
