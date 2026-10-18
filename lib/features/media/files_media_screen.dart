import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/app_database.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/utilities/color_picker.dart';
import '../../core/widgets/delete_confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class FilesMediaScreen extends StatefulWidget {
  const FilesMediaScreen({super.key});

  @override
  State<FilesMediaScreen> createState() => _FilesMediaScreenState();
}

class _FilesMediaScreenState extends State<FilesMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGrid = false;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '${l10n.search}...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(l10n.media),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            Tab(icon: const Icon(Icons.folder_open, size: 20), text: l10n.files),
            Tab(icon: const Icon(Icons.photo_library, size: 20), text: l10n.images),
            Tab(icon: const Icon(Icons.video_library, size: 20), text: l10n.videos),
            Tab(icon: const Icon(Icons.music_note, size: 20), text: l10n.audio),
            Tab(icon: const Icon(Icons.queue_music, size: 20), text: l10n.playlists),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WorkspaceFilesTab(isGrid: _isGrid, searchQuery: _searchQuery),
          _DeviceMediaTab(
            assetType: AssetType.image,
            isGrid: _isGrid,
            searchQuery: _searchQuery,
            emptyTitle: l10n.noImagesYet,
            emptySubtitle: l10n.importImagesHint,
          ),
          _DeviceMediaTab(
            assetType: AssetType.video,
            isGrid: _isGrid,
            searchQuery: _searchQuery,
            emptyTitle: l10n.noVideosYet,
            emptySubtitle: l10n.importVideosHint,
          ),
          _DeviceMediaTab(
            assetType: AssetType.audio,
            isGrid: _isGrid,
            searchQuery: _searchQuery,
            emptyTitle: l10n.noAudioFilesYet,
            emptySubtitle: l10n.importAudioHint,
          ),
          _PlaylistTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'hero_files_media_fab',
        onPressed: () => _importFiles(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.import),
      ),
    );
  }

  Future<void> _importFiles(BuildContext context) async {
    final files = await FilePicker.pickFiles(allowMultiple: true);
    if (files == null || files.isEmpty) return;

    int count = 0;
    final storageService = FileStorageService();
    await storageService.initialize();
    for (final file in files) {
      if (file.path != null) {
        try {
          final newPath = await storageService.importFile(file.path!);
          final mime = lookupMimeType(newPath) ?? 'application/octet-stream';
          final size = await File(newPath).length();
          await database.createFile(
            AppFilesCompanion.insert(
              name: file.name,
              filePath: newPath,
              mimeType: drift.Value(mime),
              size: size,
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
            ),
          );
          count++;
        } catch (_) {}
      }
    }

    if (context.mounted && count > 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importedFiles(count))),
      );
    }
  }
}

// ══════════════════════════════════════════════
// Workspace (imported) files tab — DB-backed
// ══════════════════════════════════════════════

