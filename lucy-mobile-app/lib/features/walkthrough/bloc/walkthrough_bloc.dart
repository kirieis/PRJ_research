// lib/features/walkthrough/bloc/walkthrough_bloc.dart
// ============================================================
// Project LUCY — Walkthrough BLoC
// Manages the onboarding walkthrough page navigation.
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'walkthrough_event.dart';
import 'walkthrough_state.dart';

/// BLoC handling walkthrough page navigation and completion.
class WalkthroughBloc extends Bloc<WalkthroughEvent, WalkthroughState> {
  WalkthroughBloc() : super(const WalkthroughState()) {
    on<WalkthroughNextPressed>(_onNextPressed);
    on<WalkthroughBackPressed>(_onBackPressed);
    on<WalkthroughPageChanged>(_onPageChanged);
    on<WalkthroughCompleted>(_onCompleted);
  }

  /// Advances to the next page, or marks as completed if on the last page.
  void _onNextPressed(
    WalkthroughNextPressed event,
    Emitter<WalkthroughState> emit,
  ) {
    if (state.isLastPage) {
      emit(state.copyWith(isCompleted: true));
    } else {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  /// Goes back to the previous page (no-op if on the first page).
  void _onBackPressed(
    WalkthroughBackPressed event,
    Emitter<WalkthroughState> emit,
  ) {
    if (!state.isFirstPage) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  /// Syncs state when the user swipes the PageView directly.
  void _onPageChanged(
    WalkthroughPageChanged event,
    Emitter<WalkthroughState> emit,
  ) {
    emit(state.copyWith(currentPage: event.pageIndex));
  }

  /// Marks the walkthrough as completed (skip or finish).
  void _onCompleted(
    WalkthroughCompleted event,
    Emitter<WalkthroughState> emit,
  ) {
    emit(state.copyWith(isCompleted: true));
  }
}
