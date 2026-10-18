import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Manages the app's local file storage architecture.
///
/// Files are stored on the filesystem by type, while metadata lives in SQLite.
/// Structure:
/// ```
/// app_storage/
/// ├── images/
/// ├── videos/
/// ├── audio/
/// ├── music/
/// ├── documents/
/// ├── attachments/
/// └── vault/
/// ```
class FileStorageService {
  static const _uuid = Uuid();

  late final String _basePath;

  String get basePath => _basePath;

  /// Initialize the storage directories.
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _basePath = p.join(appDir.path, 'app_storage');

    for (final dir in _subdirectories) {
      final directory = Directory(p.join(_basePath, dir));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  static const List<String> _subdirectories = [
    'images',
    'videos',
    'audio',
    'music',
    'documents',
    'attachments',
    'vault',
  ];

  /// Get the appropriate subdirectory for a given MIME type.
  String getDirectoryForMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'images';
    if (mimeType.startsWith('video/')) return 'videos';
    if (mimeType == 'audio/mpeg' || mimeType == 'audio/mp3') return 'music';
    if (mimeType.startsWith('audio/')) return 'audio';
    // Everything else goes to documents
    return 'documents';
  }

  /// Get the full path for a subdirectory.
  String getDirectoryPath(String subDir) => p.join(_basePath, subDir);

  /// Import a file from an external path into the app storage.
  ///
  /// Returns the new path within app storage.
  Future<String> importFile(String sourcePath, {String? customName}) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final mimeType = lookupMimeType(sourcePath) ?? 'application/octet-stream';
    final subDir = getDirectoryForMimeType(mimeType);
    final extension = p.extension(sourcePath);
    final fileName = customName != null
        ? '$customName$extension'
        : '${_uuid.v4()}$extension';

    final destPath = p.join(_basePath, subDir, fileName);
    await sourceFile.copy(destPath);

    return destPath;
  }

  /// Import a file for the private vault.
  Future<String> importToVault(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final extension = p.extension(sourcePath);
    final fileName = '${_uuid.v4()}$extension';
    final destPath = p.join(_basePath, 'vault', fileName);
    await sourceFile.copy(destPath);

    return destPath;
  }

  /// Delete a file from app storage.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Move a file to a new location within app storage.
  Future<String> moveFile(String currentPath, String subDir) async {
    final file = File(currentPath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', currentPath);
    }

    final extension = p.extension(currentPath);
    final fileName = '${_uuid.v4()}$extension';
    final destPath = p.join(_basePath, subDir, fileName);

    // Copy then delete to handle cross-partition moves
    await file.copy(destPath);
    await file.delete();

    return destPath;
  }

  /// Get the total storage usage in bytes.
  Future<int> getStorageUsage() async {
    int totalSize = 0;
    final baseDir = Directory(_basePath);
    if (await baseDir.exists()) {
      await for (final entity in baseDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    }
    return totalSize;
  }

  /// Get storage usage breakdown by category.
  Future<Map<String, int>> getStorageBreakdown() async {
    final breakdown = <String, int>{};
    for (final subDir in _subdirectories) {
      final dir = Directory(p.join(_basePath, subDir));
      int dirSize = 0;
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            dirSize += stat.size;
          }
        }
      }
      breakdown[subDir] = dirSize;
    }
    return breakdown;
  }

  /// Get a temporary file path for caching.
  Future<String> getTempPath(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return p.join(tempDir.path, 'workspace_cache', fileName);
  }

  /// Copy a file to a temporary location (for sharing, opening, etc.).
  Future<String> copyToTemp(String sourcePath, {String? fileName}) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', sourcePath);
    }

    final name = fileName ?? p.basename(sourcePath);
    final tempPath = await getTempPath(name);

    // Ensure temp directory exists
    final tempDir = Directory(p.dirname(tempPath));
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return (await file.copy(tempPath)).path;
  }

  /// Clear all cached temporary files.
  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, 'workspace_cache'));
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Check if a file exists on disk.
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}
