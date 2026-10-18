import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/app_theme.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isGridLayout = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Image.asset(
                  'assets/logo/NexaDiary_mark.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'NexaDiary',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: _isGridLayout ? 'List layout' : 'Grid layout',
            icon: Icon(
              _isGridLayout
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridLayout = !_isGridLayout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF635BFF), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(now),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your private space for every thought.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTodayOverview(context, l10n),
            const SizedBox(height: 24),
            _buildSectionHeader(context, l10n.tasks, '/tasks'),
            const SizedBox(height: 8),
            _buildTodayTasks(l10n),
            const SizedBox(height: 24),
            _buildSectionHeader(context, l10n.upcomingReminders, '/reminders'),
            const SizedBox(height: 8),
            _buildUpcomingReminders(l10n),
            const SizedBox(height: 24),
            _buildSectionHeader(context, l10n.timetable, '/timetable'),
            const SizedBox(height: 8),
            _buildTodayTimetable(now, l10n),
            const SizedBox(height: 24),
            _buildSectionHeader(context, l10n.recentNotes, '/notes'),
            const SizedBox(height: 8),
            _buildRecentNotes(context, l10n),
            const SizedBox(height: 24),
            _buildSectionHeader(context, l10n.recentFiles, '/files'),
            const SizedBox(height: 8),
            _buildRecentFiles(context, l10n),
            const SizedBox(height: 24),
            _buildRecentlyPlayedMedia(context, l10n),
            const SizedBox(height: 24),
            _buildFavorites(context, l10n),
            const SizedBox(height: 24),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<List<Note>>(
      stream: database.watchAllNotes(),
      builder: (context, notesSnapshot) {
        return StreamBuilder<List<Task>>(
          stream: database.watchAllTasks(),
          builder: (context, tasksSnapshot) {
            return StreamBuilder<List<AppFile>>(
              stream: database.watchAllFiles(),
              builder: (context, filesSnapshot) {
                final notes = notesSnapshot.data ?? [];
                final tasks = tasksSnapshot.data ?? [];
                final files = filesSnapshot.data ?? [];
                final pendingTasks = tasks
                    .where((task) => task.status != 'completed')
                    .length;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your day at a glance',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildOverviewItem(
                              context,
                              icon: Icons.edit_note_rounded,
                              value: notes.length.toString(),
                              label: l10n.notes,
                              color: AppTheme.primaryColor,
                              route: '/notes',
                            ),
                            const SizedBox(width: 10),
                            _buildOverviewItem(
                              context,
                              icon: Icons.check_circle_rounded,
                              value: pendingTasks.toString(),
                              label: l10n.tasks,
                              color: AppTheme.accentColor,
                              route: '/tasks',
                            ),
                            const SizedBox(width: 10),
                            _buildOverviewItem(
                              context,
                              icon: Icons.folder_rounded,
                              value: files.length.toString(),
                              label: l10n.files,
                              color: AppTheme.secondaryColor,
                              route: '/files',
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
      },
    );
  }

  Widget _buildOverviewItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 7),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () => context.push(route),
          child: Text(AppLocalizations.of(context)!.all),
        ),
      ],
    );
  }

  Widget _buildTodayTasks(AppLocalizations l10n) {
    return StreamBuilder<List<Task>>(
      stream: database.watchTodayTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noTasksForToday,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: tasks.take(5).map((task) {
              final isCompleted = task.status == 'completed';
              return ListTile(
                leading: Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted
                      ? Colors.green
                      : _getPriorityColor(task.priority),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: task.dueTime != null
                    ? Text(DateFormat('hh:mm a').format(task.dueTime!))
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingReminders(AppLocalizations l10n) {
    return StreamBuilder<List<Reminder>>(
      stream: database.watchUpcomingReminders(),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? [];
        if (reminders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noUpcomingReminders,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: reminders
                .take(5)
                .map(
                  (r) => ListTile(
                    leading: const Icon(Icons.alarm, color: Colors.orange),
                    title: Text(r.title),
                    subtitle: Text(
                      DateFormat('MMM d, hh:mm a').format(r.reminderTime),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildTodayTimetable(DateTime now, AppLocalizations l10n) {
    return StreamBuilder<List<TimetableEvent>>(
      stream: database.watchTimetableForDay(now.weekday),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noTimetableForToday,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: events
                .take(5)
                .map(
                  (e) => ListTile(
                    leading: Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(e.color.replaceFirst('#', '0xFF')),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      '${DateFormat('HH:mm').format(e.startTime)} - ${DateFormat('HH:mm').format(e.endTime)}',
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildRecentNotes(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<List<Note>>(
      stream: database.watchAllNotes(),
      builder: (context, snapshot) {
        final notes = (snapshot.data ?? []).take(4).toList();
        if (notes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noNotesYet,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!_isGridLayout) {
          return Card(
            child: Column(
              children: notes
                  .map(
                    (note) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/note/${note.id}'),
                    ),
                  )
                  .toList(),
            ),
          );
        }
        final r = ResponsiveUtils(context);
        final columns = r.gridColumns(2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteGridItem(context, notes[index]),
        );
      },
    );
  }

  Widget _buildNoteGridItem(BuildContext context, Note note) {
    return Card(
        child: InkWell(
          onTap: () => context.push('/note/${note.id}'),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 14),
                Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildRecentlyPlayedMedia(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return StreamBuilder<List<MediaHistoryData>>(
      stream: database.watchRecentlyPlayed(limit: 5),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Recently Played', '/media'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: history
                    .map(
                      (h) => ListTile(
                        leading: Icon(
                          h.mediaType == 'audio'
                              ? Icons.music_note
                              : h.mediaType == 'video'
                              ? Icons.videocam
                              : Icons.play_circle,
                        ),
                        title: FutureBuilder<AppFile>(
                          future: database.getFile(h.fileId),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data?.name ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        subtitle: Text(h.mediaType.toUpperCase()),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFavorites(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<List<Note>>(
      stream: database.watchFavoriteNotes(),
      builder: (context, noteSnapshot) {
        final favoriteNotes = (noteSnapshot.data ?? []).take(3).toList();
        return StreamBuilder<List<AppFile>>(
          stream: database.watchFavoriteFiles(),
          builder: (context, fileSnapshot) {
            final favoriteFiles = (fileSnapshot.data ?? []).take(3).toList();
            if (favoriteNotes.isEmpty && favoriteFiles.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n!.favorites,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (favoriteNotes.isNotEmpty)
                  Card(
                    child: Column(
                      children: [
                        for (final note in favoriteNotes)
                          ListTile(
                            leading: const Icon(
                              Icons.note,
                              color: Colors.amber,
                            ),
                            title: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(l10n!.noteLabel),
                            onTap: () => context.push('/note/${note.id}'),
                          ),
                      ],
                    ),
                  ),
                if (favoriteFiles.isNotEmpty)
                  Card(
                    child: Column(
                      children: [
                        for (final file in favoriteFiles)
                          ListTile(
                            leading: Icon(
                              _getFileIcon(file.mimeType),
                              color: Colors.amber,
                            ),
                            title: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(l10n!.fileLabel),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentFiles(BuildContext context, AppLocalizations l10n) {
    return StreamBuilder<List<AppFile>>(
      stream: database.watchAllFiles(),
      builder: (context, snapshot) {
        final files = (snapshot.data ?? []).take(4).toList();
        if (files.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noFilesYet,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }
        if (_isGridLayout) {
          final r = ResponsiveUtils(context);
          final columns = r.gridColumns(2);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Card(
                child: InkWell(
                  onTap: () => context.push('/media'),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getFileIcon(file.mimeType),
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(file.size),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        return Card(
          child: Column(
            children: files
                .map(
                  (file) => ListTile(
                    leading: Icon(_getFileIcon(file.mimeType)),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_formatFileSize(file.size)),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String p) {
    switch (p) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.startsWith('video/')) return Icons.video_file;
    if (mime.startsWith('audio/')) return Icons.audio_file;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
