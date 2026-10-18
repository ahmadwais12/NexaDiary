import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.trash,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: [
            Tab(icon: const Icon(Icons.sticky_note_2_outlined, size: 18), text: l10n.notes),
            Tab(icon: const Icon(Icons.check_circle_outline, size: 18), text: l10n.tasks),
            Tab(icon: const Icon(Icons.folder_open, size: 18), text: l10n.files),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TrashedNotesTab(),
          _TrashedTasksTab(),
          _TrashedFilesTab(),
        ],
      ),
    );
  }
}

// ─── Shared Card Shell ───

Widget _trashCard({
  required BuildContext context,
  required Color accent,
  required IconData icon,
  required Widget content,
  required VoidCallback onRestore,
  required List<PopupMenuEntry<String>> menuItems,
  required ValueChanged<String> onMenuSelected,
}) {
  return Card(
    color: accent.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: accent.withValues(alpha: 0.25)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(child: content),
          IconButton(
            tooltip: 'Restore',
            onPressed: onRestore,
            icon: const Icon(Icons.restore_from_trash_rounded, size: 24, color: Colors.green),
          ),
          PopupMenuButton<String>(
            onSelected: onMenuSelected,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 26,
              color: Colors.grey.shade600,
            ),
            itemBuilder: (context) => menuItems,
          ),
        ],
      ),
    ),
  );
}

List<PopupMenuEntry<String>> _trashMenuItems(AppLocalizations l10n) => [
      PopupMenuItem(
        value: 'restore',
        child: Row(
          children: [
            const Icon(Icons.restore, size: 20, color: Colors.green),
            const SizedBox(width: 12),
            Text(l10n.restore),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'permanent_delete',
        child: Row(
          children: [
            const Icon(Icons.delete_forever, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Text(l10n.deletePermanently, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];

void _handleTrashMenu(
  BuildContext context,
  AppLocalizations l10n,
  String value,
  String type,
  int id,
  String name, {
  required Future<void> Function() restore,
  required String restoredMessage,
}) async {
  if (value == 'restore') {
    await restore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(restoredMessage)),
      );
    }
  } else if (value == 'permanent_delete') {
    _confirmPermanentDelete(context, l10n, type, id, name);
  }
}

// ─── Trashed Notes Tab ───

class _TrashedNotesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Note>>(
      stream: database.watchTrashedNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return _buildEmptyState(context, l10n, Icons.sticky_note_2_outlined);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(context, notes[index], l10n),
        );
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, AppLocalizations l10n) {
    final bgColor = parseColor(note.color);
    final theme = Theme.of(context);
    return _trashCard(
      context: context,
      accent: bgColor ?? theme.colorScheme.primary,
      icon: Icons.sticky_note_2_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.history_rounded, size: 13, color: Colors.grey.shade500),
              Flexible(
                child: Text(
                  DateFormat('MMM d, yyyy').format(note.modifiedAt),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ],
      ),
      onRestore: () async {
        await database.restoreNote(note.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noteRestored)),
          );
        }
      },
      menuItems: _trashMenuItems(l10n),
      onMenuSelected: (value) => _handleTrashMenu(
        context, l10n, value, 'note', note.id, note.title,
        restore: () => database.restoreNote(note.id),
        restoredMessage: l10n.noteRestored,
      ),
    );
  }
}

// ─── Trashed Tasks Tab ───

class _TrashedTasksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Task>>(
      stream: database.watchTrashedTasks(),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return _buildEmptyState(context, l10n, Icons.check_circle_outline);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _buildTaskCard(context, tasks[index], l10n),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, AppLocalizations l10n) {
    final bgColor = parseColor(task.color);
    final theme = Theme.of(context);
    final priorityMeta = _priorityMeta(task.priority);
    return _trashCard(
      context: context,
      accent: bgColor ?? theme.colorScheme.primary,
      icon: Icons.task_alt_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              task.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _buildPriorityChip(priorityMeta),
              if (task.dueDate != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(task.dueDate!),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      onRestore: () async {
        await database.restoreTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.taskRestored)),
          );
        }
      },
      menuItems: _trashMenuItems(l10n),
      onMenuSelected: (value) => _handleTrashMenu(
        context, l10n, value, 'task', task.id, task.title,
        restore: () => database.restoreTask(task.id),
        restoredMessage: l10n.taskRestored,
      ),
    );
  }

  (String, Color) _priorityMeta(String priority) {
    switch (priority) {
      case 'urgent':
        return ('Urgent', Colors.red);
      case 'high':
        return ('High', Colors.orange);
      case 'medium':
        return ('Medium', Colors.blue);
      case 'low':
        return ('Low', Colors.green);
      default:
        return (priority, Colors.grey);
    }
  }

  Widget _buildPriorityChip((String, Color) meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: meta.$2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        meta.$1,
        style: TextStyle(
          fontSize: 11,
          color: meta.$2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Trashed Files Tab ───

class _TrashedFilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<AppFile>>(
      stream: database.watchTrashedFiles(),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return _buildEmptyState(context, l10n, Icons.folder_open);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileCard(context, files[index], l10n),
        );
      },
    );
  }

  Widget _buildFileCard(BuildContext context, AppFile file, AppLocalizations l10n) {
    final bgColor = parseColor(file.color);
    final theme = Theme.of(context);
    return _trashCard(
      context: context,
      accent: bgColor ?? theme.colorScheme.primary,
      icon: _getFileIcon(file.mimeType),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            file.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.folder_zip_rounded, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                _formatSize(file.size),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
      onRestore: () async {
        await database.restoreFile(file.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.fileRestored)),
          );
        }
      },
      menuItems: _trashMenuItems(l10n),
      onMenuSelected: (value) => _handleTrashMenu(
        context, l10n, value, 'file', file.id, file.name,
        restore: () => database.restoreFile(file.id),
        restoredMessage: l10n.fileRestored,
      ),
    );
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    if (mime.startsWith('audio/')) return Icons.music_note_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ─── Shared Helpers ───

Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, IconData icon) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 44, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.trashEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            l10n.trashHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ),
      ],
    ),
  );
}

void _confirmPermanentDelete(
  BuildContext context,
  AppLocalizations l10n,
  String type,
  int id,
  String name,
) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Delete Forever?',
    itemName: name,
    isPermanent: true,
  );
  if (confirmed) {
    switch (type) {
      case 'note':
        await database.deleteNote(id);
        break;
      case 'task':
        await database.deleteTask(id);
        break;
      case 'file':
        await database.deleteFile(id);
        break;
    }
  }
}
