import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../main.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final String? singleFilePath;
  final int? fileId;

  const ImageViewerScreen({
    super.key,
    this.assets = const [],
    this.initialIndex = 0,
    this.singleFilePath,
    this.fileId,
  });

  /// Convenience constructor when opening a single file path (from workspace)
  const ImageViewerScreen.single({
    super.key,
    required String filePath,
  })  : assets = const [],
        initialIndex = 0,
        singleFilePath = filePath,
        fileId = null;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  double _rotation = 0;
  bool _showUI = true;

  // Single file path mode
  String? _loadedFilePath;
  String? get _singleFilePath => widget.singleFilePath ?? _loadedFilePath;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // Resolve workspace file by id when no direct path was provided
    if (widget.fileId != null) {
      database.getFile(widget.fileId!).then((f) {
        if (mounted) setState(() => _loadedFilePath = f.filePath);
      }).catchError((_) {});
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  void _rotateImage() {
    setState(() => _rotation = (_rotation + 90) % 360);
  }

  AssetEntity? get _currentAsset {
    if (_singleFilePath != null) return null;
    if (widget.assets.isEmpty) return null;
    if (_currentIndex >= widget.assets.length) return null;
    return widget.assets[_currentIndex];
  }

  Future<void> _shareImage() async {
    if (_singleFilePath != null) {
      await Share.shareXFiles([XFile(_singleFilePath!)]);
      return;
    }
    final asset = _currentAsset;
    if (asset == null) return;
    final file = await asset.originFile;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _deleteImage() async {
    final asset = _currentAsset;
    if (asset == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will permanently remove this image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PhotoManager.editor.deleteWithIds([asset.id]);
      if (mounted) {
        if (widget.assets.length <= 1) {
          Navigator.pop(context);
        } else {
          setState(() {
            widget.assets.removeAt(_currentIndex);
            if (_currentIndex >= widget.assets.length) {
              _currentIndex = widget.assets.length - 1;
            }
          });
          _pageController.jumpToPage(_currentIndex);
        }
      }
    }
  }

  Future<void> _downloadToDevice() async {
    final path = _singleFilePath;
    if (path != null) {
      // For single file, just share it
      await Share.shareXFiles([XFile(path)]);
      return;
    }
    final asset = _currentAsset;
    if (asset == null) return;
    // Save to device using the origin file
    final file = await asset.originFile;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared image')),
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isSingleFile = _singleFilePath != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isSingleFile ? _buildSingleFileBody() : _buildGalleryBody(),
    );
  }

  Widget _buildSingleFileBody() {
    return GestureDetector(
      onTap: _toggleUI,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Transform.rotate(
              angle: _rotation * pi / 180,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.file(
                  File(_singleFilePath!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          if (_showUI) ...[
            _buildTopBar(_singleFilePath!.split('/').last),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryBody() {
    return GestureDetector(
      onTap: _toggleUI,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.assets.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _rotation = 0;
              });
            },
            itemBuilder: (context, index) {
              final asset = widget.assets[index];
              return FutureBuilder<File?>(
                future: asset.originFile,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  return Center(
                    child: Transform.rotate(
                      angle: _rotation * pi / 180,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Image.file(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_showUI) ...[
            _buildTopBar(
              _currentAsset?.title ?? 'Image ${_currentIndex + 1}',
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGalleryBottomBar(),
            ),
            // Page indicator
            if (widget.assets.length > 1)
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.assets.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(String title) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                onPressed: _rotateImage,
                tooltip: 'Rotate',
              ),
              if (_currentAsset != null)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: _downloadToDevice,
                  tooltip: 'Save',
                ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareImage,
                tooltip: 'Share',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteImage,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomAction(Icons.rotate_right, 'Rotate', _rotateImage),
                _buildBottomAction(Icons.share, 'Share', _shareImage),
                _buildBottomAction(Icons.info_outline, 'Info', _showFileInfo),
                _buildBottomAction(Icons.delete_outline, 'Delete', _deleteImage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryBottomBar() {
    final asset = _currentAsset;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${asset.title ?? 'Image'} • ${_formatDate(asset.createDateTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomAction(Icons.rotate_right, 'Rotate', _rotateImage),
                _buildBottomAction(Icons.share, 'Share', _shareImage),
                _buildBottomAction(Icons.download, 'Save', _downloadToDevice),
                _buildBottomAction(Icons.info_outline, 'Info', _showFileInfo),
                _buildBottomAction(Icons.delete_outline, 'Delete', _deleteImage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  void _showFileInfo() async {
    final asset = _currentAsset;
    if (asset == null) return;

    final file = await asset.originFile;
    final size = file != null ? await file.length() : 0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('File Info',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 16),
              _infoRow('Name', asset.title ?? 'Unknown'),
              _infoRow('Size', _formatSize(size)),
              _infoRow('Date', _formatDate(asset.createDateTime)),
              _infoRow('Type', asset.type == AssetType.video ? 'Video' : 'Image'),
              if (asset.width > 0 && asset.height > 0)
                _infoRow('Resolution', '${asset.width} × ${asset.height}'),
              if (asset.duration > 0)
                _infoRow('Duration', _formatDuration(asset.duration)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
