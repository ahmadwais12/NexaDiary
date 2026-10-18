import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../database/app_database.dart';
import 'notification_service.dart';

/// Checks for expired items and updates their status.
/// Also ensures alarms are scheduled for upcoming items.
class ExpiryChecker {
  final AppDatabase _database;
  final NotificationService _notificationService;
  Timer? _periodicTimer;

  ExpiryChecker({
    required AppDatabase database,
    required NotificationService notificationService,
  }) : _database = database,
       _notificationService = notificationService;

  /// Start checking expiry every 60 seconds.
  void startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkExpiredItems();
    });
  }

  /// Stop the periodic checker.
  void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Check all items and update expired statuses.
  /// Also re-schedule alarms for upcoming items.
  Future<void> checkExpiredItems() async {
    await _checkExpiredTasks();
    await _checkExpiredReminders();
    await _checkExpiredCalendarEvents();
    await _rescheduleUpcomingAlarms();
  }

  /// Mark tasks as 'expired' if their due date/time has passed
  /// and they are still 'pending'.
  Future<void> _checkExpiredTasks() async {
    try {
      final allTasks = await _database.getAllTasks();
      final now = DateTime.now();

      for (final task in allTasks) {
        if (task.status != 'pending' || !task.alarmEnabled) continue;
        if (task.dueTime == null && task.dueDate == null) continue;

        // Determine the effective due datetime
        DateTime? effectiveDue;
        if (task.dueTime != null) {
          effectiveDue = task.dueTime;
        } else if (task.dueDate != null) {
          // Use end of day for date-only tasks
          effectiveDue = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
            23,
            59,
          );
        }

        if (effectiveDue != null && effectiveDue.isBefore(now)) {
          await _database.updateTask(
            TasksCompanion(id: Value(task.id), status: const Value('expired')),
          );
          debugPrint(
            '[ExpiryChecker] Task expired: ${task.title} (id: ${task.id})',
          );
        }
      }
    } catch (e) {
      debugPrint('[ExpiryChecker] Error checking expired tasks: $e');
    }
  }

  /// Mark reminders as inactive if their reminder time has passed
  /// and they are not recurring.
  Future<void> _checkExpiredReminders() async {
    try {
      final allReminders = await _database.getAllReminders();
      final now = DateTime.now();

      for (final reminder in allReminders) {
        if (!reminder.isActive || !reminder.alarmEnabled) continue;
        // Only auto-deactivate non-recurring reminders
        if (reminder.repeatRule != null && reminder.repeatRule!.isNotEmpty)
          continue;

        if (reminder.reminderTime.isBefore(now)) {
          await _database.updateReminder(
            RemindersCompanion(
              id: Value(reminder.id),
              isActive: const Value(false),
            ),
          );
          debugPrint(
            '[ExpiryChecker] Reminder expired: ${reminder.title} (id: ${reminder.id})',
          );
        }
      }
    } catch (e) {
      debugPrint('[ExpiryChecker] Error checking expired reminders: $e');
    }
  }

  /// Calendar events don't have an active/inactive field, but we can
  /// cancel their alarms after they've passed.
  Future<void> _checkExpiredCalendarEvents() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Get yesterday's events and cancel their alarms (they're past)
      final yesterdayEvents = await _database.getEventsForDate(yesterday);
      for (final event in yesterdayEvents) {
        await _notificationService.cancelCalendarAlarm(event.id);
      }
    } catch (e) {
      debugPrint('[ExpiryChecker] Error checking expired calendar events: $e');
    }
  }

  /// Re-schedule alarms for all upcoming items.
  /// This ensures alarms survive app restarts.
  Future<void> _rescheduleUpcomingAlarms() async {
    try {
      final now = DateTime.now();

      // Re-schedule task alarms for pending tasks with future due dates
      final allTasks = await _database.getAllTasks();
      for (final task in allTasks) {
        if (task.status != 'pending') continue;
        final dueDt = task.dueTime ?? task.dueDate;
        if (dueDt == null || dueDt.isBefore(now)) continue;
        await _notificationService.scheduleTaskAlarm(
          taskId: task.id,
          title: task.title,
          description: task.description,
          dueDateTime: dueDt,
        );
      }

      // Re-schedule reminder alarms
      final allReminders = await _database.getAllReminders();
      for (final reminder in allReminders) {
        if (!reminder.isActive) continue;
        if (reminder.reminderTime.isBefore(now) &&
            (reminder.repeatRule == null || reminder.repeatRule!.isEmpty))
          continue;
        await _notificationService.scheduleReminderAlarm(
          reminderId: reminder.id,
          title: reminder.title,
          description: reminder.description,
          reminderDateTime: reminder.reminderTime,
          repeatRule: reminder.repeatRule,
        );
      }

      // Re-schedule enabled weekly timetable alarms.
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        final events = await _database.getTimetableForDay(day);
        for (final event in events) {
          if (!event.isActive || !event.alarmEnabled) continue;
          await _notificationService.scheduleTimetableAlarm(
            eventId: event.id,
            title: event.title,
            description: event.description,
            dayOfWeek: event.dayOfWeek,
            startTime: TimeOfDay.fromDateTime(event.startTime),
          );
        }
      }
    } catch (e) {
      debugPrint('[ExpiryChecker] Error rescheduling alarms: $e');
    }
  }

  void dispose() {
    stopPeriodicCheck();
  }
}
