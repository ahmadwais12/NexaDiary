import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:provider/provider.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/app_date.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  String _searchQuery = '';

  /// Calendar types: gregorian, hijri, shamsi
  String _calendarType = 'gregorian';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsState>();
    if (_calendarType != settings.calendarType) {
      _calendarType = settings.calendarType;
      // Convert _currentMonth to new calendar type context
      _syncCurrentMonthToType();
    }
  }

  void _syncCurrentMonthToType() {
    // Keep _currentMonth as Gregorian internally; just rebuild
    setState(() {});
  }

  // ─── Calendar conversion helpers ───

  String _formatMonthYear(DateTime date) {
    switch (_calendarType) {
      case 'hijri':
        final hijri = HijriCalendarConfig.fromGregorian(date);
        final hijriMonths = [
          '', 'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
          'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
          'Ramadan', 'Shawwal', 'Dhul Qi\'dah', 'Dhul Hijjah',
        ];
        final monthName = hijriMonths[hijri.hMonth];
        return '$monthName ${hijri.hYear}';
      case 'shamsi':
        final jalali = Jalali.fromDateTime(date);
        final shamsiMonths = AppDate.shamsiMonthsOf(context);
        final monthName = shamsiMonths[jalali.month];
        return '$monthName ${jalali.year}';
      default:
        return DateFormat('MMMM yyyy').format(date);
    }
  }

  int _getFirstDayOfMonth() {
    switch (_calendarType) {
      case 'hijri':
        final hijri = HijriCalendarConfig.fromGregorian(_currentMonth);
        final firstGregorian = hijri.hijriToGregorian(hijri.hYear, hijri.hMonth, 1);
        return firstGregorian.weekday;
      case 'shamsi':
        final jalali = Jalali.fromDateTime(_currentMonth);
        final firstGregorian = Jalali(jalali.year, jalali.month, 1).toDateTime();
        return firstGregorian.weekday;
      default:
        return DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    }
  }

  int _getDaysInMonth() {
    switch (_calendarType) {
      case 'hijri':
        final hijri = HijriCalendarConfig.fromGregorian(_currentMonth);
        return hijri.getDaysInMonth(hijri.hYear, hijri.hMonth);
      case 'shamsi':
        final jalali = Jalali.fromDateTime(_currentMonth);
        return Jalali(jalali.year, jalali.month).monthLength;
      default:
        return DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    }
  }

  /// Convert calendar-specific day number back to a Gregorian DateTime
  DateTime _dayToGregorian(int day) {
    switch (_calendarType) {
      case 'hijri':
        final hijri = HijriCalendarConfig.fromGregorian(_currentMonth);
        return hijri.hijriToGregorian(hijri.hYear, hijri.hMonth, day);
      case 'shamsi':
        final jalali = Jalali.fromDateTime(_currentMonth);
        return Jalali(jalali.year, jalali.month, day).toDateTime();
      default:
        return DateTime(_currentMonth.year, _currentMonth.month, day);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateMonth(int offset) {
    setState(() {
      switch (_calendarType) {
        case 'hijri':
          final hijri = HijriCalendarConfig.fromGregorian(_currentMonth);
          final newMonth = hijri.hMonth + offset;
          if (newMonth < 1) {
            final temp = HijriCalendarConfig.fromHijri(hijri.hYear - 1, 12, 1);
            _currentMonth = temp.hijriToGregorian(hijri.hYear - 1, 12, 1);
          } else if (newMonth > 12) {
            final temp = HijriCalendarConfig.fromHijri(hijri.hYear + 1, 1, 1);
            _currentMonth = temp.hijriToGregorian(hijri.hYear + 1, 1, 1);
          } else {
            _currentMonth = hijri.hijriToGregorian(hijri.hYear, newMonth, 1);
          }
          break;
        case 'shamsi':
          final jalali = Jalali.fromDateTime(_currentMonth);
          final newMonth = jalali.month + offset;
          if (newMonth < 1) {
            _currentMonth = Jalali(jalali.year - 1, 12, 1).toDateTime();
          } else if (newMonth > 12) {
            _currentMonth = Jalali(jalali.year + 1, 1, 1).toDateTime();
          } else {
            _currentMonth = Jalali(jalali.year, newMonth, 1).toDateTime();
          }
          break;
        default:
          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      }
    });
  }

  String _weekdayLabel(int index) {
    // index 0-6 maps to Mon-Sun
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[index];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = ResponsiveUtils(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatMonthYear(_currentMonth),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.isIpad ? 18 : (r.isTablet ? 16 : 15)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildCalendarTypeChip(l10n),
          ],
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _currentMonth = DateTime.now();
              });
            },
            icon: const Icon(Icons.today, size: 18),
            label: Text(l10n.today),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthCalendar(),
          const Divider(height: 1),
          Expanded(child: _buildEventsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_calendar_fab',
        onPressed: () => context.push('/calendar-event/new?date=${_selectedDate.toIso8601String()}'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newEvent),
      ),
    );
  }

  Widget _buildCalendarTypeChip(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final types = [
      {'key': 'gregorian', 'label': l10n.gregorian},
      {'key': 'hijri', 'label': l10n.hijri},
      {'key': 'shamsi', 'label': l10n.shamsi},
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: types.map((t) {
        final isSelected = _calendarType == t['key'];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () {
              context.read<SettingsState>().setCalendarType(t['key']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t['label']!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthCalendar() {
    final firstWeekday = _getFirstDayOfMonth();
    final totalDays = _getDaysInMonth();
    final totalCells = (firstWeekday - 1) + totalDays;
    final totalRows = (totalCells + 6) ~/ 7;
    final theme = Theme.of(context);
    final r = ResponsiveUtils(context);
    final dayHeight = r.isIpad ? 56.0 : (r.isTablet ? 50.0 : 40.0);
    final dayFontSize = r.isIpad ? 16.0 : (r.isTablet ? 15.0 : 13.0);

    return Column(
      children: [
        // Navigation row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _navigateMonth(-1),
            ),
            Flexible(
              child: Text(
                _formatMonthYear(_currentMonth),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _navigateMonth(1),
            ),
          ],
        ),
        // Weekday labels
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  _weekdayLabel(i),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Day grid
        ...List.generate(totalRows, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - (firstWeekday - 1) + 1;

              if (dayNumber < 1 || dayNumber > totalDays) {
                return Expanded(child: SizedBox(height: dayHeight));
              }

              final gregorianDate = _dayToGregorian(dayNumber);
              final isSelected = _isSameDay(gregorianDate, _selectedDate);
              final isToday = _isSameDay(gregorianDate, DateTime.now());

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = gregorianDate),
                  child: Container(
                    height: dayHeight,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : null,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.6), width: 1.5)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? theme.colorScheme.primary
                                  : null,
                          fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: dayFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildEventsList() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return StreamBuilder<List<CalendarEvent>>(
      stream: database.watchEventsForDate(_selectedDate),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];

        List<CalendarEvent> filtered = events;
        if (_searchQuery.isNotEmpty) {
          filtered = events
              .where(
                (e) =>
                    e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    e.description.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No events found'
                      : l10n.noEventsFor(DateFormat('MMM d').format(_selectedDate)),
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final event = filtered[index];
            final bgColor = parseColor(event.color);
            return Card(
              color: bgColor?.withValues(alpha: 0.12),
              shape: bgColor != null
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: bgColor.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Color bar
                    Container(
                      width: 5,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bgColor ?? Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 13, color: bgColor ?? theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                event.allDay
                                    ? l10n.allDay
                                    : '${DateFormat('HH:mm').format(event.startTime)}${event.endTime != null ? ' - ${DateFormat('HH:mm').format(event.endTime!)}' : ''}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                              ),
                              if (event.startTime.isBefore(DateTime.now())) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Past',
                                    style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // More menu
                    PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          context.push('/calendar-event/${event.id}?date=${event.startTime.toIso8601String()}');
                        } else if (action == 'delete') {
                          _confirmDeleteEvent(event);
                        }
                      },
                      icon: Icon(Icons.more_vert_rounded, size: 28, color: Colors.grey.shade600),
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
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEvent(CalendarEvent event) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Move to Trash?',
      itemName: event.title,
    );
    if (confirmed) {
      await notificationService.cancelCalendarAlarm(event.id);
      await database.trashCalendarEvent(event.id);
    }
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${l10n.search}...',
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
                child: StreamBuilder<List<CalendarEvent>>(
                  stream: database.watchEventsForDate(_selectedDate),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? events
                        : events
                            .where(
                              (e) =>
                                  e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                  e.description.toLowerCase().contains(_searchQuery.toLowerCase()),
                            )
                            .toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        final bgColor = parseColor(event.color);
                        return ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: bgColor ?? Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(event.title),
                          subtitle: event.allDay
                              ? Text(l10n.allDay)
                              : Text(
                                  '${DateFormat('HH:mm').format(event.startTime)}${event.endTime != null ? ' - ${DateFormat('HH:mm').format(event.endTime!)}' : ''}',
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
