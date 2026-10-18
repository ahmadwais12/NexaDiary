import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

import '../../core/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.media),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.photo_library), text: AppLocalizations.of(context)!.images),
            Tab(icon: Icon(Icons.video_library), text: AppLocalizations.of(context)!.videos),
            Tab(icon: Icon(Icons.music_note), text: AppLocalizations.of(context)!.audio),
            Tab(icon: Icon(Icons.queue_music), text: AppLocalizations.of(context)!.playlists),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ImageTab(),
          _VideoTab(),
          _AudioTab(),
          _PlaylistTab(),
        ],
      ),
    );
  }
}

// --- Image Tab ---
class _ImageTab extends StatelessWidget {
  const _ImageTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppFile>>(
      stream: database.watchAllFiles(),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        final images = files
            .where((f) => (lookupMimeType(f.filePath) ?? '').startsWith('image/'))
            .toList();

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noImagesYet, style: TextStyle(color: Colors.grey)),
                Text(AppLocalizations.of(context)!.importImagesHint,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _ImageTile(file: image);
          },
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final AppFile file;
  const _ImageTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/media/image/${file.id}');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Video Tab ---
class _VideoTab extends StatelessWidget {
  const _VideoTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppFile>>(
      stream: database.watchAllFiles(),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        final videos = files
            .where((f) => (lookupMimeType(f.filePath) ?? '').startsWith('video/'))
            .toList();

        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noVideosYet, style: TextStyle(color: Colors.grey)),
                Text(AppLocalizations.of(context)!.importVideosHint,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.videocam),
                ),
                title: Text(
                  video.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatSize(video.size)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () => context.push('/media/video/${video.id}'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Audio Tab ---
class _AudioTab extends StatelessWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppFile>>(
      stream: database.watchAllFiles(),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        final audio = files
            .where((f) => (lookupMimeType(f.filePath) ?? '').startsWith('audio/'))
            .toList();

        if (audio.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noAudioFilesYet,
                    style: TextStyle(color: Colors.grey)),
                Text(AppLocalizations.of(context)!.importAudioHint,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: audio.length,
          itemBuilder: (context, index) {
            final file = audio[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.music_note),
                ),
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatSize(file.size)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () => context.push('/media/audio/${file.id}'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Playlist Tab ---
class _PlaylistTab extends StatelessWidget {
  const _PlaylistTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Playlist>>(
      stream: database.watchAllPlaylists(),
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.queue_music, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noPlaylistsYet,
                    style: TextStyle(color: Colors.grey)),
                Text(AppLocalizations.of(context)!.createPlaylistHint,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                leading: const CircleAvatar(
                  child: Icon(Icons.queue_music),
                ),
                title: Text(playlist.name),
                subtitle: Text(playlist.description.isNotEmpty
                    ? playlist.description
                    : 'No description'),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {},
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
