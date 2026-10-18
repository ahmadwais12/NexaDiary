import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDay = DateTime.now().weekday;
  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.timetable,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          TextButton.icon(
            onPressed: () =>
                setState(() => _selectedDay = DateTime.now().weekday),
            icon: const Icon(Icons.today, size: 18),
            label: Text(l10n.today),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = day == _selectedDay;
                final isToday = day == DateTime.now().weekday;
                final theme = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : isToday
                                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                  : theme.colorScheme.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayNames[index].substring(0, 3),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : (isToday ? theme.colorScheme.primary : null),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday
                                  ? (isSelected ? Colors.white : theme.colorScheme.primary)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(child: _buildEventsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_timetable_fab',
        onPressed: () => context.push('/timetable-event/new?day=$_selectedDay'),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  void _confirmDeleteTimetableEvent(TimetableEvent event) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Delete Event?',
      itemName: event.title,
      description: 'This timetable event will be permanently deleted and cannot be recovered.',
    );
    if (confirmed) {
      await notificationService.cancelTimetableAlarm(event.id);
      await database.deleteTimetableEvent(event.id);
    }
  }

  Widget _buildEventsList() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<TimetableEvent>>(
      stream: database.watchTimetableForDay(_selectedDay),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];

        List<TimetableEvent> filtered = events;
        if (_searchQuery.isNotEmpty) {
          filtered = events
              .where(
                (e) =>
                    e.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    e.description.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No events found'
                      : l10n.noEventsFor(_dayNames[_selectedDay - 1]),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final event = filtered[index];
            final color = parseColor(event.color) ?? Colors.grey;
            return Card(
              color: color.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: color.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => context.push('/timetable-event/${event.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Left: time block
                      Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(event.startTime),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color),
                            ),
                            const SizedBox(height: 2),
                            Container(width: 18, height: 1, color: color.withValues(alpha: 0.4)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm').format(event.endTime),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8)),
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
                              event.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                event.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Right: more icon (vertically centered)
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            context.push('/timetable-event/${event.id}');
                          } else if (action == 'delete') {
                            _confirmDeleteTimetableEvent(event);
                          }
                        },
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 28,
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
                    hintText: l10n.searchTimetable,
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
                child: StreamBuilder<List<TimetableEvent>>(
                  stream: database.watchTimetableForDay(_selectedDay),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? events
                        : events
                              .where(
                                (e) =>
                                    e.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    e.description.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        final color =
                            parseColor(event.color) ?? Colors.grey;
                        return ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(event.title),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                          ),
                        );
                      },
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
