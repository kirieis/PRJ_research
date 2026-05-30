// lib/features/pro_dashboard/widget/pin_resource_panel.dart
// ============================================================
// Project LUCY — Zone 3: Pin Resource Panel
// TextField + "Ghim" button + horizontal thumbnail list.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/pinned_resource.dart';

/// Zone 3 — Pin documents/images to the room.
///
/// Layout:
/// ```
/// ┌──────────────────────────────────────┐
/// │ 📌 Pinned Resources                  │
/// │ ┌─ [URL input          ] [📌 Ghim] ┐│
/// │ └────────────────────────────────────┘│
/// │ [thumb1] [thumb2] [thumb3] →         │
/// └──────────────────────────────────────┘
/// ```
class PinResourcePanel extends StatefulWidget {
  /// Currently pinned resources.
  final List<PinnedResource> pinnedResources;

  /// Whether a pin API call is in progress.
  final bool isPinning;

  /// Called when user taps "Ghim" with {resourceUrl, type}.
  final void Function(String resourceUrl, String type) onPinResource;

  const PinResourcePanel({
    super.key,
    required this.pinnedResources,
    required this.isPinning,
    required this.onPinResource,
  });

  @override
  State<PinResourcePanel> createState() => _PinResourcePanelState();
}

class _PinResourcePanelState extends State<PinResourcePanel> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.push_pin_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pinned Resources',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.pinnedResources.isNotEmpty)
                Text(
                  '${widget.pinnedResources.length}',
                  style: TextStyle(
                    color: AppColors.warning.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── URL Input + Pin Button ─────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste URL or image link...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.textHint.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.textHint.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.warning,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: widget.isPinning ? null : _onPinPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.warning.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: widget.isPinning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : const Icon(Icons.push_pin_rounded, size: 16),
                  label: const Text(
                    'Ghim',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Pinned Resources Thumbnails ─────────────────
          if (widget.pinnedResources.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No resources pinned yet',
                  style: TextStyle(
                    color: AppColors.textHint.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.pinnedResources.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final resource = widget.pinnedResources[index];
                  return _ResourceThumbnail(resource: resource);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onPinPressed() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Auto-detect type based on URL extension.
    final isImage = _isImageUrl(url);
    widget.onPinResource(url, isImage ? 'image' : 'url');
    _urlController.clear();
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg');
  }
}

/// Thumbnail card for a pinned resource.
class _ResourceThumbnail extends StatelessWidget {
  final PinnedResource resource;

  const _ResourceThumbnail({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon based on type.
          Icon(
            resource.isImage
                ? Icons.image_rounded
                : Icons.link_rounded,
            size: 24,
            color: resource.isImage
                ? AppColors.accent
                : AppColors.primary,
          ),
          const SizedBox(height: 4),
          // Truncated URL.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _truncateUrl(resource.resourceUrl),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateUrl(String url) {
    // Remove protocol for display.
    return url
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .replaceAll('www.', '');
  }
}
