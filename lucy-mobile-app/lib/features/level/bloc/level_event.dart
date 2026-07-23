// lib/features/level/bloc/level_event.dart
// ============================================================
// Project LUCY — Level BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

import '../../../core/models/level.dart';

/// Base event for the Level BLoC.
sealed class LevelEvent extends Equatable {
  const LevelEvent();

  @override
  List<Object?> get props => [];
}

/// Load current level progress from server/local storage.
class LevelProgressLoaded extends LevelEvent {
  const LevelProgressLoaded();
}

/// XP earned from a completed session.
class LevelXpEarned extends LevelEvent {
  final XpResult xpResult;

  const LevelXpEarned({required this.xpResult});

  @override
  List<Object?> get props => [xpResult];
}

/// User confirmed level up (after animation).
class LevelUpConfirmed extends LevelEvent {
  const LevelUpConfirmed();
}

/// Reset level progress (for testing/admin).
class LevelProgressReset extends LevelEvent {
  const LevelProgressReset();
}
