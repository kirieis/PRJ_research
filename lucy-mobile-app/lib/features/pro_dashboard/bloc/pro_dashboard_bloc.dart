// lib/features/pro_dashboard/bloc/pro_dashboard_bloc.dart
// ============================================================
// Project LUCY — Pro Dashboard BLoC
// Orchestrates sub-level control, speaker queue, and pin resources.
//
// Socket events: kebab-case matching Node.js server convention.
// API calls: Dev 3 Spring Boot endpoints via ProApiService.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../audio_room/service/socket_service.dart';
import '../model/sub_level_info.dart';
import '../service/pro_api_service.dart';
import 'pro_dashboard_event.dart';
import 'pro_dashboard_state.dart';

/// BLoC managing the Pro Dashboard's three zones.
///
/// Zone 1: Sub-level control (force advance, display current)
/// Zone 2: Speaking queue (approve/skip speakers)
/// Zone 3: Pinned resources (pin URLs/images via API)
///
/// Subscribes to [SocketService] streams for realtime updates
/// and uses [ProApiService] for REST API calls.
class ProDashboardBloc extends Bloc<ProDashboardEvent, ProDashboardState> {
  final SocketService _socketService;
  final ProApiService _apiService;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _cooldownTimer;

  ProDashboardBloc({
    required SocketService socketService,
    required ProApiService apiService,
  })  : _socketService = socketService,
        _apiService = apiService,
        super(const ProDashboardState()) {
    on<ProDashboardStarted>(_onStarted);
    on<ProDashboardNextSublevelPressed>(_onNextSublevelPressed);
    on<ProDashboardCooldownExpired>(_onCooldownExpired);
    on<ProDashboardSpeakerApproved>(_onSpeakerApproved);
    on<ProDashboardSpeakerSkipped>(_onSpeakerSkipped);
    on<ProDashboardSpeakQueueUpdated>(_onSpeakQueueUpdated);
    on<ProDashboardResourcePinned>(_onResourcePinned);
    on<ProDashboardSublevelChanged>(_onSublevelChanged);
    on<ProDashboardRoomStateReceived>(_onRoomStateReceived);
  }

  // ── LIFECYCLE ─────────────────────────────────────────────

  Future<void> _onStarted(
    ProDashboardStarted event,
    Emitter<ProDashboardState> emit,
  ) async {
    emit(state.copyWith(
      status: ProDashboardStatus.loading,
      roomId: event.roomId,
      authState: event.authState,
    ));

    try {
      // Subscribe to socket events.
      _subscribeToSocketEvents();

      // Load moderator hints (fire and forget — not blocking).
      _apiService.getModeratorHints(event.roomId).then((hints) {
        developer.log(
          '📋 Loaded ${hints.length} moderator hints',
          name: 'ProDashboardBloc',
        );
      });

      emit(state.copyWith(status: ProDashboardStatus.ready));

      developer.log(
        '✅ Pro Dashboard started for room: ${event.roomId}, '
        'role: ${event.authState.role}',
        name: 'ProDashboardBloc',
      );
    } catch (e) {
      developer.log(
        '❌ Dashboard init failed: $e',
        name: 'ProDashboardBloc',
        error: e,
      );
      emit(state.copyWith(
        status: ProDashboardStatus.error,
        errorMessage: 'Failed to initialize dashboard: $e',
      ));
    }
  }

  // ── ZONE 1: SUB-LEVEL CONTROL ─────────────────────────────

