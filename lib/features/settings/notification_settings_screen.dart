import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPendingNotifications();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await notificationService.getPendingNotifications();
      if (mounted) setState(() => _pendingNotifications = pending);
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);

    if (status.isGranted) {
      // Schedule test notification to confirm it works
      await notificationService.showNotification(
        title: 'NexaDiary',
        body: 'Notifications are now enabled! You\'ll receive reminders for your tasks and events.',
      );
      _loadPendingNotifications();
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    final settings = context.read<SettingsState>();

    if (enable) {
      if (!_hasPermission) {
        await _requestPermission();
        if (!_hasPermission) return; // User denied
      }
      await settings.setNotificationsEnabled(true);
    } else {
      await settings.setNotificationsEnabled(false);
      // Cancel all scheduled notifications when disabled
      await notificationService.cancelAllNotifications();
      _loadPendingNotifications();
    }
  }

  Future<void> _testNotification() async {
    final settings = context.read<SettingsState>();
    if (!settings.notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) return;
    }

    // Schedule a test notification in 5 seconds
    await notificationService.scheduleNotification(
      title: 'Test Notification 🔔',
      body: 'This is a test notification from NexaDiary. Sound: ${settings.notificationSound}',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      androidChannelId: 'test_channel',
    );

    _loadPendingNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification scheduled for 5 seconds from now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Send Test Notification',
            onPressed: _testNotification,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                final r = ResponsiveUtils(context);
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // === PERMISSION STATUS ===
                        if (!_hasPermission)
                          _buildPermissionBanner(context, settings),

                        // === NOTIFICATIONS TOGGLE ===
                        _buildSectionHeader(l10n.notifications, theme),
                        _buildSettingsCard(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.notifications_active_rounded,
                              iconColor: Colors.amber,
                              title: l10n.notifications,
                              subtitle: _hasPermission
                                  ? 'Notifications are active'
                                  : 'Tap to enable and grant permission',
                              value: settings.notificationsEnabled,
                              onChanged: (value) => _toggleNotifications(value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // === NOTIFICATION TYPES ===
                        _buildSectionHeader('Notification Types', theme),
                        _buildSettingsCard(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.alarm_rounded,
                              iconColor: Colors.orange,
                              title: 'Task Reminders',
                              subtitle: 'Get notified about upcoming tasks',
                              value: settings.notificationsEnabled,
                              onChanged: (value) =>
                                  settings.setNotificationsEnabled(value),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSwitchTile(
                              icon: Icons.event_rounded,
                              iconColor: Colors.blue,
                              title: 'Calendar Events',
                              subtitle: 'Reminders for calendar events',
                              value: settings.notificationsEnabled,
                              onChanged: (value) =>
                                  settings.setNotificationsEnabled(value),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSwitchTile(
                              icon: Icons.schedule_rounded,
                              iconColor: Colors.green,
                              title: 'Timetable Alerts',
                              subtitle: 'Alerts before scheduled classes',
                              value: settings.notificationsEnabled,
                              onChanged: (value) =>
                                  settings.setNotificationsEnabled(value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // === SOUND & VIBRATION ===
                        _buildSectionHeader('Sound & Vibration', theme),
                        _buildSettingsCard(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.music_note_rounded,
                              iconColor: Colors.deepOrange,
                              title: l10n.notificationSound,
                              subtitle: _getSoundName(
                                  settings.notificationSound, l10n),
                              onTap: () => _showSoundSheet(
                                  context, settings, l10n),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildSwitchTile(
                              icon: Icons.vibration_rounded,
                              iconColor: Colors.pink,
                              title: l10n.vibration,
                              subtitle: l10n.vibrationDescription,
                              value: settings.vibrationEnabled,
                              onChanged: (value) =>
                                  settings.setVibrationEnabled(value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // === PENDING NOTIFICATIONS ===
                        _buildSectionHeader('Scheduled Notifications', theme),
                        _buildPendingNotificationsCard(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, SettingsState settings) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Permission Required',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allow notifications to receive reminders for tasks, events, and more.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.08),
      child: _pendingNotifications.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No scheduled notifications',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                ..._pendingNotifications.take(5).map((notif) {
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Colors.blue, size: 18),
                    ),
                    title: Text(
                      notif.title ?? 'Notification',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      notif.body ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () async {
                        await notificationService.cancelNotification(notif.id);
                        _loadPendingNotifications();
                      },
                    ),
                  );
                }),
                if (_pendingNotifications.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '+${_pendingNotifications.length - 5} more',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                if (_pendingNotifications.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded,
                        color: Colors.red, size: 20),
                    title: const Text(
                      'Cancel All',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await notificationService.cancelAllNotifications();
                      _loadPendingNotifications();
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.08),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          size: 20, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  String _getSoundName(String sound, AppLocalizations l10n) {
    switch (sound) {
      case 'default':
        return l10n.defaultSound;
      case 'bell':
        return 'Bell 🔔';
      case 'chime':
        return 'Chime 🎵';
      case 'gentle':
        return 'Gentle 🌸';
      default:
        return l10n.defaultSound;
    }
  }

  void _showSoundSheet(
      BuildContext context, SettingsState settings, AppLocalizations l10n) {
    final sounds = ['default', 'bell', 'chime', 'gentle'];
    final soundLabels = {
      'default': l10n.defaultSound,
      'bell': 'Bell 🔔',
      'chime': 'Chime 🎵',
      'gentle': 'Gentle 🌸',
    };
    final soundDescs = {
      'default': 'System default notification sound',
      'bell': 'Classic bell sound for attention',
      'chime': 'Soft chime for gentle reminders',
      'gentle': 'Calm melody for quiet notifications',
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.notificationSound,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the notification sound',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...sounds.map((sound) {
                final isSelected = settings.notificationSound == sound;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          sound == 'default'
                              ? Icons.notifications_rounded
                              : sound == 'bell'
                                  ? Icons.notifications_active_rounded
                                  : sound == 'chime'
                                      ? Icons.music_note_rounded
                                      : Icons.volume_down_rounded,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                        soundLabels[sound]!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        soundDescs[sound]!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary)
                          : Icon(Icons.radio_button_unchecked,
                              color: Colors.grey.shade400),
                      onTap: () {
                        settings.setNotificationSound(sound);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
