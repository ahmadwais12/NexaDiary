import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class DataStorageSettingsScreen extends StatefulWidget {
  const DataStorageSettingsScreen({super.key});

  @override
  State<DataStorageSettingsScreen> createState() =>
      _DataStorageSettingsScreenState();
}

class _DataStorageSettingsScreenState extends State<DataStorageSettingsScreen> {
  int _notesCount = 0;
  int _tasksCount = 0;
  int _filesCount = 0;
  int _remindersCount = 0;
  int _trashedCount = 0;
  String _dbSize = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/workspace.sqlite');
      final dbSize = await dbFile.exists() ? await dbFile.length() : 0;

      final notesCount = await database.getNotesCount();
      final tasksCount = await database.getTasksCount();
      final filesCount = await database.getFilesCount();
      final remindersCount = await database.getRemindersCount();
      final trashedCount = await database.getTrashedCount();

      final sizeKb = dbSize ~/ 1024;
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      if (!mounted) return;
      setState(() {
        _notesCount = notesCount;
        _tasksCount = tasksCount;
        _filesCount = filesCount;
        _remindersCount = remindersCount;
        _trashedCount = trashedCount;
        _dbSize = sizeStr;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _dbSize = 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.data)),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // === STORAGE OVERVIEW ===
                  _buildSectionHeader(l10n.storageUsage, theme),
                  _buildStorageOverviewCard(theme),

                  const SizedBox(height: 16),

                  // === CONTENT BREAKDOWN ===
                  _buildSectionHeader('Content Breakdown', theme),
                  _buildContentBreakdownCard(theme),

                  const SizedBox(height: 16),

                  // === MAINTENANCE ===
                  _buildSectionHeader('Maintenance', theme),
                  _buildSettingsCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.delete_sweep_rounded,
                        iconColor: Colors.red,
                        title: l10n.clearTrash,
                        subtitle: _trashedCount > 0
                            ? '$_trashedCount items in trash'
                            : l10n.clearTrashDescription,
                        onTap: () => _clearTrash(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.cleaning_services_rounded,
                        iconColor: Colors.orange,
                        title: l10n.clearCache,
                        subtitle: l10n.clearCacheDescription,
                        onTap: () => _clearCache(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildSettingsTile(
                        icon: Icons.backup_rounded,
                        iconColor: Colors.teal,
                        title: 'Export Data',
                        subtitle: 'Create a backup of all your data',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export feature coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === DATABASE INFO ===
                  _buildSectionHeader('Database Info', theme),
                  _buildSettingsCard(
                    children: [
                      _buildInfoTile('Database Size', _dbSize, Colors.blueGrey),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile('Notes', '$_notesCount items', Colors.blue),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile('Tasks', '$_tasksCount items', Colors.green),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile('Files', '$_filesCount items', Colors.purple),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile('Reminders', '$_remindersCount items', Colors.orange),
                      const Divider(height: 1, indent: 56),
                      _buildInfoTile('Trashed', '$_trashedCount items', Colors.red),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStorageOverviewCard(ThemeData theme) {
    final totalItems = _notesCount + _tasksCount + _filesCount + _remindersCount;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.sd_storage_rounded,
                            color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dbSize,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$totalItems total items across all categories',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Storage bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.3, // Placeholder
                      backgroundColor: Colors.grey.shade200,
                      color: theme.colorScheme.primary,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Database: $_dbSize',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContentBreakdownCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.08),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBreakdownItem(Icons.note_rounded, 'Notes', _notesCount, Colors.blue),
                  _buildBreakdownItem(Icons.task_alt_rounded, 'Tasks', _tasksCount, Colors.green),
                  _buildBreakdownItem(Icons.folder_rounded, 'Files', _filesCount, Colors.purple),
                  _buildBreakdownItem(Icons.alarm_rounded, 'Reminders', _remindersCount, Colors.orange),
                ],
              ),
            ),
    );
  }

  Widget _buildBreakdownItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String label, String value, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
    );
  }

  void _clearTrash(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_trashedCount == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noTrashedItems)),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 36),
          title: Text(l10n.clearTrashConfirm),
          content: Text('This will permanently delete $_trashedCount trashed items.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await database.clearAllTrashed();
        _loadStorageInfo(); // Refresh counts
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trashCleared)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _clearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tempDir = await getTemporaryDirectory();
      int clearedSize = 0;
      final files = tempDir.listSync();
      for (final file in files) {
        try {
          if (file is File) {
            clearedSize += await file.length();
          }
          await file.delete(recursive: true);
        } catch (_) {}
      }

      final clearedStr = clearedSize > 1024 * 1024
          ? '${(clearedSize / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(clearedSize / 1024).toStringAsFixed(1)} KB';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cache cleared ($clearedStr freed)')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cacheCleared)),
      );
    }
  }
}
