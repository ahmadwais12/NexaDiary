import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  int? _selectedFolderId;
  bool _isGrid = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.files,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: Icon(_isGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedFolderId != null)
            TextButton(
              onPressed: () => setState(() => _selectedFolderId = null),
              child: Text(l10n.files),
            ),
          Expanded(
            child: StreamBuilder<List<AppFile>>(
              stream: _selectedFolderId != null
                  ? database.watchFilesByFolder(_selectedFolderId)
                  : database.watchAllFiles(),
              builder: (context, snapshot) {
                final files = snapshot.data ?? [];
                final filteredFiles = _searchQuery.isEmpty
                    ? files
                    : files.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                if (filteredFiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noFilesYet,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.importFiles,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGrid) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) =>
                        _buildFileGridItem(filteredFiles[index]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) =>
                        _buildFileListItem(filteredFiles[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_files_fab',
        onPressed: _importFiles,
        icon: const Icon(Icons.add),
        label: Text(l10n.import),
      ),
    );
  }

  Widget _buildFileGridItem(AppFile file) {
    final mimeType = lookupMimeType(file.filePath);
    final bgColor = parseColor(file.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getFileIcon(mimeType ?? ''), size: 40),
          const SizedBox(height: 4),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListItem(AppFile file) {
    final l10n = AppLocalizations.of(context)!;
    final mimeType = lookupMimeType(file.filePath);
    final bgColor = parseColor(file.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      shape: bgColor != null ? RoundedRectangleBorder(
        side: BorderSide(color: bgColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Left: icon
            Icon(_getFileIcon(mimeType ?? ''), size: 28, color: bgColor),
            const SizedBox(width: 14),
            // Left: content (title, body, size)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSize(file.size),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Right: more icon (vertically centered)
            PopupMenuButton<String>(
              onSelected: (v) => _handleFileAction(v, file),
              icon: Icon(
                Icons.more_vert_rounded,
                size: 28,
                color: Colors.grey.shade600,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.rename),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: const [
                      Icon(Icons.palette, size: 20),
                      SizedBox(width: 12),
                      Text('Color'),
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
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<AppFile>>(
                  stream: database.watchAllFiles(),
                  builder: (context, snapshot) {
                    final files = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? files
                        : files.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final file = filtered[index];
                        final mimeType = lookupMimeType(file.filePath);
                        return ListTile(
                          leading: Icon(_getFileIcon(mimeType ?? '')),
                          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_formatSize(file.size)),
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

  void _importFiles() async {
    final files = await FilePicker.pickFiles();
    if (files.isNotEmpty) {
      int count = 0;
      for (final file in files) {
        if (file.path != null) {
          final storageService = FileStorageService();
          await storageService.initialize();
          final newPath = await storageService.importFile(file.path!);
          final mime = lookupMimeType(newPath) ?? 'application/octet-stream';
          final size = await file.length();
          await database.createFile(
            AppFilesCompanion.insert(
              name: file.name,
              filePath: newPath,
              mimeType: Value(mime),
              size: size,
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
            ),
          );
          count++;
        }
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.importedFiles(count))));
      }
    }
  }

  void _handleFileAction(String action, AppFile file) async {
    final l10n = AppLocalizations.of(context)!;
    if (action == 'delete') {
      _confirmDeleteFile(file);
    } else if (action == 'color') {
      _showFileColorPicker(file);
    } else if (action == 'rename') {
      final controller = TextEditingController(text: file.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.rename),
          content: Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
          padding: const EdgeInsets.all(16),
          child: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true)),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.rename),
            ),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        await database.updateFile(
          AppFilesCompanion(
            id: Value(file.id),
            name: Value(newName),
            modifiedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  void _confirmDeleteFile(AppFile file) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Move to Trash?',
      itemName: file.name,
    );
    if (confirmed) {
      await database.trashFile(file.id);
    }
  }

  void _showFileColorPicker(AppFile file) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Card Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ColorPicker(
              selectedColor: file.color,
              onColorSelected: (c) async {
                await database.updateFile(
                  AppFilesCompanion(
                    id: Value(file.id),
                    color: Value(c),
                    modifiedAt: Value(DateTime.now()),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.startsWith('video/')) return Icons.videocam;
    if (mime.startsWith('audio/')) return Icons.music_note;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
