import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/app_database.dart';
import '../../core/utilities/app_date.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/notes_style_field.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class ReminderEditorScreen extends StatefulWidget {
  final int? reminderId;
  const ReminderEditorScreen({super.key, this.reminderId});

  @override
  State<ReminderEditorScreen> createState() => _ReminderEditorScreenState();
}

class _ReminderEditorScreenState extends State<ReminderEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _reminderDate;
  late TimeOfDay _reminderTime;
  String? _repeatRule;
  String _color = '';
  bool _isLoading = true;
  bool _isActive = true;
  bool _alarmEnabled = true;
  Reminder? _existingReminder;

  String _originalTitle = '';
  String _originalDescription = '';
  DateTime _originalReminderDate = DateTime.now();
  TimeOfDay _originalReminderTime = TimeOfDay.now();
  String? _originalRepeatRule;
  String _originalColor = '';
  bool _originalIsActive = true;
  bool _originalAlarmEnabled = true;

  @override
  void initState() {
    super.initState();
    final defaultReminderTime = DateTime.now().add(const Duration(minutes: 5));
    _reminderDate = defaultReminderTime;
    _reminderTime = TimeOfDay.fromDateTime(defaultReminderTime);
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    if (widget.reminderId != null) {
      try {
        final reminders = await database.getAllReminders();
        _existingReminder = reminders.firstWhere(
          (r) => r.id == widget.reminderId,
        );
        _titleController.text = _existingReminder!.title;
        _descriptionController.text = _existingReminder!.description;
        _reminderDate = _existingReminder!.reminderTime;
        _reminderTime = TimeOfDay.fromDateTime(_existingReminder!.reminderTime);
        _repeatRule = _existingReminder!.repeatRule;
        _color = _existingReminder!.color;
        _isActive = _existingReminder!.isActive;
        _alarmEnabled = _existingReminder!.alarmEnabled;
        _originalTitle = _existingReminder!.title;
        _originalDescription = _existingReminder!.description;
        _originalReminderDate = _existingReminder!.reminderTime;
        _originalReminderTime = TimeOfDay.fromDateTime(
          _existingReminder!.reminderTime,
        );
        _originalRepeatRule = _existingReminder!.repeatRule;
        _originalColor = _existingReminder!.color;
        _originalIsActive = _existingReminder!.isActive;
        _originalAlarmEnabled = _existingReminder!.alarmEnabled;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<bool> _save() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Reminder'
        : _titleController.text.trim();
    final combinedDateTime = DateTime(
      _reminderDate.year,
      _reminderDate.month,
      _reminderDate.day,
      _reminderTime.hour,
      _reminderTime.minute,
    );

    try {
      if (_existingReminder != null) {
        await database.updateReminder(
          RemindersCompanion(
            id: drift.Value(_existingReminder!.id),
            title: drift.Value(title),
            description: drift.Value(_descriptionController.text),
            reminderTime: drift.Value(combinedDateTime),
            repeatRule: drift.Value(_repeatRule),
            color: drift.Value(_color),
            isActive: drift.Value(_isActive),
            alarmEnabled: drift.Value(_alarmEnabled),
          ),
        );
        // Schedule alarm for existing reminder
        if (_isActive && _alarmEnabled) {
          await notificationService.scheduleReminderAlarm(
            reminderId: _existingReminder!.id,
            title: title,
            description: _descriptionController.text,
            reminderDateTime: combinedDateTime,
            repeatRule: _repeatRule,
          );
        } else {
          await notificationService.cancelReminderAlarm(_existingReminder!.id);
        }
      } else {
        final newId = await database.createReminder(
          RemindersCompanion.insert(
            title: title,
            description: drift.Value(_descriptionController.text),
            reminderTime: combinedDateTime,
            repeatRule: drift.Value(_repeatRule),
            color: drift.Value(_color),
            alarmEnabled: drift.Value(_alarmEnabled),
            createdAt: DateTime.now(),
          ),
        );
        // Schedule alarm for new reminder
        if (_alarmEnabled) {
          await notificationService.scheduleReminderAlarm(
            reminderId: newId,
            title: title,
            description: _descriptionController.text,
            reminderDateTime: combinedDateTime,
            repeatRule: _repeatRule,
          );
        }
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save reminder: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the reminder. Please try again.'),
          ),
        );
      }
      return false;
    }
  }

  bool get _hasChanges {
    if (_titleController.text.trim() != _originalTitle) return true;
    if (_descriptionController.text.trim() != _originalDescription) return true;
    if (_reminderDate != _originalReminderDate) return true;
    if (_reminderTime?.hour != _originalReminderTime?.hour ||
        _reminderTime?.minute != _originalReminderTime?.minute)
      return true;
    if (_repeatRule != _originalRepeatRule) return true;
    if (_color != _originalColor) return true;
    if (_isActive != _originalIsActive) return true;
    if (_alarmEnabled != _originalAlarmEnabled) return true;
    return false;
  }

  bool get _hasContent => _titleController.text.trim().isNotEmpty;

  Future<void> _showBackDialog() async {
    final isNew = widget.reminderId == null && _hasContent;
    final hasChanges = widget.reminderId != null && _hasChanges;

    // New reminder with content → auto-save
    if (isNew) {
      if (await _save() && mounted) context.pop();
      return;
    }

    // No changes → just pop
    if (!hasChanges) {
      if (mounted) context.pop();
      return;
    }

    // Existing reminder with changes → show dialog
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
      if (await _save() && mounted) context.pop();
    } else if (result == 'discard') {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            _existingReminder != null ? l10n.reminder : l10n.newReminder,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Save reminder',
              icon: const Icon(Icons.save_rounded),
              onPressed: () async {
                if (await _save() && mounted) context.pop();
              },
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      NotesStyleField(
                        controller: _titleController,
                        hint: l10n.reminderTitle,
                        isTitle: true,
                        autofocus: widget.reminderId == null,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      NotesStyleField(
                        controller: _descriptionController,
                        hint: l10n.description,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.alarm_rounded),
                        title: const Text('Alarm'),
                        subtitle: const Text('Notify me at the reminder time'),
                        value: _alarmEnabled,
                        onChanged: (value) =>
                            setState(() => _alarmEnabled = value),
                      ),
                      const SizedBox(height: 24),

                      // Date & Time Section
                      Text(
                        l10n.dueDate,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(
                                AppDate.formatLong(context, _reminderDate),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final d = await AppDate.showPicker(
                                  context,
                                  initialDate: _reminderDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null)
                                  setState(() => _reminderDate = d);
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text(_reminderTime.format(context)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _reminderTime,
                                );
                                if (t != null)
                                  setState(() => _reminderTime = t);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Repeat Section
                      Text(
                        l10n.repeat,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [null, 'daily', 'weekly', 'monthly'].map((r) {
                          return ChoiceChip(
                            label: Text(
                              r == null
                                  ? l10n.once
                                  : r[0].toUpperCase() + r.substring(1),
                            ),
                            selected: _repeatRule == r,
                            onSelected: (_) => setState(() => _repeatRule = r),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Color Section
                      Text(
                        'Card Color',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ColorPicker(
                        selectedColor: _color,
                        onColorSelected: (c) => setState(() => _color = c),
                      ),
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
}
