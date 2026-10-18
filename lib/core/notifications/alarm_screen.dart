import 'dart:async';
import 'dart:math' as math;

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen alarm display shown when an alarm fires.
/// Shows entity type, title, animated alarm icon, snooze & dismiss buttons.
/// Works even when the app is in the background or killed.
class AlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Parse payload to determine entity type and title
  String get _entityType => _parsePayloadPart(0);

  String _parsePayloadPart(int index) {
    final payload = widget.alarmSettings.payload ?? '';
    final parts = payload.split(':');
    return index < parts.length ? parts[index] : '';
  }

  IconData get _entityIcon {
    switch (_entityType) {
      case 'task':
        return Icons.task_alt_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'calendar':
        return Icons.event_rounded;
      case 'timetable':
        return Icons.school_rounded;
      default:
        return Icons.alarm_rounded;
    }
  }

  Color get _entityColor {
    switch (_entityType) {
      case 'task':
        return const Color(0xFF6366F1);
      case 'reminder':
        return const Color(0xFFF59E0B);
      case 'calendar':
        return const Color(0xFF10B981);
      case 'timetable':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _entityLabel {
    switch (_entityType) {
      case 'task':
        return 'Task Due';
      case 'reminder':
        return 'Reminder';
      case 'calendar':
        return 'Calendar Event';
      case 'timetable':
        return 'Class Starting';
      default:
        return 'Alarm';
    }
  }

  String get _title {
    return widget.alarmSettings.notificationSettings.title;
  }

  String get _body {
    return widget.alarmSettings.notificationSettings.body;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Pulse animation for alarm icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Elapsed timer to show how long the alarm has been ringing
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _elapsedTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String get _elapsedText {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _snooze() async {
    // Stop current alarm
    await Alarm.stop(widget.alarmSettings.id);
    // Re-set alarm 5 minutes from now
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: widget.alarmSettings.id,
        dateTime: DateTime.now().add(const Duration(minutes: 5)),
        assetAudioPath: widget.alarmSettings.assetAudioPath,
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        androidStopAlarmOnTermination: false,
        warningNotificationOnKill: false,
        androidSnoozeDuration: const Duration(minutes: 5),
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 3),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: widget.alarmSettings.notificationSettings.title,
          body: 'Snoozed — ringing again in 5 minutes',
          stopButton: 'Stop',
          androidSnoozeButton: 'Snooze 5 min',
          androidStopAlarmOnDismiss: false,
        ),
        payload: widget.alarmSettings.payload,
      ),
    );
    debugPrint('[AlarmScreen] Alarm snoozed for 5 minutes: ${widget.alarmSettings.id}');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _dismiss() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Prevent back button — user must use dismiss
        if (!didPop) _dismiss();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _entityColor.withValues(alpha: 0.15),
                  const Color(0xFF0F0F1A),
                  _entityColor.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Elapsed time
                Text(
                  _elapsedText,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 16),

                // Entity type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _entityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _entityColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_entityIcon, size: 14, color: _entityColor),
                      const SizedBox(width: 6),
                      Text(
                        _entityLabel,
                        style: TextStyle(
                          color: _entityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Animated alarm icon
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseAnimation,
                    _rotateAnimation,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: math.sin(_rotateAnimation.value) * 0.1,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _entityColor.withValues(alpha: 0.3),
                                _entityColor.withValues(alpha: 0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _entityColor.withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.alarm_rounded,
                            size: 80,
                            color: _entityColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 1),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 12),

                // Body / description
                if (_body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      _body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const Spacer(flex: 2),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      // Snooze button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.snooze_rounded,
                          label: 'Snooze',
                          subtitle: '5 min',
                          color: Colors.amber,
                          onTap: _snooze,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Dismiss button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.stop_circle_rounded,
                          label: 'Dismiss',
                          subtitle: 'Stop alarm',
                          color: const Color(0xFFEF4444),
                          onTap: _dismiss,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
