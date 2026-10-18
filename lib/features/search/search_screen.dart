import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/utilities/responsive_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _query.isEmpty
            ? Text(l10n.favorites, style: const TextStyle(fontWeight: FontWeight.w700))
            : TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchEverything,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          if (_query.isEmpty)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                // Show search field
                setState(() => _query = ' ');
              },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final r = ResponsiveUtils(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Column(
                children: [
                  // Filter chips
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      children: [
                  _buildFilterChip(l10n.all, 'all', Icons.star_rounded, Colors.amber),
                  _buildFilterChip(l10n.notes, 'notes', Icons.note_rounded, Colors.blue),
                  _buildFilterChip(l10n.files, 'files', Icons.folder_rounded, Colors.purple),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _query.isNotEmpty && _query != ' '
                        ? _buildSearchResults()
                        : _buildFavoritesList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, Color color) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(label),
        selected: selected,
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView(
      children: [
        if (_filter == 'all' || _filter == 'notes') _buildFavoriteNotesSection(),
        if (_filter == 'all' || _filter == 'files') _buildFavoriteFilesSection(),
      ],
    );
  }

  Widget _buildFavoriteNotesSection() {
    return FutureBuilder<List<Note>>(
      future: database.getAllNotes(),
      builder: (context, snapshot) {
        final allNotes = snapshot.data ?? [];
        final favorites = allNotes.where((n) => n.isFavorite).toList();
        if (favorites.isEmpty) return const SizedBox.shrink();
        return _buildSection(
          title: 'Favorite Notes',
          count: favorites.length,
          icon: Icons.note_rounded,
          color: Colors.blue,
          children: favorites.map((note) => _buildNoteTile(context, note)).toList(),
        );
      },
    );
  }

  Widget _buildFavoriteFilesSection() {
    return FutureBuilder<List<AppFile>>(
      future: database.getAllFiles(),
      builder: (context, snapshot) {
        final allFiles = snapshot.data ?? [];
        final favorites = allFiles.where((f) => f.isFavorite).toList();
        if (favorites.isEmpty) return const SizedBox.shrink();
        return _buildSection(
          title: 'Favorite Files',
          count: favorites.length,
          icon: Icons.folder_rounded,
          color: Colors.purple,
          children: favorites.map((file) => _buildFileTile(context, file)).toList(),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildNoteTile(BuildContext context, Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.06),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.note_rounded, color: Colors.blue, size: 20),
        ),
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 18),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d').format(note.modifiedAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        onTap: () => context.push('/note/${note.id}'),
      ),
    );
  }

  Widget _buildFileTile(BuildContext context, AppFile file) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.06),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getFileIcon(file.mimeType), color: Colors.purple, size: 20),
        ),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _formatFileSize(file.size),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 18),
      ),
    );
  }

  // ═══════════ Search Results ═══════════

  Widget _buildSearchResults() {
    return ListView(
      children: [
        if (_filter == 'all' || _filter == 'notes') _buildSearchNotesSection(),
        if (_filter == 'all' || _filter == 'files') _buildSearchFilesSection(),
      ],
    );
  }

  Widget _buildSearchNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Note>>(
      future: database.searchAllNotes(_query),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        if (notes.isEmpty) return const SizedBox.shrink();
        return _buildSection(
          title: l10n.notes,
          count: notes.length,
          icon: Icons.note_rounded,
          color: Colors.blue,
          children: notes.map((note) => _buildNoteTile(context, note)).toList(),
        );
      },
    );
  }

  Widget _buildSearchFilesSection() {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<AppFile>>(
      future: database.searchAllFiles(_query),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        if (files.isEmpty) return const SizedBox.shrink();
        return _buildSection(
          title: l10n.files,
          count: files.length,
          icon: Icons.folder_rounded,
          color: Colors.purple,
          children: files.map((file) => _buildFileTile(context, file)).toList(),
        );
      },
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image_rounded;
    if (mimeType.startsWith('video/')) return Icons.videocam_rounded;
    if (mimeType.startsWith('audio/')) return Icons.music_note_rounded;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
