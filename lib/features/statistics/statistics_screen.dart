import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // === Overview Card ===
                  _buildOverviewCard(context, l10n, theme),
                  const SizedBox(height: 16),

                  // === Content Stats ===
                  _buildSectionHeader('Content Overview', theme),
                  _buildStatCard(
                    context,
                    icon: Icons.note_rounded,
                    title: l10n.notes,
                    color: Colors.blue,
                    child: FutureBuilder<List<Note>>(
                      future: database.getAllNotes(),
                      builder: (context, snapshot) {
                        final notes = snapshot.data ?? [];
                        final totalWords = notes.fold<int>(
                            0, (sum, n) => sum + n.content.split(RegExp(r'\s+')).length);
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(l10n.all, '${notes.length}'),
                                _buildStatItem(l10n.favorites, '${notes.where((n) => n.isFavorite).length}'),
                                _buildStatItem(l10n.pin, '${notes.where((n) => n.isPinned).length}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMiniStat('Words', '$totalWords'),
                                  _buildMiniStat('Avg/Note', notes.isNotEmpty ? '${(totalWords / notes.length).round()}' : '0'),
                                  _buildMiniStat('Archived', '${notes.where((n) => n.isArchived).length}'),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    context,
                    icon: Icons.task_alt_rounded,
                    title: l10n.tasks,
                    color: Colors.green,
                    child: FutureBuilder<List<Task>>(
                      future: database.getAllTasks(),
                      builder: (context, snapshot) {
                        final tasks = snapshot.data ?? [];
                        final completed = tasks.where((t) => t.status == 'completed').length;
                        final pending = tasks.where((t) => t.status == 'pending').length;
                        final high = tasks.where((t) => t.priority == 'high').length;
                        final completionRate = tasks.isNotEmpty ? ((completed / tasks.length) * 100).round() : 0;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(l10n.all, '${tasks.length}'),
                                _buildStatItem(l10n.completed, '$completed'),
                                _buildStatItem(l10n.pending, '$pending'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Completion Rate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    Text('$completionRate%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: tasks.isNotEmpty ? completed / tasks.length : 0,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.green,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMiniStat('High Priority', '$high'),
                                  _buildMiniStat('Medium', '${tasks.where((t) => t.priority == 'medium').length}'),
                                  _buildMiniStat('Low', '${tasks.where((t) => t.priority == 'low').length}'),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    context,
                    icon: Icons.folder_rounded,
                    title: l10n.files,
                    color: Colors.purple,
                    child: FutureBuilder<List<AppFile>>(
                      future: database.getAllFiles(),
                      builder: (context, snapshot) {
                        final files = snapshot.data ?? [];
                        final totalSize = files.fold<int>(0, (sum, f) => sum + f.size);
                        final images = files.where((f) => f.mimeType.startsWith('image/')).length;
                        final videos = files.where((f) => f.mimeType.startsWith('video/')).length;
                        final audio = files.where((f) => f.mimeType.startsWith('audio/')).length;
                        final docs = files.length - images - videos - audio;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(l10n.all, '${files.length}'),
                                _buildStatItem(l10n.favorites, '${files.where((f) => f.isFavorite).length}'),
                                _buildStatItem('Size', _formatFileSize(totalSize)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMiniStat('Images', '$images'),
                                  _buildMiniStat('Videos', '$videos'),
                                  _buildMiniStat('Audio', '$audio'),
                                  _buildMiniStat('Docs', '$docs'),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildStatCard(
                    context,
                    icon: Icons.alarm_rounded,
                    title: l10n.reminders,
                    color: Colors.orange,
                    child: FutureBuilder<List<Reminder>>(
                      future: database.getAllReminders(),
                      builder: (context, snapshot) {
                        final reminders = snapshot.data ?? [];
                        final active = reminders.where((r) => r.isActive).length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(l10n.all, '${reminders.length}'),
                            _buildStatItem('Active', '$active'),
                            _buildStatItem('Inactive', '${reminders.length - active}'),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // === Quick Insights ===
                  _buildSectionHeader('Quick Insights', theme),
                  _buildInsightsCard(context, theme),

                  const SizedBox(height: 24),

                  // === Privacy Badge ===
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '100% Private',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  l10n.allStatsCalculatedLocally,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Your Activity Overview',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getOverviewCounts(),
              builder: (context, snapshot) {
                final counts = snapshot.data ?? {};
                final total = (counts['notes'] ?? 0) + (counts['tasks'] ?? 0) + (counts['files'] ?? 0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewItem(Icons.note_rounded, 'Notes', '${counts['notes'] ?? 0}', Colors.blue),
                    _buildOverviewItem(Icons.task_alt_rounded, 'Tasks', '${counts['tasks'] ?? 0}', Colors.green),
                    _buildOverviewItem(Icons.folder_rounded, 'Files', '${counts['files'] ?? 0}', Colors.purple),
                    _buildOverviewItem(Icons.check_circle_rounded, 'Total', '$total', theme.colorScheme.primary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildInsightsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInsightRow(
              icon: Icons.lightbulb_rounded,
              color: Colors.amber,
              title: 'Productivity Tip',
              subtitle: 'You have completed more than 50% of your tasks. Keep it up!',
            ),
            const Divider(),
            _buildInsightRow(
              icon: Icons.trending_up_rounded,
              color: Colors.green,
              title: 'Storage Healthy',
              subtitle: 'Your data is well-organized and backed up.',
            ),
            const Divider(),
            _buildInsightRow(
              icon: Icons.security_rounded,
              color: Colors.blue,
              title: 'Data Protected',
              subtitle: 'All your data stays on your device. No cloud sync.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String title, required Color color, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }

  Future<Map<String, int>> _getOverviewCounts() async {
    final notes = await database.getNotesCount();
    final tasks = await database.getTasksCount();
    final files = await database.getFilesCount();
    return {'notes': notes, 'tasks': tasks, 'files': files};
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
