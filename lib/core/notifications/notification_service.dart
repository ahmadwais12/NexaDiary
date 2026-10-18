import 'dart:async';
import 'dart:io' show Platform;

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification channel IDs for different entity types.
class NotificationChannels {
  static const String tasks = 'tasks_alarms';
  static const String reminders = 'reminders_alarms';
  static const String calendar = 'calendar_alarms';
  static const String timetable = 'timetable_alarms';
  static const String general = 'general_channel';
}

/// Handles local notifications and real alarms for reminders, tasks,
/// calendar events, and timetable events — works even when the app is closed.
///
/// Uses `alarm` package for real alarm sounds + full-screen display,
/// and `flutter_local_notifications` for pre-alarm reminder notifications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactAlarmsPermitted = false;
  StreamSubscription? _ringingSubscription;
  Function(AlarmSettings)? onAlarmRinging; // Called when alarm fires

  /// Notification ID prefixes per entity type (deterministic IDs).
  static const int _taskPrefix = 1;
  static const int _reminderPrefix = 2;
  static const int _calendarPrefix = 3;
  static const int _timetablePrefix = 4;
  /// Real alarm ID offset (separate from notification IDs).
  static const int _realAlarmOffset = 700000000;

  /// Initialize the notification system, alarm package, and all channels.
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
    } catch (e) {
      debugPrint(
        '[NotificationService] Could not determine local timezone: $e',
      );
    }

    // ── Initialize flutter_local_notifications ──
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
    await _checkExactAlarmPermission();

    // ── Initialize alarm package ──
    try {
      await Alarm.init();
      debugPrint('[NotificationService] Alarm package initialized');
    } catch (e) {
      debugPrint('[NotificationService] Alarm init failed: $e');
    }

    // Listen for alarms ringing.
    // Uses ringStream because AlarmSet isn't publicly exported.
    _ringingSubscription?.cancel();
    _ringingSubscription = Alarm.ringStream.stream.listen((alarm) {
      debugPrint('[NotificationService] Alarm ringing: ${alarm.id}');
      onAlarmRinging?.call(alarm);
    });

    _initialized = true;
    debugPrint('[NotificationService] Fully initialized (notifications + alarm)');
  }

  /// Stop listening to alarm ringings.
  void dispose() {
    _ringingSubscription?.cancel();
    _ringingSubscription = null;
  }

  // ──────────────────────────────────────────────
  //  Exact alarm permission
  // ──────────────────────────────────────────────

  Future<void> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      _exactAlarmsPermitted = true;
      return;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      _exactAlarmsPermitted = false;
      return;
    }

    try {
      await android.areNotificationsEnabled();

      final exactStatus = await Permission.scheduleExactAlarm.status;
      if (exactStatus.isGranted) {
        _exactAlarmsPermitted = true;
        debugPrint('[NotificationService] Exact alarms: GRANTED');
      } else if (exactStatus.isPermanentlyDenied) {
        _exactAlarmsPermitted = false;
        debugPrint('[NotificationService] Exact alarms: DENIED — using inexact');
      } else {
        final reqStatus = await Permission.scheduleExactAlarm.request();
        _exactAlarmsPermitted = reqStatus.isGranted;
        debugPrint('[NotificationService] Exact alarm request: $reqStatus');
      }
    } catch (e) {
      _exactAlarmsPermitted = false;
      debugPrint('[NotificationService] Exact alarm check error: $e');
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.request();
      _exactAlarmsPermitted = status.isGranted;
      return _exactAlarmsPermitted;
    } catch (e) {
      debugPrint('[NotificationService] Failed to request exact alarm: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  //  Notification channels
  // ──────────────────────────────────────────────

  Future<void> _createNotificationChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    for (final chId in [
      NotificationChannels.tasks,
      NotificationChannels.reminders,
      NotificationChannels.calendar,
      NotificationChannels.timetable,
      NotificationChannels.general,
    ]) {
      try {
        await android.deleteNotificationChannel(channelId: chId);
      } catch (_) {}
    }

    final channels = [
      AndroidNotificationChannel(
        NotificationChannels.tasks,
        'Task Alarms',
        description: 'Alarms for task due dates',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        NotificationChannels.reminders,
        'Reminder Alarms',
        description: 'Alarms for your reminders',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        NotificationChannels.calendar,
        'Calendar Alarms',
        description: 'Alarms for calendar events',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        NotificationChannels.timetable,
        'Timetable Alarms',
        description: 'Alarms for timetable classes',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        NotificationChannels.general,
        'General',
        description: 'General notifications',
        importance: Importance.high,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('[NotificationService] Notification tapped: $payload');
    }
  }

  // ──────────────────────────────────────────────
  //  Deterministic IDs
  // ──────────────────────────────────────────────

  int _entityNotificationId(String entityType, int entityId) {
    switch (entityType) {
      case 'task':
        return _taskPrefix * 100000 + entityId;
      case 'reminder':
        return _reminderPrefix * 100000 + entityId;
      case 'calendar':
        return _calendarPrefix * 100000 + entityId;
      case 'timetable':
        return _timetablePrefix * 100000 + entityId;
      default:
        return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  int _realAlarmId(String entityType, int entityId) =>
      _realAlarmOffset + _entityNotificationId(entityType, entityId);

  // ──────────────────────────────────────────────
  //  Real alarm (alarm package)
  // ──────────────────────────────────────────────

  /// Schedule a real alarm using the `alarm` package.
  /// This works even when the app is killed — shows full-screen alarm UI
  /// with device default alarm sound, vibration, and snooze/dismiss buttons.
  Future<void> _setRealAlarm({
    required String entityType,
    required int entityId,
    required String title,
    required String body,
    required DateTime dateTime,
    String? repeatRule,
  }) async {
    if (!dateTime.isAfter(DateTime.now())) return;

    final id = _realAlarmId(entityType, entityId);
    final payload = '$entityType:$entityId:${repeatRule ?? ''}';

    try {
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: id,
          dateTime: dateTime,
          // null assetAudioPath = device default alarm sound
          assetAudioPath: null,
          loopAudio: true,
          vibrate: true,
          androidFullScreenIntent: true,
          androidStopAlarmOnTermination: false,
          warningNotificationOnKill: Platform.isIOS,
          androidSnoozeDuration: const Duration(minutes: 5),
          volumeSettings: VolumeSettings.fade(
            volume: 1.0,
            fadeDuration: const Duration(seconds: 3),
            volumeEnforced: true,
          ),
          notificationSettings: NotificationSettings(
            title: title,
            body: body,
            stopButton: 'Stop',
            androidSnoozeButton: 'Snooze 5 min',
            androidStopAlarmOnDismiss: false,
          ),
          payload: payload,
        ),
      );
      debugPrint('[NotificationService] Real alarm set: $id at $dateTime');
    } catch (e) {
      debugPrint('[NotificationService] Failed to set real alarm: $e');
    }
  }

  /// Cancel a real alarm.
  Future<void> _stopRealAlarm(String entityType, int entityId) async {
    final id = _realAlarmId(entityType, entityId);
    try {
      await Alarm.stop(id);
      debugPrint('[NotificationService] Real alarm stopped: $id');
    } catch (e) {
      debugPrint('[NotificationService] Failed to stop real alarm: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  Safe local notification scheduling
  // ──────────────────────────────────────────────

  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails details,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    if (_exactAlarmsPermitted) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDateTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint('[NotificationService] Exact notification scheduled: $id');
        return;
      } on PlatformException catch (e) {
        debugPrint('[NotificationService] Exact failed ($e), using inexact');
      }
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint('[NotificationService] Inexact notification scheduled: $id');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule notification: $e');
    }
  }

  // ──────────────────────────────────────────────
  //  Permission requests
  // ──────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) return true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ──────────────────────────────────────────────
  //  Task alarms
  // ──────────────────────────────────────────────

  Future<int> scheduleTaskAlarm({
    required int taskId,
    required String title,
    required String description,
    required DateTime dueDateTime,
    int reminderMinutesBefore = 0,
  }) async {
    final scheduledTime = dueDateTime.subtract(
      Duration(minutes: reminderMinutesBefore),
    );
    if (scheduledTime.isBefore(DateTime.now())) return -1;

    final id = _entityNotificationId('task', taskId);
    final body = reminderMinutesBefore > 0
        ? 'Due in $reminderMinutesBefore minutes — $description'
        : description.isEmpty
        ? 'Task is due now'
        : description;

    // Schedule local notification (pre-alarm reminder)
    await _safeZonedSchedule(
      id: id,
      title: '📋 Task: $title',
      body: body,
      scheduledDate: scheduledTime,
      details: _alarmDetails(NotificationChannels.tasks, 'task:$taskId'),
      payload: 'task:$taskId',
    );

    // Schedule real alarm (alarm package) — fires at exact due time with sound
    await _setRealAlarm(
      entityType: 'task',
      entityId: taskId,
      title: '📋 Task: $title',
      body: description.isEmpty ? 'Task is due now' : description,
      dateTime: dueDateTime,
    );

    debugPrint(
      '[NotificationService] Task alarm scheduled: $id for $scheduledTime',
    );
    return id;
  }

  Future<void> cancelTaskAlarm(int taskId) async {
    final id = _entityNotificationId('task', taskId);
    await _plugin.cancel(id: id);
    await _stopRealAlarm('task', taskId);
    debugPrint('[NotificationService] Task alarm cancelled: $id');
  }

  // ──────────────────────────────────────────────
  //  Reminder alarms
  // ──────────────────────────────────────────────

  Future<int> scheduleReminderAlarm({
    required int reminderId,
    required String title,
    required String description,
    required DateTime reminderDateTime,
    String? repeatRule,
  }) async {
    if (reminderDateTime.isBefore(DateTime.now()) &&
        (repeatRule == null || repeatRule.isEmpty)) {
      return -1;
    }

    final id = _entityNotificationId('reminder', reminderId);
    final body = description.isEmpty ? 'Time for your reminder!' : description;

    if (repeatRule != null && repeatRule.isNotEmpty) {
      return await _scheduleRecurringReminder(
        id: id,
        reminderId: reminderId,
        title: title,
        body: body,
        firstTime: reminderDateTime,
        repeatRule: repeatRule,
        payload: 'reminder:$reminderId',
      );
    }

    // Local notification
    await _safeZonedSchedule(
      id: id,
      title: '🔔 Reminder: $title',
      body: body,
      scheduledDate: reminderDateTime,
      details: _alarmDetails(
        NotificationChannels.reminders,
        'reminder:$reminderId',
      ),
      payload: 'reminder:$reminderId',
    );

    // Real alarm
    await _setRealAlarm(
      entityType: 'reminder',
      entityId: reminderId,
      title: '🔔 Reminder: $title',
      body: body,
      dateTime: reminderDateTime,
      repeatRule: repeatRule,
    );

    debugPrint(
      '[NotificationService] Reminder alarm scheduled: $id for $reminderDateTime',
    );
    return id;
  }

  Future<int> _scheduleRecurringReminder({
    required int id,
    required int reminderId,
    required String title,
    required String body,
    required DateTime firstTime,
    required String repeatRule,
    required String payload,
  }) async {
    final isWeekly = repeatRule == 'weekly';
    final scheduledTime = isWeekly
        ? _nextWeekdayDateTime(
            DateTime.now(),
            firstTime.weekday,
            TimeOfDay.fromDateTime(firstTime),
          )
        : _nextDailyDateTime(firstTime);

    try {
      await _safeZonedSchedule(
        id: id,
        title: '🔔 Reminder: $title',
        body: body,
        scheduledDate: scheduledTime,
        details: _alarmDetails(NotificationChannels.reminders, payload),
        payload: payload,
        matchDateTimeComponents: isWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : DateTimeComponents.time,
      );
      debugPrint(
        '[NotificationService] Recurring reminder notification scheduled: $id',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to schedule recurring reminder: $e',
      );
    }

    // Real alarm for recurring reminder — set next occurrence
    await _setRealAlarm(
      entityType: 'reminder',
      entityId: reminderId,
      title: '🔔 Reminder: $title',
      body: body,
      dateTime: scheduledTime,
      repeatRule: repeatRule,
    );

    return id;
  }

  Future<void> cancelReminderAlarm(int reminderId) async {
    final id = _entityNotificationId('reminder', reminderId);
    await _plugin.cancel(id: id);
    await _stopRealAlarm('reminder', reminderId);
    debugPrint('[NotificationService] Reminder alarm cancelled: $id');
  }

  // ──────────────────────────────────────────────
  //  Calendar event alarms
  // ──────────────────────────────────────────────

  Future<int> scheduleCalendarAlarm({
    required int eventId,
    required String title,
    required String description,
    required DateTime eventStartDateTime,
    int reminderMinutesBefore = 15,
  }) async {
    final scheduledTime = eventStartDateTime.subtract(
      Duration(minutes: reminderMinutesBefore),
    );
    if (scheduledTime.isBefore(DateTime.now())) return -1;

    final id = _entityNotificationId('calendar', eventId);
    final timeLabel =
        reminderMinutesBefore > 0 ? ' in $reminderMinutesBefore minutes' : '';
    final body = description.isEmpty
        ? 'Event starts$timeLabel'
        : '$description — starts$timeLabel';

    // Local notification (pre-alarm)
    await _safeZonedSchedule(
      id: id,
      title: '📅 Event: $title',
      body: body,
      scheduledDate: scheduledTime,
      details: _alarmDetails(
        NotificationChannels.calendar,
        'calendar:$eventId',
      ),
      payload: 'calendar:$eventId',
    );

    // Real alarm at event start time
    await _setRealAlarm(
      entityType: 'calendar',
      entityId: eventId,
      title: '📅 Event: $title',
      body: description.isEmpty ? 'Event is starting now' : description,
      dateTime: eventStartDateTime,
    );

    debugPrint(
      '[NotificationService] Calendar alarm scheduled: $id for $scheduledTime',
    );
    return id;
  }

  Future<void> cancelCalendarAlarm(int eventId) async {
    final id = _entityNotificationId('calendar', eventId);
    await _plugin.cancel(id: id);
    await _stopRealAlarm('calendar', eventId);
    debugPrint('[NotificationService] Calendar alarm cancelled: $id');
  }

  // ──────────────────────────────────────────────
  //  Timetable event alarms
  // ──────────────────────────────────────────────

  Future<int> scheduleTimetableAlarm({
    required int eventId,
    required String title,
    required String description,
    required int dayOfWeek,
    required TimeOfDay startTime,
    int reminderMinutesBefore = 10,
  }) async {
    final id = _entityNotificationId('timetable', eventId);

    final now = DateTime.now();
    var nextOccurrence = _nextWeekdayDateTime(now, dayOfWeek, startTime);
    var scheduledTime = nextOccurrence.subtract(
      Duration(minutes: reminderMinutesBefore),
    );
    if (scheduledTime.isBefore(DateTime.now())) {
      nextOccurrence = _nextWeekdayDateTime(
        now.add(const Duration(days: 7)),
        dayOfWeek,
        startTime,
      );
      scheduledTime = nextOccurrence.subtract(
        Duration(minutes: reminderMinutesBefore),
      );
    }

    final dayName = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][dayOfWeek - 1];
    final timeLabel =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final body = description.isEmpty
        ? '$dayName class starts at $timeLabel'
        : '$description — $dayName at $timeLabel';

    // Local notification (pre-alarm)
    try {
      await _safeZonedSchedule(
        id: id,
        title: '🏫 Class: $title',
        body: body,
        scheduledDate: scheduledTime,
        details: _alarmDetails(
          NotificationChannels.timetable,
          'timetable:$eventId',
        ),
        payload: 'timetable:$eventId',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint(
        '[NotificationService] Timetable notification scheduled: $id ($dayName)',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to schedule timetable notification: $e',
      );
    }

    // Real alarm — fires at class start time each week
    await _setRealAlarm(
      entityType: 'timetable',
      entityId: eventId,
      title: '🏫 Class: $title',
      body: body,
      dateTime: nextOccurrence,
      repeatRule: 'weekly',
    );

    return id;
  }

  Future<void> cancelTimetableAlarm(int eventId) async {
    final id = _entityNotificationId('timetable', eventId);
    await _plugin.cancel(id: id);
    await _stopRealAlarm('timetable', eventId);
    debugPrint('[NotificationService] Timetable alarm cancelled: $id');
  }

  // ──────────────────────────────────────────────
  //  Generic helpers
  // ──────────────────────────────────────────────

  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? androidChannelId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      details: _alarmDetails(
        androidChannelId ?? NotificationChannels.general,
        payload,
      ),
      payload: payload,
    );

    return id;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.general,
        'General',
        channelDescription: 'General notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  // ──────────────────────────────────────────────
  //  Private helpers
  // ──────────────────────────────────────────────

  NotificationDetails _alarmDetails(String channelId, String? payload) {
    final channelName = channelId
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final alarmSound = UriAndroidNotificationSound(
      'content://settings/system/alarm_alert',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: alarmSound,
      styleInformation: const BigTextStyleInformation(''),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  DateTime _nextWeekdayDateTime(
    DateTime from,
    int weekday,
    TimeOfDay timeOfDay,
  ) {
    final currentWeekday = from.weekday;
    var daysUntil = weekday - currentWeekday;
    if (daysUntil < 0 ||
        (daysUntil == 0 &&
            _timeOfDayToMinutes(timeOfDay) <=
                _timeOfDayToMinutes(TimeOfDay.fromDateTime(from)))) {
      daysUntil += 7;
    }
    final targetDate = from.add(Duration(days: daysUntil));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  DateTime _nextDailyDateTime(DateTime firstTime) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      firstTime.hour,
      firstTime.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  int _timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
}
