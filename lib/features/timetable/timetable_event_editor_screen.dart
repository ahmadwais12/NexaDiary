import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/app_database.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/widgets/notes_style_field.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class TimetableEventEditorScreen extends StatefulWidget {
  final int? eventId;
  final int dayOfWeek;
  const TimetableEventEditorScreen({
    super.key,
    this.eventId,
    required this.dayOfWeek,
  });

  @override
  State<TimetableEventEditorScreen> createState() =>
      _TimetableEventEditorScreenState();
}

class _TimetableEventEditorScreenState
    extends State<TimetableEventEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
  String _selectedColor = '#6366f1';
  bool _isLoading = true;
  bool _alarmEnabled = false;

  String _originalTitle = '';
  String _originalDescription = '';
  TimeOfDay _originalStartTime = TimeOfDay.now();
  TimeOfDay _originalEndTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: 0,
  );
  String _originalSelectedColor = '#6366f1';
  bool _originalAlarmEnabled = false;

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    if (widget.eventId != null) {
      try {
        final events = await database.getTimetableForDay(widget.dayOfWeek);
        final event = events.firstWhere((e) => e.id == widget.eventId);
        _titleController.text = event.title;
        _descriptionController.text = event.description;
        _startTime = TimeOfDay.fromDateTime(event.startTime);
        _endTime = TimeOfDay.fromDateTime(event.endTime);
        _selectedColor = event.color;
        _alarmEnabled = event.alarmEnabled;
        _originalTitle = event.title;
        _originalDescription = event.description;
        _originalStartTime = TimeOfDay.fromDateTime(event.startTime);
        _originalEndTime = TimeOfDay.fromDateTime(event.endTime);
        _originalSelectedColor = event.color;
        _originalAlarmEnabled = event.alarmEnabled;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Event'
        : _titleController.text.trim();
    final now = DateTime.now();

    if (widget.eventId != null) {
      await database.updateTimetableEvent(
        TimetableEventsCompanion(
          id: drift.Value(widget.eventId!),
          title: drift.Value(title),
          description: drift.Value(_descriptionController.text),
          dayOfWeek: drift.Value(widget.dayOfWeek),
          startTime: drift.Value(
            DateTime(
              now.year,
              now.month,
              now.day,
              _startTime.hour,
              _startTime.minute,
            ),
          ),
          endTime: drift.Value(
            DateTime(
              now.year,
              now.month,
              now.day,
              _endTime.hour,
              _endTime.minute,
            ),
          ),
          color: drift.Value(_selectedColor),
          alarmEnabled: drift.Value(_alarmEnabled),
        ),
      );
      if (_alarmEnabled) {
        await notificationService.scheduleTimetableAlarm(
          eventId: widget.eventId!,
          title: title,
          description: _descriptionController.text,
          dayOfWeek: widget.dayOfWeek,
          startTime: _startTime,
        );
      } else {
        await notificationService.cancelTimetableAlarm(widget.eventId!);
      }
    } else {
      final newId = await database.createTimetableEvent(
        TimetableEventsCompanion.insert(
          title: title,
          description: drift.Value(_descriptionController.text),
          dayOfWeek: widget.dayOfWeek,
          startTime: DateTime(
            now.year,
            now.month,
            now.day,
            _startTime.hour,
            _startTime.minute,
          ),
          endTime: DateTime(
            now.year,
            now.month,
            now.day,
            _endTime.hour,
            _endTime.minute,
          ),
          color: drift.Value(_selectedColor),
          alarmEnabled: drift.Value(_alarmEnabled),
          createdAt: DateTime.now(),
        ),
      );
      if (_alarmEnabled) {
        await notificationService.scheduleTimetableAlarm(
          eventId: newId,
          title: title,
          description: _descriptionController.text,
          dayOfWeek: widget.dayOfWeek,
          startTime: _startTime,
        );
      }
    }
  }

  bool get _hasChanges {
    if (_titleController.text.trim() != _originalTitle) return true;
    if (_descriptionController.text.trim() != _originalDescription) return true;
    if (_startTime?.hour != _originalStartTime?.hour ||
        _startTime?.minute != _originalStartTime?.minute)
      return true;
    if (_endTime?.hour != _originalEndTime?.hour ||
        _endTime?.minute != _originalEndTime?.minute)
      return true;
    if (_selectedColor != _originalSelectedColor) return true;
    if (_alarmEnabled != _originalAlarmEnabled) return true;
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
            widget.eventId != null ? l10n.timetable : l10n.newEvent,
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
                      // Day indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dayNames[widget.dayOfWeek - 1],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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

                      // Time Section
                      Text(
                        'Time',
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
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.access_time_filled),
                              title: Text(
                                '${l10n.end}: ${_endTime.format(context)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _endTime,
                                );
                                if (t != null) setState(() => _endTime = t);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.alarm_rounded),
                        title: const Text('Alarm'),
                        subtitle: const Text(
                          'Notify me 10 minutes before this class',
                        ),
                        value: _alarmEnabled,
                        onChanged: (value) =>
                            setState(() => _alarmEnabled = value),
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
