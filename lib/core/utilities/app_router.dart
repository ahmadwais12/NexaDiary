import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/tasks/task_editor_screen.dart';
import '../../features/files/file_browser_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/backup/backup_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/media/files_media_screen.dart';
import '../../features/media/video_player_screen.dart';
import '../../features/media/audio_player_screen.dart';
import '../../features/media/audio_recorder_screen.dart';
import '../../features/media/image_viewer_screen.dart';
import '../../features/vault/vault_screen.dart';
import '../../features/lock/app_lock_setup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/settings/appearance_settings_screen.dart';
import '../../features/settings/data_storage_settings_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/policy_screen.dart';
import '../../features/settings/security_settings_screen.dart';
import '../../features/trash/trash_screen.dart';
import '../../features/settings/about_settings_screen.dart';
import '../../features/reminders/reminder_editor_screen.dart';
import '../../features/timetable/timetable_event_editor_screen.dart';
import '../../features/calendar/calendar_event_editor_screen.dart';
import 'shell_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Notes
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (context, state) => const NotesScreen(),
            ),
          ],
        ),
        // Tasks
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ],
        ),
        // More
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes (no bottom nav)
    GoRoute(
      path: '/note/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => NoteEditorScreen(
        noteId: int.tryParse(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/note/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NoteEditorScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => TaskEditorScreen(
        taskId: int.tryParse(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/task/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaskEditorScreen(),
    ),
    GoRoute(
      path: '/file-browser',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FileBrowserScreen(),
    ),
    GoRoute(
      path: '/reminders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RemindersScreen(),
    ),
    GoRoute(
      path: '/reminder/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReminderEditorScreen(),
    ),
    GoRoute(
      path: '/reminder/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReminderEditorScreen(
        reminderId: int.tryParse(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/timetable',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TimetableScreen(),
    ),
    GoRoute(
      path: '/timetable-event/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dayOfWeek = int.tryParse(state.uri.queryParameters['day'] ?? '${DateTime.now().weekday}') ?? DateTime.now().weekday;
        return TimetableEventEditorScreen(dayOfWeek: dayOfWeek);
      },
    ),
    GoRoute(
      path: '/timetable-event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dayOfWeek = int.tryParse(state.uri.queryParameters['day'] ?? '${DateTime.now().weekday}') ?? DateTime.now().weekday;
        return TimetableEventEditorScreen(
          eventId: int.tryParse(state.pathParameters['id'] ?? ''),
          dayOfWeek: dayOfWeek,
        );
      },
    ),
    GoRoute(
      path: '/calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/calendar-event/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return CalendarEventEditorScreen(initialDate: date);
      },
    ),
    GoRoute(
      path: '/calendar-event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dateStr = state.uri.queryParameters['date'];
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return CalendarEventEditorScreen(
          eventId: int.tryParse(state.pathParameters['id'] ?? ''),
          initialDate: date,
        );
      },
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/backup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BackupScreen(),
    ),
    GoRoute(
      path: '/statistics',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StatisticsScreen(),
    ),
    // --- Media routes ---
    GoRoute(
      path: '/media',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FilesMediaScreen(),
    ),
    GoRoute(
      path: '/media/video/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idParam = state.pathParameters['id']!;
        final filePath = state.uri.queryParameters['path'];
        return VideoPlayerScreen(
          fileId: filePath == null ? int.parse(idParam) : null,
          filePath: filePath,
        );
      },
    ),
    GoRoute(
      path: '/media/audio/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idParam = state.pathParameters['id']!;
        final filePath = state.uri.queryParameters['path'];
        return AudioPlayerScreen(
          fileId: filePath == null ? int.parse(idParam) : null,
          filePath: filePath,
        );
      },
    ),
    GoRoute(
      path: '/media/image/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idParam = state.pathParameters['id']!;
        final filePath = state.uri.queryParameters['path'];
        if (filePath != null) {
          return ImageViewerScreen.single(filePath: filePath);
        }
        final id = int.tryParse(idParam);
        if (id != null && id > 0) {
          return ImageViewerScreen(fileId: id);
        }
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '/media/record',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AudioRecorderScreen(),
    ),
    // --- Vault route ---
    GoRoute(
      path: '/vault',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VaultScreen(),
    ),
    GoRoute(
      path: '/app-lock-setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppLockSetupScreen(),
    ),
    // --- Settings screens ---
    GoRoute(
      path: '/trash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TrashScreen(),
    ),
    GoRoute(
      path: '/settings/appearance',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppearanceSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/data',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DataStorageSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const PolicyScreen(type: PolicyType.privacy),
    ),
    GoRoute(
      path: '/settings/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PolicyScreen(type: PolicyType.terms),
    ),
  ],
);


