import 'package:flutter/material.dart';

/// Predefined color palette for items. Empty string means no color (default).
const List<String> kItemColors = [
  '',           // No color (default)
  '#6366f1',   // Indigo
  '#ef4444',   // Red
  '#f59e0b',   // Amber
  '#22c55e',   // Green
  '#3b82f6',   // Blue
  '#8b5cf6',   // Violet
  '#ec4899',   // Pink
  '#06b6d4',   // Cyan
  '#f97316',   // Orange
  '#14b8a6',   // Teal
  '#84cc16',   // Lime
];

/// Parse a hex color string like '#6366f1' to a Color.
/// Returns null for empty string (no color).
Color? parseColor(String hex) {
  if (hex.isEmpty) return null;
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

/// A horizontal row of color circles for picking a background color.
class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kItemColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final hex = kItemColors[index];
          final color = parseColor(hex);
          final isSelected = hex == selectedColor;
          return GestureDetector(
            onTap: () => onColorSelected(hex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: (color ?? Colors.grey).withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
              child: color == null
                  ? Icon(Icons.format_color_reset, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Apply a background color to a Card/Container based on hex string.
/// Returns a BoxDecoration with the appropriate background color.
BoxDecoration colorDecoration(String hex, {double radius = 16}) {
  final color = parseColor(hex);
  return BoxDecoration(
    color: color?.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(radius),
    border: color != null ? Border.all(color: color.withValues(alpha: 0.25)) : null,
  );
}
