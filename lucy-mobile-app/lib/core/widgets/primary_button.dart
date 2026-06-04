// lib/core/widgets/primary_button.dart
// ============================================================
// Project LUCY — Reusable Primary Button
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable CTA button with loading, disabled, and gradient states.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double height;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height = 52.0,
    this.icon,
  });

  bool get _isInteractive => !isLoading && !isDisabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: _isInteractive || isLoading
              ? const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _isInteractive || isLoading ? null : AppColors.textHint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isInteractive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isInteractive ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(child: _buildChild()),
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: _labelStyle),
        ],
      );
    }

    return Text(label, style: _labelStyle);
  }

  TextStyle get _labelStyle => const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );
}
