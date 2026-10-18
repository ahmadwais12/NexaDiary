import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsState>();
    final isRtl = settings.locale.languageCode == 'fa' || settings.locale.languageCode == 'ps';
    final r = ResponsiveUtils(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // === FIXED HEADER (profile-style: logo + name + subtitle) ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Row(
                children: isRtl ? [
                  // RTL: Name+subtitle on left, logo on right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NexaDiary',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.yourPrivateWorkspaceTagline,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildProfileAvatar(theme, r),
                ] : [
                  // LTR: Logo on left, name+subtitle on right
                  _buildProfileAvatar(theme, r),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NexaDiary',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.yourPrivateWorkspaceTagline,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // === SCROLLABLE CONTENT ===
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // ── PRODUCTIVITY ──
                  _buildSectionHeader(
                    icon: Icons.speed,
                    title: l10n.productivity,
                    color: Colors.blue,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.calendar_month_rounded,
                    title: l10n.calendar,
                    subtitle: l10n.calendarDescription,
                    route: '/calendar',
                    color: Colors.blue,
                  ),
                  _buildExchangeCalendarItem(context, l10n),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.schedule_rounded,
                    title: l10n.timetable,
                    subtitle: l10n.timetableDescription,
                    route: '/timetable',
                    color: Colors.green,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.alarm_rounded,
                    title: l10n.reminders,
                    subtitle: l10n.remindersDescription,
                    route: '/reminders',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // ── CONTENT ──
                  _buildSectionHeader(
                    icon: Icons.folder_open,
                    title: l10n.content,
                    color: Colors.purple,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.star_rounded,
                    title: l10n.favorites,
                    subtitle: l10n.favoritesDescription,
                    route: '/search',
                    color: Colors.amber,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.delete_outline_rounded,
                    title: l10n.trash,
                    subtitle: l10n.trashDescription,
                    route: '/trash',
                    color: Colors.red,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.lock_rounded,
                    title: l10n.privateVault,
                    subtitle: l10n.privateVaultDescription,
                    route: '/vault',
                    color: Colors.red,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.perm_media_rounded,
                    title: l10n.filesAndMedia,
                    subtitle: l10n.filesAndMediaDescription,
                    route: '/media',
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 24),

                  // ── TOOLS ──
                  _buildSectionHeader(
                    icon: Icons.handyman,
                    title: l10n.tools,
                    color: Colors.teal,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.backup_rounded,
                    title: l10n.backupAndRestore,
                    subtitle: l10n.backupAndRestoreDescription,
                    route: '/backup',
                    color: Colors.teal,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: l10n.statistics,
                    subtitle: l10n.statisticsDescription,
                    route: '/statistics',
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 24),

                  // ── SETTINGS ──
                  _buildSectionHeader(
                    icon: Icons.settings,
                    title: l10n.settings,
                    color: Colors.grey,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.palette_rounded,
                    title: l10n.appearance,
                    subtitle:
                        '${l10n.darkMode}, ${l10n.language}, ${l10n.fontFamily}',
                    route: '/settings/appearance',
                    color: Colors.deepOrange,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.storage_rounded,
                    title: l10n.data,
                    subtitle: '${l10n.storageUsage}, ${l10n.clearTrash}',
                    route: '/settings/data',
                    color: Colors.blueGrey,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.notifications_rounded,
                    title: l10n.notifications,
                    subtitle:
                        '${l10n.notificationsDescription}, ${l10n.vibration}',
                    route: '/settings/notifications',
                    color: Colors.amber,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.shield_rounded,
                    title: l10n.security,
                    subtitle:
                        '${l10n.appLock}, ${l10n.encryptBackups}',
                    route: '/settings/security',
                    color: Colors.deepPurple,
                  ),
                  _buildEnhancedMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: l10n.about,
                    subtitle:
                        '${l10n.version}, ${l10n.privacyPolicy}',
                    route: '/settings/about',
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Profile Avatar ===

  Widget _buildProfileAvatar(ThemeData theme, ResponsiveUtils r) {
    final size = r.isIpad ? 100.0 : (r.isTablet ? 90.0 : 80.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.isIpad ? 26 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.isIpad ? 26 : 20),
        child: Image.asset(
          'assets/logo/NexaDiary_mark.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // === Exchange Calendar Item ===

  Widget _buildExchangeCalendarItem(
      BuildContext context, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.swap_horiz_rounded, color: Colors.indigo, size: 22),
        ),
        title: Text(
          l10n.exchangeCalendar,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          l10n.exchangeCalendarDescription,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing:
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        onTap: () => _showExchangeCalendarDialog(context, l10n),
      ),
    );
  }

  void _showExchangeCalendarDialog(
      BuildContext context, AppLocalizations l10n) {
    final settings = context.read<SettingsState>();
    final currentType = settings.calendarType;

    final types = [
      {
        'key': 'gregorian',
        'label': l10n.gregorian,
        'icon': Icons.calendar_today_rounded,
        'desc': 'January - December'
      },
      {
        'key': 'hijri',
        'label': l10n.hijri,
        'icon': Icons.nightlight_round,
        'desc': 'Muharram - Dhul Hijjah'
      },
      {
        'key': 'shamsi',
        'label': l10n.shamsi,
        'icon': Icons.wb_sunny_rounded,
        'desc': 'Farvardin - Esfand'
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              final colorScheme = Theme.of(ctx).colorScheme;
              return Column(
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
                    l10n.calendarType,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.exchangeCalendarDescription,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ...types.map((t) {
                    final isSelected = currentType == t['key'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                    .withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            t['icon'] as IconData,
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          t['desc'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: colorScheme.primary)
                            : Icon(Icons.radio_button_unchecked,
                                color: Colors.grey.shade400),
                        onTap: () {
                          settings.setCalendarType(t['key'] as String);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // === Section Header with Icon ===

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // === Enhanced Menu Item with Subtitle ===

  Widget _buildEnhancedMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing:
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        onTap: () => context.push(route),
      ),
    );
  }
}
