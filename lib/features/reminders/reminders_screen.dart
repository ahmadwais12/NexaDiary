import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/app_theme.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reminders,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(l10n.all)),
              PopupMenuItem(value: 'active', child: Text(l10n.active)),
              PopupMenuItem(value: 'inactive', child: Text(l10n.inactive)),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            child: Row(
              children: [
                _buildFilterChip(l10n.all, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Expired', 'expired'),
                const SizedBox(width: 8),
                _buildFilterChip('Inactive', 'inactive'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: database.watchAllReminders(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];

          final now = DateTime.now();
          List<Reminder> filtered = reminders;
          if (_filterStatus == 'active') {
            filtered = reminders.where((r) => r.isActive && r.reminderTime.isAfter(now)).toList();
          } else if (_filterStatus == 'expired') {
            filtered = reminders.where((r) => r.reminderTime.isBefore(now) && !r.isActive).toList();
          } else if (_filterStatus == 'inactive') {
            filtered = reminders.where((r) => !r.isActive && r.reminderTime.isAfter(now)).toList();
          }

          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where(
                  (r) =>
                      r.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      r.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }

          if (filtered.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isNotEmpty
                  ? 'No reminders found'
                  : l10n.noReminders,
              _searchQuery.isNotEmpty
                  ? 'Try a different search'
                  : 'Tap + to create a reminder',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final r = filtered[index];
              final bgColor = parseColor(r.color) ?? AppTheme.primaryColor;
              final isExpired = r.reminderTime.isBefore(DateTime.now());
              return Card(
                color: isExpired ? Colors.red.withValues(alpha: 0.06) : bgColor.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isExpired ? Colors.red.withValues(alpha: 0.25) : bgColor.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => context.push('/reminder/${r.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        // Left: icon pill with status dot
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: r.isActive
                                ? bgColor.withValues(alpha: 0.18)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Icon(
                                  isExpired ? Icons.timer_off_rounded : (r.isActive ? Icons.alarm_rounded : Icons.alarm_off_rounded),
                                  size: 22,
                                  color: isExpired ? Colors.red.shade400 : (r.isActive ? bgColor : Colors.grey),
                                ),
                              ),
                              if (r.isActive)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Middle: content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                r.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isExpired ? Colors.red.shade400 : (r.isActive ? null : Colors.grey),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (r.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  r.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.event_rounded, size: 13, color: isExpired ? Colors.red.shade400 : bgColor),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      DateFormat('MMM d, yyyy').format(r.reminderTime),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isExpired ? Colors.red.shade400 : Colors.grey.shade500),
                                    ),
                                  ),
                                  if (isExpired) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Expired',
                                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 10),
                                  Icon(Icons.schedule_rounded, size: 13, color: isExpired ? Colors.red.shade400 : bgColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('hh:mm a').format(r.reminderTime),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isExpired ? Colors.red.shade400 : Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right: quick toggle + menu
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: r.isActive,
                            activeThumbColor: bgColor,
                            onChanged: (v) async {
                              await database.updateReminder(
                                RemindersCompanion(
                                  id: drift.Value(r.id),
                                  isActive: drift.Value(v),
                                ),
                              );
                            },
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              context.push('/reminder/${r.id}');
                            } else if (action == 'toggle') {
                              await database.updateReminder(
                                RemindersCompanion(
                                  id: drift.Value(r.id),
                                  isActive: drift.Value(!r.isActive),
                                ),
                              );
                            } else if (action == 'delete') {
                              _confirmDeleteReminder(r);
                            }
                          },
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 26,
                            color: Colors.grey.shade600,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: const [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(r.isActive ? Icons.pause : Icons.play_arrow, size: 20),
                                  const SizedBox(width: 12),
                                  Text(r.isActive ? 'Disable' : 'Enable'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_reminders_fab',
        onPressed: () => context.push('/reminder/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
      ),
    );
  }

  void _confirmDeleteReminder(Reminder r) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete Reminder?',
      itemName: r.title,
      description: 'This reminder will be permanently deleted and cannot be recovered.',
    );
    if (confirmed) {
      await notificationService.cancelReminderAlarm(r.id);
      await database.deleteReminder(r.id);
    }
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == value,
      onSelected: (_) => setState(() => _filterStatus = value),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showSearch() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchReminders,
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Reminder>>(
                  stream: database.watchAllReminders(),
                  builder: (context, snapshot) {
                    final reminders = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? reminders
                        : reminders
                              .where(
                                (r) =>
                                    r.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    r.description.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: Icon(
                          filtered[index].isActive
                              ? Icons.alarm
                              : Icons.alarm_off,
                          size: 28,
                          color: filtered[index].isActive
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                        titleAlignment: ListTileTitleAlignment.center,
                        title: Text(
                          filtered[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, hh:mm a').format(
                            filtered[index].reminderTime,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
