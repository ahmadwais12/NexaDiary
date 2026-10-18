import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedFolderId;
  bool _showFolders = false;
  String _searchQuery = '';

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
          l10n.notes,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFolders ? Icons.close : Icons.folder_outlined),
            onPressed: () => setState(() => _showFolders = !_showFolders),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
        ],
        bottom: _showFolders
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.all),
                  Tab(text: l10n.favorites),
                  Tab(text: l10n.archive),
                ],
              ),
      ),
      body: _showFolders ? _buildFolderView() : _buildTabBarView(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_notes_fab',
        onPressed: () => context.push('/note/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildFolderView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(
            _selectedFolderId == null ? l10n.allNotes : l10n.inFolder,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFolderPicker(),
        ),
        const Divider(),
        Expanded(child: _buildNotesList()),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotesList(),
        _buildFavoriteNotes(),
        _buildArchivedNotes(),
      ],
    );
  }

  Widget _buildNotesList() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Note>>(
      stream: _selectedFolderId != null
          ? database.watchNotesByFolder(_selectedFolderId)
          : database.watchAllNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        final filtered = _searchQuery.isEmpty
            ? notes
            : notes
                  .where(
                    (n) =>
                        n.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        n.content.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        if (filtered.isEmpty)
          return _buildEmptyState(l10n.noNotesYet, l10n.starNote);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildNoteCard(filtered[index]),
        );
      },
    );
  }

  Widget _buildFavoriteNotes() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Note>>(
      stream: database.watchFavoriteNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        if (notes.isEmpty)
          return _buildEmptyState(l10n.noFavorites, l10n.starNote);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(notes[index]),
        );
      },
    );
  }

  Widget _buildArchivedNotes() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Note>>(
      stream: database.watchAllNotes(),
      builder: (context, snapshot) {
        final notes = (snapshot.data ?? []).where((n) => n.isArchived).toList();
        if (notes.isEmpty)
          return _buildEmptyState(l10n.noArchivedNotes, l10n.archiveNotesDesc);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildNoteCard(notes[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final l10n = AppLocalizations.of(context)!;
    final bgColor = parseColor(note.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      shape: bgColor != null ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bgColor.withValues(alpha: 0.25)),
      ) : null,
      child: InkWell(
        onTap: () => context.push('/note/${note.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left: content (title, body, date)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Row(
                      children: [
                        if (note.isPinned) ...[
                          const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                        ],
                        if (note.isFavorite) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Body
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    // Date
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(note.modifiedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: more icon (vertically centered)
              PopupMenuButton<String>(
                onSelected: (value) => _handleNoteAction(value, note),
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
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          note.isFavorite ? Icons.star : Icons.star_border,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(note.isFavorite ? l10n.removeFavorite : l10n.addFavorite),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(note.isPinned ? l10n.unpin : l10n.pin),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(note.isArchived ? l10n.unarchive : l10n.archive),
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
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
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
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchEverything,
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
                child: StreamBuilder<List<Note>>(
                  stream: database.watchAllNotes(),
                  builder: (context, snapshot) {
                    final notes = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? notes
                        : notes
                              .where(
                                (n) =>
                                    n.title.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ) ||
                                    n.content.toLowerCase().contains(
                                      _searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(filtered[index].title),
                        subtitle: Text(
                          filtered[index].content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/note/${filtered[index].id}');
                        },
                      ),
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

  void _confirmDelete(Note note) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Move to Trash?',
      itemName: note.title,
    );
    if (confirmed) {
      await database.trashNote(note.id);
    }
  }

  void _showFolderPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final folders = await database.getAllFolders();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(l10n.allNotes),
            selected: _selectedFolderId == null,
            onTap: () {
              setState(() => _selectedFolderId = null);
              Navigator.pop(context);
            },
          ),
          ...folders.map(
            (folder) => ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.name),
              selected: _selectedFolderId == folder.id,
              onTap: () {
                setState(() => _selectedFolderId = folder.id);
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.newFolder),
            onTap: () {
              Navigator.pop(context);
              _showCreateFolderDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newFolder),
        content: Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.folderName, border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await database.createFolder(
                  FoldersCompanion.insert(
                    name: controller.text,
                    createdAt: DateTime.now(),
                    modifiedAt: DateTime.now(),
                  ),
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _handleNoteAction(String action, Note note) async {
    switch (action) {
      case 'edit':
        context.push('/note/${note.id}');
        break;
      case 'favorite':
        await database.updateNote(
          NotesCompanion(
            id: Value(note.id),
            isFavorite: Value(!note.isFavorite),
            modifiedAt: Value(DateTime.now()),
          ),
        );
        break;
      case 'pin':
        await database.updateNote(
          NotesCompanion(
            id: Value(note.id),
            isPinned: Value(!note.isPinned),
            modifiedAt: Value(DateTime.now()),
          ),
        );
        break;
      case 'archive':
        await database.updateNote(
          NotesCompanion(
            id: Value(note.id),
            isArchived: Value(!note.isArchived),
            modifiedAt: Value(DateTime.now()),
          ),
        );
        break;
      case 'delete':
        _confirmDelete(note);
        break;
    }
  }
}
