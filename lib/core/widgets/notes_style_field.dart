import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Text field matching the Notes editor input style:
/// square tinted container, RTL-aware padding, soft hint.
class NotesStyleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isTitle;
  final bool autofocus;

  const NotesStyleField({
    super.key,
    required this.controller,
    required this.hint,
    this.isTitle = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    return Container(
      constraints: isTitle ? null : const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.only(
        left: isRtl ? 4 : 16,
        right: isRtl ? 16 : 4,
        top: 18,
        bottom: isTitle ? 18 : 14,
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: isTitle ? 1 : null,
        minLines: isTitle ? null : 10,
        textAlignVertical: isTitle ? null : TextAlignVertical.top,
        style: isTitle
            ? const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            : const TextStyle(fontSize: 16, height: 1.7),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        textCapitalization: TextCapitalization.sentences,
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      ),
    );
  }
}