class _WorkspaceFilesTab extends StatelessWidget {
  final bool isGrid;
  final String searchQuery;
  const _WorkspaceFilesTab({required this.isGrid, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<AppFile>>(
      stream: database.watchAllFiles(),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        final filtered = searchQuery.isEmpty
            ? files
            : files.where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(l10n.noFilesYet, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text(l10n.importFiles, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        if (isGrid) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _FileGridItem(file: filtered[index]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _FileListItem(file: filtered[index]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// Device media tab — reads real device storage
// ══════════════════════════════════════════════

class _DeviceMediaTab extends StatefulWidget {
  final AssetType assetType;
  final bool isGrid;
  final String searchQuery;
  final String emptyTitle;
  final String emptySubtitle;

  const _DeviceMediaTab({
    required this.assetType,
    required this.isGrid,
    required this.searchQuery,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  State<_DeviceMediaTab> createState() => _DeviceMediaTabState();
}

class _DeviceMediaTabState extends State<_DeviceMediaTab> {
  static final Map<AssetType, List<AssetEntity>> _cache = {};

  Future<List<AssetEntity>>? _future;
  bool _permissionDenied = false;

  RequestType get _requestType {
    switch (widget.assetType) {
      case AssetType.image:
        return RequestType.image;
      case AssetType.video:
        return RequestType.video;
      case AssetType.audio:
        return RequestType.audio;
      default:
        return RequestType.common;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Serve from cache immediately if available
    if (_cache.containsKey(widget.assetType)) {
      setState(() => _future = Future.value(_cache[widget.assetType]));
    }
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
      final paths = await PhotoManager.getAssetPathList(
        type: _requestType,
        onlyAll: true,
      );
      if (paths.isEmpty) {
        if (mounted) setState(() => _future = Future.value([]));
        return;
      }
      final assets = await paths.first.getAssetListRange(start: 0, end: 2000);
      _cache[widget.assetType] = assets;
      if (mounted) setState(() => _future = Future.value(assets));
    } catch (_) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return _buildPermissionDenied(context);
    }
    return FutureBuilder<List<AssetEntity>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var assets = snapshot.data!;
        if (widget.searchQuery.isNotEmpty) {
          final q = widget.searchQuery.toLowerCase();
          assets = assets.where((a) => (a.title ?? '').toLowerCase().contains(q)).toList();
        }

        if (assets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(widget.emptyTitle, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(widget.emptySubtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: widget.isGrid ? _buildGrid(assets) : _buildList(assets),
        );
      },
    );
  }

  Widget _buildGrid(List<AssetEntity> assets) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: assets.length,
      itemBuilder: (context, index) => _AssetTile(
        key: ValueKey(assets[index].id),
        asset: assets[index],
        isGrid: true,
      ),
    );
  }

  Widget _buildList(List<AssetEntity> assets) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: assets.length,
      itemBuilder: (context, index) => _AssetTile(
        key: ValueKey(assets[index].id),
        asset: assets[index],
        isGrid: false,
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Storage permission needed',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          const Text('Allow access to show your photos, videos and audio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              await PhotoManager.openSetting();
              _refresh();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// ── Device asset tile ──

class _AssetTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isGrid;

  const _AssetTile({super.key, required this.asset, required this.isGrid});

  Future<String?> _resolvePath() async {
    try {
      if (asset.type == AssetType.video) {
        final f = await asset.originFile;
        return f?.path;
      }
      final f = await asset.file;
      return f?.path;
    } catch (_) {
      return null;
    }
  }

  void _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await _resolvePath();
    if (path == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Cannot open this file')));
      return;
    }
    if (!context.mounted) return;
    switch (asset.type) {
      case AssetType.image:
        context.push('/media/image/0?path=${Uri.encodeComponent(path)}');
        break;
      case AssetType.video:
        context.push('/media/video/0?path=${Uri.encodeComponent(path)}');
        break;
      case AssetType.audio:
        context.push('/media/audio/0?path=${Uri.encodeComponent(path)}');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GestureDetector(
        onTap: () => _open(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: asset.type == AssetType.image || asset.type == AssetType.video
                  ? _buildThumbnail()
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(_iconFor(asset.type), size: 32),
                    ),
            ),
            if (asset.type == AssetType.video)
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
              ),
            if (asset.type == AssetType.audio)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, size: 32),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(asset.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
            if (asset.duration > 0)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  color: Colors.black54,
                  child: Text(_formatDuration(asset.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                asset.type == AssetType.image || asset.type == AssetType.video
                    ? _buildThumbnail()
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(_iconFor(asset.type)),
                      ),
                if (asset.type == AssetType.video)
                  const Center(child: Icon(Icons.play_circle_fill, size: 24, color: Colors.white70)),
              ],
            ),
          ),
        ),
        title: Text(asset.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          asset.duration > 0
              ? '${_formatDuration(asset.duration)} · ${_formatDate(asset.createDateTime)}'
              : _formatDate(asset.createDateTime),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        onTap: () => _open(context),
      ),
    );
  }

  Widget _buildThumbnail() {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(256, 256)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.grey.shade300);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }

  IconData _iconFor(AssetType type) {
    switch (type) {
      case AssetType.video:
        return Icons.videocam;
      case AssetType.audio:
        return Icons.music_note;
      case AssetType.image:
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ── Playlist Tab ──

class _PlaylistTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Playlist>>(
      stream: database.watchAllPlaylists(),
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? [];
        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.queue_music, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noPlaylistsYet, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(l10n.createPlaylistHint, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                title: Text(playlist.name),
                subtitle: Text(playlist.description),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// Workspace file items (grid/list + actions)
// ══════════════════════════════════════════════

class _FileGridItem extends StatelessWidget {
  final AppFile file;
  const _FileGridItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final mime = lookupMimeType(file.filePath) ?? '';
    final bgColor = parseColor(file.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: mime.startsWith('image/')
                ? Image.file(File(file.filePath), fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => Icon(_getFileIcon(mime), size: 40))
                : Icon(_getFileIcon(mime), size: 40),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  final AppFile file;
  const _FileListItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mime = lookupMimeType(file.filePath) ?? '';
    final bgColor = parseColor(file.color);
    return Card(
      color: bgColor?.withValues(alpha: 0.12),
      child: InkWell(
        onLongPress: () => _showLongPressMenu(context, file),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(_getFileIcon(mime), size: 28, color: bgColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_formatSize(file.size), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _handleAction(context, v, file),
                icon: Icon(Icons.more_vert_rounded, size: 28, color: Colors.grey.shade600),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'vault', child: Row(children: [const Icon(Icons.lock_outline, size: 20, color: Colors.deepPurple), const SizedBox(width: 12), const Text('Move to Vault')])),
                  PopupMenuItem(value: 'rename', child: Row(children: [const Icon(Icons.edit_outlined, size: 20), const SizedBox(width: 12), Text(l10n.rename)])),
                  PopupMenuItem(value: 'color', child: Row(children: const [Icon(Icons.palette, size: 20), SizedBox(width: 12), Text('Color')])),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 20, color: Colors.red), const SizedBox(width: 12), Text(l10n.delete, style: const TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, AppFile file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: Colors.deepPurple),
                title: const Text('Move to Private Vault'),
                subtitle: Text('Encrypt and hide this file',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _moveToVault(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Rename'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAction(context, 'rename', file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.green),
                title: const Text('Share'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAction(context, 'delete', file);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveToVault(BuildContext context, AppFile file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${file.name}" moved to Private Vault'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }

  void _handleAction(BuildContext context, String action, AppFile file) async {
    final l10n = AppLocalizations.of(context)!;
    if (action == 'delete') {
      _confirmDeleteFile(context, file);
    } else if (action == 'color') {
      _showColorPicker(context, file);
    } else if (action == 'rename') {
      final controller = TextEditingController(text: file.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.rename),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(border: InputBorder.none)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(l10n.rename)),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        await database.updateFile(AppFilesCompanion(
          id: drift.Value(file.id),
          name: drift.Value(newName),
          modifiedAt: drift.Value(DateTime.now()),
        ));
      }
    }
  }

  void _confirmDeleteFile(BuildContext context, AppFile file) async {
    final confirmed = await showDeleteConfirmDialog(
      context: context,
      title: 'Move to Trash?',
      itemName: file.name,
    );
    if (confirmed) {
      await database.trashFile(file.id);
    }
  }

  void _showColorPicker(BuildContext context, AppFile file) {
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
                await database.updateFile(AppFilesCompanion(
                  id: drift.Value(file.id),
                  color: drift.Value(c),
                  modifiedAt: drift.Value(DateTime.now()),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──

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
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