  Future<void> _onNextSublevelPressed(
    ProDashboardNextSublevelPressed event,
    Emitter<ProDashboardState> emit,
  ) async {
    // Guard: already in cooldown or not a moderator.
    if (state.isNextCooldown || !state.canModerate) return;

    // Guard: already at last sub-level.
    if (state.currentSublevel?.isLast == true) return;

    developer.log(
      '▶ Force next sublevel for room: ${state.roomId}',
      name: 'ProDashboardBloc',
    );

    // Emit socket event to server.
    _socketService.emitForceNextSublevel(state.roomId);

    // Start 3-second cooldown.
    emit(state.copyWith(isNextCooldown: true));

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 3), () {
      add(const ProDashboardCooldownExpired());
    });
  }

  void _onCooldownExpired(
    ProDashboardCooldownExpired event,
    Emitter<ProDashboardState> emit,
  ) {
    emit(state.copyWith(isNextCooldown: false));
  }

  void _onSublevelChanged(
    ProDashboardSublevelChanged event,
    Emitter<ProDashboardState> emit,
  ) {
    developer.log(
      '📚 Sub-level changed: ${event.sublevel.displayLabel}',
      name: 'ProDashboardBloc',
    );
    emit(state.copyWith(currentSublevel: event.sublevel));
  }

  // ── ZONE 2: SPEAKING QUEUE ────────────────────────────────

  Future<void> _onSpeakerApproved(
    ProDashboardSpeakerApproved event,
    Emitter<ProDashboardState> emit,
  ) async {
    developer.log(
      '✅ Approved speaker: ${event.userId}',
      name: 'ProDashboardBloc',
    );

    // Emit to server.
    _socketService.emitApproveSpeaker(
      roomId: state.roomId,
      userId: event.userId,
    );

    // Optimistically remove from local queue.
    final updatedQueue = state.speakQueue
        .where((id) => id != event.userId)
        .toList();
    emit(state.copyWith(speakQueue: updatedQueue));
  }

  Future<void> _onSpeakerSkipped(
    ProDashboardSpeakerSkipped event,
    Emitter<ProDashboardState> emit,
  ) async {
    developer.log(
      '❌ Skipped speaker: ${event.userId}',
      name: 'ProDashboardBloc',
    );

    // Emit to server.
    _socketService.emitSkipSpeaker(
      roomId: state.roomId,
      userId: event.userId,
    );

    // Optimistically remove from local queue.
    final updatedQueue = state.speakQueue
        .where((id) => id != event.userId)
        .toList();
    emit(state.copyWith(speakQueue: updatedQueue));
  }

  void _onSpeakQueueUpdated(
    ProDashboardSpeakQueueUpdated event,
    Emitter<ProDashboardState> emit,
  ) {
    // Add to queue if not already present.
    if (!state.speakQueue.contains(event.userId)) {
      emit(state.copyWith(
        speakQueue: [...state.speakQueue, event.userId],
      ));
    }
  }

  // ── ZONE 3: PIN RESOURCES ─────────────────────────────────

  Future<void> _onResourcePinned(
    ProDashboardResourcePinned event,
    Emitter<ProDashboardState> emit,
  ) async {
    if (event.resourceUrl.trim().isEmpty) return;

    emit(state.copyWith(isPinning: true));

    developer.log(
      '📌 Pinning resource: ${event.type} — ${event.resourceUrl}',
      name: 'ProDashboardBloc',
    );

    final resource = await _apiService.pinResource(
      roomId: state.roomId,
      resourceUrl: event.resourceUrl,
      type: event.type,
    );

    if (resource != null) {
      emit(state.copyWith(
        isPinning: false,
        pinnedResources: [...state.pinnedResources, resource],
      ));
    } else {
      emit(state.copyWith(
        isPinning: false,
        errorMessage: 'Failed to pin resource. Please try again.',
      ));
    }
  }

  // ── ROOM STATE ────────────────────────────────────────────

  void _onRoomStateReceived(
    ProDashboardRoomStateReceived event,
    Emitter<ProDashboardState> emit,
  ) {
    final data = event.data;

    // Extract sub-level info if present.
    SubLevelInfo? sublevel;
    if (data['currentSublevel'] is Map<String, dynamic>) {
      sublevel = SubLevelInfo.fromJson(
        data['currentSublevel'] as Map<String, dynamic>,
      );
    }

    // Extract speak queue if present.
    List<String>? queue;
    if (data['speakQueue'] is List) {
      queue = (data['speakQueue'] as List)
          .map((e) => e.toString())
          .toList();
    }

    emit(state.copyWith(
      currentSublevel: sublevel ?? state.currentSublevel,
      speakQueue: queue ?? state.speakQueue,
    ));
  }

  // ── STREAM SUBSCRIPTIONS ──────────────────────────────────

  void _subscribeToSocketEvents() {
    _subscriptions.addAll([
      // Sub-level advanced.
      _socketService.onNextSublevel.listen((data) {
        add(ProDashboardSublevelChanged(SubLevelInfo.fromJson(data)));
      }),

      // Full room state snapshot.
      _socketService.onRoomStateUpdated.listen((data) {
        add(ProDashboardRoomStateReceived(data));
      }),

      // Hand raised — new speaker in queue.
      _socketService.onUserRaisedHand.listen((userId) {
        add(ProDashboardSpeakQueueUpdated(userId));
      }),
    ]);
  }

  // ── CLEANUP ───────────────────────────────────────────────

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }
}
