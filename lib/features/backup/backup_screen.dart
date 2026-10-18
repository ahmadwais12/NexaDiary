import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/security/encryption_service.dart';
import '../../core/utilities/app_theme.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../core/utilities/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String? _customPath;
  List<io.File> _backupFiles = [];
  bool _isLoading = true;

  static const _pathKey = 'backup_custom_path';

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final prefs = await SharedPreferences.getInstance();
    _customPath = prefs.getString(_pathKey);
    await _refreshBackupFiles();
    setState(() => _isLoading = false);
  }

  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKey, path);
    _customPath = path;
    await _refreshBackupFiles();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pathUpdated)),
      );
    }
  }

  Future<void> _resetPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pathKey);
    _customPath = null;
    await _refreshBackupFiles();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pathUpdated)),
      );
    }
  }

  Future<String> _getBackupDirectory() async {
    if (_customPath != null && _customPath!.isNotEmpty) {
      return _customPath!;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> _refreshBackupFiles() async {
    try {
      final dirPath = await _getBackupDirectory();
      final dir = io.Directory(dirPath);
      if (await dir.exists()) {
        final files = await dir
            .list()
            .where((f) => f is io.File && f.path.endsWith('.json'))
            .cast<io.File>()
            .toList();
        files.sort((a, b) => b.path.compareTo(a.path)); // newest first
        _backupFiles = files;
      } else {
        _backupFiles = [];
      }
    } catch (e) {
      _backupFiles = [];
    }
  }

  Future<void> _pickNewPath() async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select backup folder',
    );
    if (result != null) {
      await _savePath(result);
    }
  }

  String _formatFileSize(io.File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatFileDate(io.File file) {
    final stat = file.statSync();
    return DateFormat('MMM d, yyyy  HH:mm').format(stat.modified);
  }

  String _getFileName(io.File file) {
    return file.path.split(io.Platform.pathSeparator).last;
  }

  Future<void> _deleteBackupFile(io.File file) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 40),
        title: Text(l10n.deleteBackup),
        content: Text(l10n.confirmDeleteBackup),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await file.delete();
      await _refreshBackupFiles();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupDeleted)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dirName = _customPath ?? 'Default';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backup),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _refreshBackupFiles();
              setState(() => _isLoading = false);
            },
            tooltip: 'Refresh',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── Backup Location Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.folder_rounded, color: AppTheme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.backupLocation,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.backupPathDescription,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Path display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dirName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickNewPath,
                                icon: const Icon(Icons.folder_open_rounded, size: 18),
                                label: Text(l10n.changePath),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            if (_customPath != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _resetPath,
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                label: Text(l10n.defaultPath),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Export Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.upload_rounded, color: Colors.blue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.exportSection,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.exportDescription, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _exportData(context),
                                icon: const Icon(Icons.file_download_rounded),
                                label: Text(l10n.exportData),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareData(context),
                                icon: const Icon(Icons.share_rounded),
                                label: Text(l10n.share),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Import Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.download_rounded, color: Colors.green, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.importSection,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.restoreFromBackup, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _importData(context),
                            icon: const Icon(Icons.file_upload_rounded),
                            label: Text(l10n.importBackup),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Backup Files List Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: Colors.orange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.backupFiles,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_backupFiles.length}',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_backupFiles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.folder_off_rounded, size: 48, color: theme.colorScheme.outlineVariant),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.noBackupsInLocation,
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_backupFiles.length, (index) {
                            final file = _backupFiles[index];
                            final name = _getFileName(file);
                            final size = _formatFileSize(file);
                            final date = _formatFileDate(file);

                            return Container(
                              margin: EdgeInsets.only(bottom: index < _backupFiles.length - 1 ? 8 : 0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // File icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.description_rounded, color: Colors.orange, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  // File info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$size  ·  $date',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                    onPressed: () => _deleteBackupFile(file),
                                    tooltip: l10n.deleteBackup,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Privacy Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.grey, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.privacySection,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.allDataStoredLocally,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
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

  Future<void> _exportData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsState>();
    try {
      final data = await database.exportAllData();
      var json = jsonEncode(data);

      // Encrypt if enabled
      if (settings.encryptBackups) {
        final password = await _showEncryptionPasswordDialog(context, encrypt: true);
        if (password == null) return; // User cancelled
        final encryption = EncryptionService();
        await encryption.deriveKey(password);
        json = await encryption.encrypt(json);
      }

      final dirPath = await _getBackupDirectory();
      final dir = io.Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = io.File('$dirPath/backup_$timestamp.json');
      await file.writeAsString(json);
      await database.into(database.backupHistory).insert(
        BackupHistoryCompanion.insert(
          backupPath: file.path,
          backupSize: json.length,
          createdAt: DateTime.now(),
          status: 'success',
        ),
      );
      await _refreshBackupFiles();
      if (mounted) setState(() {});
      if (context.mounted) {
        final msg = settings.encryptBackups
            ? 'Backup saved (encrypted)' 
            : l10n.backupSaved;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _shareData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsState>();
    try {
      final data = await database.exportAllData();
      var json = jsonEncode(data);

      // Encrypt if enabled (consistent with _exportData)
      if (settings.encryptBackups) {
        final password = await _showEncryptionPasswordDialog(context, encrypt: true);
        if (password == null) return; // User cancelled
        final encryption = EncryptionService();
        await encryption.deriveKey(password);
        json = await encryption.encrypt(json);
      }

      final dirPath = await _getBackupDirectory();
      final dir = io.Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = io.File('$dirPath/backup_$timestamp.json');
      await file.writeAsString(json);
      await database.into(database.backupHistory).insert(
        BackupHistoryCompanion.insert(
          backupPath: file.path,
          backupSize: json.length,
          createdAt: DateTime.now(),
          status: 'success',
        ),
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Workspace Backup'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareFailed(e.toString()))),
        );
      }
    }
  }

  Future<String?> _showEncryptionPasswordDialog(BuildContext context, {required bool encrypt}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          encrypt ? Icons.enhanced_encryption_rounded : Icons.lock_open_rounded,
          size: 36,
        ),
        title: Text(encrypt ? 'Encryption Password' : 'Decryption Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: encrypt ? 'Enter password to encrypt' : 'Enter password to decrypt',
            prefixIcon: const Icon(Icons.key_rounded),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _importData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result.isNotEmpty) {
        final file = io.File(result.first.path!);
        var json = await file.readAsString();

        // Try to detect if file is encrypted (not valid JSON)
        Map<String, dynamic> data;
        try {
          data = jsonDecode(json) as Map<String, dynamic>;
        } catch (_) {
          // Not valid JSON — likely encrypted, prompt for password
          final password = await _showEncryptionPasswordDialog(context, encrypt: false);
          if (password == null) return;
          final encryption = EncryptionService();
          await encryption.deriveKey(password);
          try {
            json = await encryption.decrypt(json);
            data = jsonDecode(json) as Map<String, dynamic>;
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wrong password or corrupted file'), behavior: SnackBarBehavior.floating),
              );
            }
            return;
          }
        }

        if (data['notes'] != null) {
          for (final n in data['notes']) {
            await database.createNote(NotesCompanion.insert(
              title: n['title'],
              content: n['content'] ?? '',
              createdAt: DateTime.parse(n['createdAt']),
              modifiedAt: DateTime.parse(n['modifiedAt']),
              isFavorite: drift.Value(n['isFavorite'] ?? false),
              isPinned: drift.Value(n['isPinned'] ?? false),
            ));
          }
        }
        if (data['tasks'] != null) {
          for (final t in data['tasks']) {
            await database.createTask(TasksCompanion.insert(
              title: t['title'],
              description: t['description'] ?? '',
              priority: t['priority'] ?? 'medium',
              status: t['status'] ?? 'pending',
              createdAt: DateTime.parse(t['createdAt']),
              dueDate: drift.Value(
                t['dueDate'] != null ? DateTime.parse(t['dueDate']) : null,
              ),
            ));
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupImported)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailed(e.toString()))),
        );
      }
    }
  }
}
