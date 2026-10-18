import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/app_database.dart';
import '../../core/utilities/app_date.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class TaskEditorScreen extends StatefulWidget {
  final int? taskId;
  const TaskEditorScreen({super.key, this.taskId});
  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _repeatRule;
  String _color = '';
  bool _alarmEnabled = false;
  bool _isLoading = true;

  String _originalTitle = '';
  String _originalDescription = '';
  String _originalPriority = 'medium';
  DateTime? _originalDueDate;
  TimeOfDay? _originalDueTime;
  String? _originalRepeatRule;
  String _originalColor = '';
  bool _originalAlarmEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    if (widget.taskId != null) {
      try {
        final task = await database.getTask(widget.taskId!);
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _priority = task.priority;
        _dueDate = task.dueDate;
        _dueTime = task.dueTime != null
            ? TimeOfDay.fromDateTime(task.dueTime!)
            : null;
        _repeatRule = task.repeatRule;
        _color = task.color;
        _alarmEnabled = task.alarmEnabled;
        _originalTitle = task.title;
        _originalDescription = task.description;
        _originalPriority = task.priority;
        _originalDueDate = task.dueDate;
        _originalDueTime = task.dueTime != null
            ? TimeOfDay.fromDateTime(task.dueTime!)
            : null;
        _originalRepeatRule = task.repeatRule;
        _originalColor = task.color;
        _originalAlarmEnabled = task.alarmEnabled;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save({bool pop = false}) async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Task'
        : _titleController.text.trim();
    DateTime? combinedDateTime;
    if (_dueDate != null) {
      combinedDateTime = _dueDate;
      if (_dueTime != null)
        combinedDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
    }
    if (widget.taskId != null) {
      await database.updateTask(
        TasksCompanion(
          id: drift.Value(widget.taskId!),
          title: drift.Value(title),
          description: drift.Value(_descriptionController.text),
          priority: drift.Value(_priority),
          dueDate: drift.Value(_dueDate),
          dueTime: drift.Value(combinedDateTime),
          repeatRule: drift.Value(_repeatRule),
          color: drift.Value(_color),
          alarmEnabled: drift.Value(_alarmEnabled),
        ),
      );
      // Schedule alarm for existing task
      if (_alarmEnabled && combinedDateTime != null) {
        await notificationService.scheduleTaskAlarm(
          taskId: widget.taskId!,
          title: title,
          description: _descriptionController.text,
          dueDateTime: combinedDateTime,
        );
      } else {
        await notificationService.cancelTaskAlarm(widget.taskId!);
      }
    } else {
      final newId = await database.createTask(
        TasksCompanion.insert(
          title: title,
          description: drift.Value(_descriptionController.text),
          priority: drift.Value(_priority),
          dueDate: drift.Value(_dueDate),
          dueTime: drift.Value(combinedDateTime),
          repeatRule: drift.Value(_repeatRule),
          color: drift.Value(_color),
          alarmEnabled: drift.Value(_alarmEnabled),
          createdAt: DateTime.now(),
        ),
      );
      // Schedule alarm for new task
      if (_alarmEnabled && combinedDateTime != null) {
        await notificationService.scheduleTaskAlarm(
          taskId: newId,
          title: title,
          description: _descriptionController.text,
          dueDateTime: combinedDateTime,
        );
      }
    }
    if (pop && mounted) context.pop();
  }

  bool get _hasChanges {
    if (_titleController.text.trim() != _originalTitle) return true;
    if (_descriptionController.text.trim() != _originalDescription) return true;
    if (_priority != _originalPriority) return true;
    if (_color != _originalColor) return true;
    if (_repeatRule != _originalRepeatRule) return true;
    if (_alarmEnabled != _originalAlarmEnabled) return true;
    if (_dueDate != _originalDueDate) return true;
    if (_dueTime?.hour != _originalDueTime?.hour ||
        _dueTime?.minute != _originalDueTime?.minute)
      return true;
    return false;
  }

  bool get _hasContent => _titleController.text.trim().isNotEmpty;

  Future<void> _showBackDialog() async {
    final isNew = widget.taskId == null && _hasContent;
    final hasChanges = widget.taskId != null && _hasChanges;

    // New task with content → auto-save
    if (isNew) {
      await _save();
      if (mounted) context.pop();
      return;
    }

    // No changes → just pop
    if (!hasChanges) {
      if (mounted) context.pop();
      return;
    }

    // Existing task with changes → show dialog
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.save_alt_rounded, size: 36),
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save your changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'save') {
      await _save();
      if (mounted) context.pop();
    } else if (result == 'discard') {
      if (mounted) context.pop();
    }
  }

  Future<void> _deleteTask() async {
    if (widget.taskId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.unsavedChangesLost),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notificationService.cancelTaskAlarm(widget.taskId!);
      await database.deleteTask(widget.taskId!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_isLoading)
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );

    final titleText = widget.taskId != null ? l10n.task : 'New Task';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _showBackDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _showBackDialog(),
          ),
          title: Text(
            titleText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 28),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteTask();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            final r = ResponsiveUtils(context);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textField(
                        theme,
                        _titleController,
                        l10n.taskTitle,
                        isTitle: true,
                        autofocus: widget.taskId == null,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        theme,
                        _descriptionController,
                        l10n.description,
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(theme, Icons.flag_rounded, l10n.priority),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'low',
                          'medium',
                          'high',
                          'urgent',
                        ].map((p) => _priorityChip(theme, p)).toList(),
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(theme, Icons.event_rounded, l10n.dueDate),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dateTimeCard(
                            theme,
                            icon: Icons.calendar_today_rounded,
                            label: l10n.dueDate,
                            value: _dueDate != null
                                ? AppDate.formatShort(context, _dueDate!)
                                : l10n.noDueDate,
                            hasValue: _dueDate != null,
                            onTap: () async {
                              final d = await AppDate.showPicker(
                                context,
                                initialDate: _dueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) setState(() => _dueDate = d);
                            },
                            onClear: () => setState(() => _dueDate = null),
                          ),
                          const SizedBox(width: 10),
                          _dateTimeCard(
                            theme,
                            icon: Icons.access_time_rounded,
                            label: l10n.dueTime,
                            value: _dueTime != null
                                ? _dueTime!.format(context)
                                : l10n.noDueTime,
                            hasValue: _dueTime != null,
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _dueTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _dueTime = t);
                            },
                            onClear: () => setState(() => _dueTime = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.alarm_rounded),
                        title: const Text('Alarm'),
                        subtitle: Text(
                          _dueDate == null
                              ? 'Choose a due date and time to schedule an alarm'
                              : 'Notify me when this task is due',
                        ),
                        value: _alarmEnabled,
                        onChanged: _dueDate == null
                            ? null
                            : (value) => setState(() => _alarmEnabled = value),
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(theme, Icons.repeat_rounded, l10n.repeat),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  null,
                                  'daily',
                                  'weekly',
                                  'monthly',
                                  'yearly',
                                  'weekdays',
                                  'weekends',
                                ]
                                .map(
                                  (r) => ChoiceChip(
                                    label: Text(
                                      r == null
                                          ? l10n.none
                                          : r[0].toUpperCase() + r.substring(1),
                                    ),
                                    selected: _repeatRule == r,
                                    onSelected: (_) =>
                                        setState(() => _repeatRule = r),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(
                        theme,
                        Icons.palette_outlined,
                        'Card Color',
                      ),
                      const SizedBox(height: 10),
                      ColorPicker(
                        selectedColor: _color,
                        onColorSelected: (c) => setState(() => _color = c),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _textField(
    ThemeData theme,
    TextEditingController controller,
    String hint, {
    bool isTitle = false,
    bool autofocus = false,
  }) {
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
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        textCapitalization: TextCapitalization.sentences,
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(
              alpha: isDark ? 0.28 : 0.1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  (IconData, Color) _priorityMeta(String p) {
    switch (p) {
      case 'low':
        return (Icons.keyboard_arrow_down_rounded, const Color(0xFF22C55E));
      case 'medium':
        return (Icons.drag_handle_rounded, const Color(0xFF3B82F6));
      case 'high':
        return (Icons.keyboard_arrow_up_rounded, const Color(0xFFF59E0B));
      default:
        return (Icons.local_fire_department_rounded, const Color(0xFFEF4444));
    }
  }

  Widget _priorityChip(ThemeData theme, String value) {
    final (icon, color) = _priorityMeta(value);
    final isDark = theme.brightness == Brightness.dark;
    final selected = _priority == value;
    final label = value[0].toUpperCase() + value.substring(1);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _priority = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.3 : 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required bool hasValue,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
            decoration: BoxDecoration(
              color: hasValue
                  ? theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.16 : 0.06,
                    )
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue
                    ? theme.colorScheme.primary.withValues(alpha: 0.45)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: hasValue
                        ? theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          )
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.7,
                          ),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: hasValue
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasValue
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
