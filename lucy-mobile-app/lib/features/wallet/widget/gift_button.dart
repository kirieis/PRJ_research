// lib/features/wallet/widget/gift_button.dart
// ============================================================
// Project LUCY — Gift Button + Fly Animation
//
// Bottom sheet: flower (5k), star (20k), crown (50k)
// Debounce: 2 seconds to prevent double-tap
// Animation: OverlayEntry + AnimationController
//   - Icon flies from button → host avatar
//   - Scale: 1 → 1.5 → 0
//   - Opacity: 1 → 0 (last 40%)
// Error 409: Snackbar "Số dư không đủ" + dismiss action
// No auto-retry — user must manually re-trigger.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

/// Gift type definition with pricing and emoji.
class _GiftDef {
  final String type;
  final String emoji;
  final int price;
  final String label;
  final Color color;

  const _GiftDef({
    required this.type,
    required this.emoji,
    required this.price,
    required this.label,
    required this.color,
  });
}

const _gifts = [
  _GiftDef(type: 'flower', emoji: '🌸', price: 5000, label: 'Hoa', color: Color(0xFFFF8FA3)),
  _GiftDef(type: 'star', emoji: '⭐', price: 20000, label: 'Ngôi sao', color: Color(0xFFFFD700)),
  _GiftDef(type: 'crown', emoji: '👑', price: 50000, label: 'Vương miện', color: Color(0xFFE8A317)),
];

/// Gift button that opens a bottom sheet to select and send gifts.
///
/// Requires [WalletBloc] in the widget tree.
/// Uses [OverlayEntry] for fly animation to avoid parent clipping.
///
/// **Debounce:** 2-second cooldown after each send.
/// **Error 409:** Shows "Số dư không đủ" snackbar with dismiss button.
class GiftButton extends StatefulWidget {
  /// The userId of the gift recipient (Host).
  final String toUserId;

  /// Optional target position for the fly animation end point.
  /// If null, defaults to screen top-center.
  final GlobalKey? hostAvatarKey;

  const GiftButton({super.key, required this.toUserId, this.hostAvatarKey});

  @override
  State<GiftButton> createState() => _GiftButtonState();
}

class _GiftButtonState extends State<GiftButton> {
  bool _isDebouncing = false;
  final GlobalKey _buttonKey = GlobalKey();
  final NumberFormat _fmt = NumberFormat('#,###', 'vi_VN');

  void _showGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GiftBottomSheet(
        gifts: _gifts,
        fmt: _fmt,
        isDebouncing: _isDebouncing,
        onSelect: (gift) {
          Navigator.pop(ctx);
          _sendGift(gift);
        },
      ),
    );
  }

  Future<void> _sendGift(_GiftDef gift) async {
    if (_isDebouncing) return;

    // Start 2-second debounce immediately.
    setState(() => _isDebouncing = true);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isDebouncing = false);
    });

    // Dispatch gift event via BLoC.
    context.read<WalletBloc>().add(WalletGiftSent(
          toUserId: widget.toUserId,
          amount: gift.price,
          giftType: gift.type,
        ));

    // FIX: Thay `await for` bằng `.first.timeout()` để tránh hang vĩnh viễn.
    try {
      final bloc = context.read<WalletBloc>();
      final resultState = await bloc.stream
          .where((s) =>
              s.status == WalletStatus.giftSuccess ||
              s.status == WalletStatus.error)
          .first
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resultState.status == WalletStatus.giftSuccess) {
        _triggerFlyAnimation(gift.emoji);
      } else if (resultState.isInsufficientBalance) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Text('Số dư không đủ'),
          ]),
          action: SnackBarAction(label: 'Tắt', onPressed: () {}),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.timer_off_rounded, color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Text('Hết thời gian chờ, vui lòng thử lại'),
          ]),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _triggerFlyAnimation(String emoji) {
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final startPos = renderBox.localToGlobal(Offset.zero);

    // Target: host avatar position or fallback to top-center.
    Offset endPos;
    if (widget.hostAvatarKey?.currentContext != null) {
      final hostBox = widget.hostAvatarKey!.currentContext!.findRenderObject() as RenderBox;
      endPos = hostBox.localToGlobal(Offset.zero);
    } else {
      endPos = Offset(MediaQuery.of(context).size.width / 2 - 25, 100);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GiftFlyAnimation(
        emoji: emoji,
        startPos: startPos,
        endPos: endPos,
        onComplete: () => entry.remove(),
      ),
    );

    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _isDebouncing
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFC471F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _isDebouncing ? AppColors.textHint.withValues(alpha: 0.3) : null,
        boxShadow: _isDebouncing
            ? null
            : [BoxShadow(color: const Color(0xFFFF6B9D).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _buttonKey,
          onTap: _isDebouncing ? null : _showGiftSheet,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: _isDebouncing ? AppColors.textHint : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet showing gift options with pricing.
class _GiftBottomSheet extends StatelessWidget {
  final List<_GiftDef> gifts;
  final NumberFormat fmt;
  final bool isDebouncing;
  final ValueChanged<_GiftDef> onSelect;

  const _GiftBottomSheet({
    required this.gifts,
    required this.fmt,
    required this.isDebouncing,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle bar.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tặng quà',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: gifts.map((g) => _giftTile(context, g)).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _giftTile(BuildContext context, _GiftDef gift) {
    return GestureDetector(
      onTap: isDebouncing ? null : () => onSelect(gift),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDebouncing ? 0.4 : 1.0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: gift.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gift.color.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(gift.emoji, style: const TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 8),
          Text(gift.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${fmt.format(gift.price)}đ',
              style: TextStyle(color: gift.color, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

/// Fly animation widget rendered via OverlayEntry.
///
/// Animates gift emoji from [startPos] to [endPos]:
///   - Position: curved ease-out trajectory
///   - Scale: 1.0 → 1.5 (40%) → 0.0 (60%)
///   - Opacity: 1.0 (60%) → 0.0 (40%)
class _GiftFlyAnimation extends StatefulWidget {
  final String emoji;
  final Offset startPos;
  final Offset endPos;
  final VoidCallback onComplete;

  const _GiftFlyAnimation({
    required this.emoji,
    required this.startPos,
    required this.endPos,
    required this.onComplete,
  });

  @override
  State<_GiftFlyAnimation> createState() => _GiftFlyAnimationState();
}

class _GiftFlyAnimationState extends State<_GiftFlyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _posAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _posAnim = Tween<Offset>(begin: widget.startPos, end: widget.endPos)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.0), weight: 60),
    ]).animate(_ctrl);

    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: _posAnim.value.dx,
          top: _posAnim.value.dy,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Text(widget.emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}
