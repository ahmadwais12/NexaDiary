import 'package:flutter/material.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../l10n/app_localizations.dart';
import 'settings_state.dart';

/// Calendar-aware date formatting and picking.
///
/// Uses the active [SettingsState.calendarType] (gregorian | hijri | shamsi).
class AppDate {
  AppDate._();

  /// Localized Shamsi month names (index 1-12) based on the active app language.
  static List<String> shamsiMonthsOf(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      '',
      l10n?.shamsiMonth1 ?? 'Hamal',
      l10n?.shamsiMonth2 ?? 'Sawr',
      l10n?.shamsiMonth3 ?? 'Jawza',
      l10n?.shamsiMonth4 ?? 'Saratan',
      l10n?.shamsiMonth5 ?? 'Asad',
      l10n?.shamsiMonth6 ?? 'Sunbula',
      l10n?.shamsiMonth7 ?? 'Mizan',
      l10n?.shamsiMonth8 ?? 'Aqrab',
      l10n?.shamsiMonth9 ?? 'Qaws',
      l10n?.shamsiMonth10 ?? 'Jadi',
      l10n?.shamsiMonth11 ?? 'Dalw',
      l10n?.shamsiMonth12 ?? 'Hoot',
    ];
  }

  static const List<String> hijriMonths = [
    '',
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhul Qi'dah",
    'Dhul Hijjah',
  ];

  /// Read the active calendar type from provider.
  static String typeOf(BuildContext context) =>
      context.read<SettingsState>().calendarType;

  /// e.g. "14 Hamal 1404" / "15 Ramadan 1447" / "Apr 2, 2025"
  static String formatShort(BuildContext context, DateTime date) {
    final type = typeOf(context);
    switch (type) {
      case 'shamsi':
        final j = Jalali.fromDateTime(date);
        return '${j.day} ${shamsiMonthsOf(context)[j.month]} ${j.year}';
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(date);
        return '${h.hDay} ${hijriMonths[h.hMonth]} ${h.hYear}';
      default:
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// e.g. "Wednesday, 14 Hamal 1404"
  static String formatLong(BuildContext context, DateTime date) {
    final weekday = DateFormat('EEEE').format(date);
    final type = typeOf(context);
    switch (type) {
      case 'shamsi':
        final j = Jalali.fromDateTime(date);
        return '$weekday, ${j.day} ${shamsiMonthsOf(context)[j.month]} ${j.year}';
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(date);
        return '$weekday, ${h.hDay} ${hijriMonths[h.hMonth]} ${h.hYear}';
      default:
        return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  /// Month-year label, e.g. "Hamal 1404".
  static String formatMonthYear(BuildContext context, DateTime date, [String? calendarType]) {
    final type = calendarType ?? typeOf(context);
    switch (type) {
      case 'shamsi':
        final j = Jalali.fromDateTime(date);
        return '${shamsiMonthsOf(context)[j.month]} ${j.year}';
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(date);
        return '${hijriMonths[h.hMonth]} ${h.hYear}';
      default:
        return DateFormat('MMMM yyyy').format(date);
    }
  }

  /// Opens a calendar-type aware date picker dialog.
  /// Returns the picked Gregorian [DateTime], or null when cancelled.
  static Future<DateTime?> showPicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? calendarType,
  }) {
    final type = calendarType ?? typeOf(context);
    return showDialog<DateTime>(
      context: context,
      builder: (_) => _AppDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        calendarType: type,
      ),
    );
  }
}

