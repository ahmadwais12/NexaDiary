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

class CalendarEventEditorScreen extends StatefulWidget {
  final int? eventId;
  final DateTime? initialDate;
  const CalendarEventEditorScreen({super.key, this.eventId, this.initialDate});

  @override
  State<CalendarEventEditorScreen> createState() =>
      _CalendarEventEditorScreenState();
}

class _CalendarEventEditorScreenState extends State<CalendarEventEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  bool _allDay = false;
  bool _alarmEnabled = false;
  String _selectedColor = '#6366f1';
  bool _isLoading = true;

  String _originalTitle = '';
  String _originalDescription = '';
  DateTime _originalStartDate = DateTime.now();
  TimeOfDay _originalStartTime = TimeOfDay.now();
  bool _originalAllDay = false;
  bool _originalAlarmEnabled = false;
  String _originalSelectedColor = '#6366f1';

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _startDate = widget.initialDate!;
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    if (widget.eventId != null) {
      try {
        final events = await database.getEventsForDate(_startDate);
        final event = events.firstWhere((e) => e.id == widget.eventId);
        _titleController.text = event.title;
        _descriptionController.text = event.description;
        _startDate = event.startTime;
        _startTime = TimeOfDay.fromDateTime(event.startTime);
        _allDay = event.allDay;
        _alarmEnabled = event.alarmEnabled;
        _selectedColor = event.color;
        _originalTitle = event.title;
        _originalDescription = event.description;
        _originalStartDate = event.startTime;
        _originalStartTime = TimeOfDay.fromDateTime(event.startTime);
        _originalAllDay = event.allDay;
        _originalAlarmEnabled = event.alarmEnabled;
        _originalSelectedColor = event.color;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Event'
        : _titleController.text.trim();

    final startDt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    if (widget.eventId != null) {
      await database.updateCalendarEvent(
        CalendarEventsCompanion(
          id: drift.Value(widget.eventId!),
          title: drift.Value(title),
          description: drift.Value(_descriptionController.text),
          startTime: drift.Value(startDt),
          allDay: drift.Value(_allDay),
          alarmEnabled: drift.Value(_alarmEnabled),
          color: drift.Value(_selectedColor),
        ),
      );
      if (_alarmEnabled) {
        await notificationService.scheduleCalendarAlarm(
          eventId: widget.eventId!,
          title: title,
          description: _descriptionController.text,
          eventStartDateTime: startDt,
        );
      } else {
        await notificationService.cancelCalendarAlarm(widget.eventId!);
      }
    } else {
      final newId = await database.createCalendarEvent(
        CalendarEventsCompanion.insert(
          title: title,
          description: drift.Value(_descriptionController.text),
          startTime: startDt,
          allDay: drift.Value(_allDay),
          alarmEnabled: drift.Value(_alarmEnabled),
          color: drift.Value(_selectedColor),
          createdAt: DateTime.now(),
        ),
      );
      if (_alarmEnabled) {
        await notificationService.scheduleCalendarAlarm(
          eventId: newId,
          title: title,
          description: _descriptionController.text,
          eventStartDateTime: startDt,
        );
      }
    }
  }

  bool get _hasChanges {
    if (_titleController.text.trim() != _originalTitle) return true;
    if (_descriptionController.text.trim() != _originalDescription) return true;
    if (_startDate != _originalStartDate) return true;
    if (_startTime?.hour != _originalStartTime?.hour ||
        _startTime?.minute != _originalStartTime?.minute)
      return true;
    if (_allDay != _originalAllDay) return true;
    if (_alarmEnabled != _originalAlarmEnabled) return true;
    if (_selectedColor != _originalSelectedColor) return true;
    return false;
  }

  bool get _hasContent => _titleController.text.trim().isNotEmpty;

  Future<void> _showBackDialog() async {
    final isNew = widget.eventId == null && _hasContent;
    final hasChanges = widget.eventId != null && _hasChanges;

    // New event with content → auto-save
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

    // Existing event with changes → show dialog
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
            widget.eventId != null ? l10n.calendar : l10n.newEvent,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [],
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
                        hint: l10n.eventTitle,
                        isTitle: true,
                        autofocus: widget.eventId == null,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      NotesStyleField(
                        controller: _descriptionController,
                        hint: l10n.description,
                      ),
                      const SizedBox(height: 24),

                      // All Day Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        child: SwitchListTile(
                          title: Text(l10n.allDay),
                          value: _allDay,
                          onChanged: (v) => setState(() => _allDay = v),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.alarm_rounded),
                        title: const Text('Alarm'),
                        subtitle: Text(
                          _allDay
                              ? 'All-day events do not have a specific alarm time'
                              : 'Notify me 15 minutes before this event',
                        ),
                        value: _alarmEnabled,
                        onChanged: _allDay
                            ? null
                            : (value) => setState(() => _alarmEnabled = value),
                      ),
                      const SizedBox(height: 16),

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
                                AppDate.formatLong(context, _startDate),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final d = await AppDate.showPicker(
                                  context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => _startDate = d);
                              },
                            ),
                            if (!_allDay) ...[
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Text(
                                  '${l10n.start}: ${_startTime.format(context)}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime,
                                  );
                                  if (t != null) setState(() => _startTime = t);
                                },
                              ),
                            ],
                          ],
                        ),
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
                        selectedColor: _selectedColor,
                        onColorSelected: (c) =>
                            setState(() => _selectedColor = c),
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
