import 'package:flutter/material.dart';

/// Shows an enhanced delete confirmation dialog.
/// Returns true if the user confirmed, false otherwise.
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String itemName,
  String? description,
  bool isPermanent = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _DeleteConfirmDialog(
      title: title,
      itemName: itemName,
      description: description,
      isPermanent: isPermanent,
    ),
  );
  return confirmed == true;
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String itemName;
  final String? description;
  final bool isPermanent;

  const _DeleteConfirmDialog({
    required this.title,
    required this.itemName,
    this.description,
    this.isPermanent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon with animated glow circle ──
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade700,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isPermanent ? Icons.warning_rounded : Icons.delete_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ──
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Item name badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPermanent ? Icons.file_copy_outlined : Icons.inventory_2_outlined,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Description ──
            Text(
              description ??
                  (isPermanent
                      ? 'This action cannot be undone. The item will be permanently removed.'
                      : 'This item will be moved to Trash. You can restore it later from the Trash page.'),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Action buttons ──
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.red.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPermanent ? Icons.delete_forever_rounded : Icons.delete_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPermanent ? 'Delete Forever' : 'Move to Trash',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