class _AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String calendarType;

  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.calendarType,
  });

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  late DateTime _anchor;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _anchor = widget.initialDate;
    _selected = widget.initialDate;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _monthLabel => AppDate.formatMonthYear(context, _anchor, widget.calendarType);

  int get _firstWeekday {
    switch (widget.calendarType) {
      case 'shamsi':
        final j = Jalali.fromDateTime(_anchor);
        return Jalali(j.year, j.month, 1).toDateTime().weekday;
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(_anchor);
        return h.hijriToGregorian(h.hYear, h.hMonth, 1).weekday;
      default:
        return DateTime(_anchor.year, _anchor.month, 1).weekday;
    }
  }

  int get _daysInMonth {
    switch (widget.calendarType) {
      case 'shamsi':
        final j = Jalali.fromDateTime(_anchor);
        return Jalali(j.year, j.month).monthLength;
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(_anchor);
        return h.getDaysInMonth(h.hYear, h.hMonth);
      default:
        return DateTime(_anchor.year, _anchor.month + 1, 0).day;
    }
  }

  /// Convert a day number in the displayed month back to Gregorian.
  DateTime _dayToDate(int day) {
    switch (widget.calendarType) {
      case 'shamsi':
        final j = Jalali.fromDateTime(_anchor);
        return Jalali(j.year, j.month, day).toDateTime();
      case 'hijri':
        final h = HijriCalendarConfig.fromGregorian(_anchor);
        return h.hijriToGregorian(h.hYear, h.hMonth, day);
      default:
        return DateTime(_anchor.year, _anchor.month, day);
    }
  }

  void _navigate(int offset) {
    setState(() {
      switch (widget.calendarType) {
        case 'shamsi':
          final j = Jalali.fromDateTime(_anchor);
          final m = j.month + offset;
          if (m < 1) {
            _anchor = Jalali(j.year - 1, 12, 1).toDateTime();
          } else if (m > 12) {
            _anchor = Jalali(j.year + 1, 1, 1).toDateTime();
          } else {
            _anchor = Jalali(j.year, m, 1).toDateTime();
          }
          break;
        case 'hijri':
          final h = HijriCalendarConfig.fromGregorian(_anchor);
          final m = h.hMonth + offset;
          if (m < 1) {
            _anchor = HijriCalendarConfig.fromHijri(h.hYear - 1, 12, 1)
                .hijriToGregorian(h.hYear - 1, 12, 1);
          } else if (m > 12) {
            _anchor = HijriCalendarConfig.fromHijri(h.hYear + 1, 1, 1)
                .hijriToGregorian(h.hYear + 1, 1, 1);
          } else {
            _anchor = h.hijriToGregorian(h.hYear, m, 1);
          }
          break;
        default:
          _anchor = DateTime(_anchor.year, _anchor.month + offset, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstWeekday = _firstWeekday;
    final totalDays = _daysInMonth;
    final totalCells = (firstWeekday - 1) + totalDays;
    final totalRows = (totalCells + 6) ~/ 7;
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Selected value preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDate.formatShort(context, _selected ?? widget.initialDate),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE').format(_selected ?? widget.initialDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Month navigation
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _navigate(-1),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => _navigate(1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Weekday labels
              Row(
                children: weekdayLabels
                    .map((l) => Expanded(
                          child: Center(
                            child: Text(
                              l,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              // Day grid
              ...List.generate(totalRows, (weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final cellIndex = weekIndex * 7 + dayIndex;
                    final dayNumber = cellIndex - (firstWeekday - 1) + 1;

                    if (dayNumber < 1 || dayNumber > totalDays) {
                      return const Expanded(child: SizedBox(height: 40));
                    }

                    final date = _dayToDate(dayNumber);
                    final disabled = date.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day)) ||
                        date.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));
                    final isSelected = _selected != null && _isSameDay(date, _selected!);
                    final isToday = _isSameDay(date, DateTime.now());

                    Widget cell = Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.1)
                                : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : disabled
                                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
                                  : null,
                        ),
                      ),
                    );

                    if (!disabled) {
                      cell = InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _selected = date),
                        child: cell,
                      );
                    }

                    return Expanded(child: cell);
                  }),
                );
              }),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _selected != null
                        ? () => Navigator.pop(context, DateTime(_selected!.year, _selected!.month, _selected!.day))
                        : null,
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
