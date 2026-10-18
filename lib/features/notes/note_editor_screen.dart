import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/app_database.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/utilities/app_theme.dart';
import '../../core/utilities/color_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class NoteEditorScreen extends StatefulWidget {
  final int? noteId;
  const NoteEditorScreen({super.key, this.noteId});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _fileStorage = FileStorageService();
  bool _isLoading = true;
  bool _isRecording = false;
  Note? _existingNote;

  int? _folderId;
  String? _folderName;
  bool _isFavorite = false;
  bool _isPinned = false;
  bool _isArchived = false;
  List<Tag> _tags = [];
  String _color = '';
  int _wordCount = 0;
  int _charCount = 0;
  List<_NoteAttachment> _attachments = [];
  List<Tag> _allTags = [];

  String _originalTitle = '';
  String _originalContent = '';
  int? _originalFolderId;
  bool _originalIsFavorite = false;
  bool _originalIsPinned = false;
  bool _originalIsArchived = false;
  String _originalColor = '';
  String _originalAttachments = '[]';
  List<int> _originalTagIds = [];

  @override
  void initState() {
    super.initState();
    _loadNote();
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _loadTags();
  }

  void _onChanged() {
    _updateCounts();
    if (mounted) setState(() {});
  }

  void _updateCounts() {
    final text = _contentController.text;
    _charCount = text.length;
    _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\\s+')).length;
  }

  Future<void> _loadNote() async {
    await _fileStorage.initialize();
    if (widget.noteId != null) {
      try {
        final note = await database.getNote(widget.noteId!);
        _existingNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _folderId = note.folderId;
        _isFavorite = note.isFavorite;
        _isPinned = note.isPinned;
        _isArchived = note.isArchived;
        _color = note.color;
        _originalTitle = note.title;
        _originalContent = note.content;
        _originalFolderId = note.folderId;
        _originalIsFavorite = note.isFavorite;
        _originalIsPinned = note.isPinned;
        _originalIsArchived = note.isArchived;
        _originalColor = note.color;
        _originalAttachments = note.attachments;
        _updateCounts();
        if (_folderId != null) {
          try {
            final folder = await database.getFolder(_folderId!);
            _folderName = folder.name;
          } catch (_) {}
        }
        final noteTags = await database.watchTagsForNote(note.id).first;
        _tags = noteTags;
        _originalTagIds = noteTags.map((t) => t.id).toList();
        try {
          final List<dynamic> json = jsonDecode(note.attachments);
          _attachments = json.map((e) => _NoteAttachment(
            path: e['path'] as String,
            type: _AttachmentType.values.firstWhere(
              (t) => t.name == e['type'],
              orElse: () => _AttachmentType.file,
            ),
            name: e['name'] as String?,
          )).toList();
          final validAttachments = <_NoteAttachment>[];
          for (final a in _attachments) {
            if (await File(a.path).exists()) {
              validAttachments.add(a);
            }
          }
          _attachments = validAttachments;
        } catch (_) {
          _attachments = [];
        }
      } catch (_) {}
    }
    setState(() => _isLoading = false);
    if (widget.noteId == null) _focusNode.requestFocus();
  }

  Future<void> _loadTags() async {
    final tags = await database.watchAllTags().first;
    setState(() => _allTags = tags);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _togglePin() async {
    setState(() => _isPinned = !_isPinned);
  }

  Future<void> _pickFolder() async {
    final folders = await database.getAllFolders();
    if (!mounted) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FolderPickerSheet(folders: folders, currentFolderId: _folderId),
    );
    if (selected != null || selected == 0) {
      setState(() {
        _folderId = selected == 0 ? null : selected;
        _folderName = selected == 0 ? null : folders.firstWhere((f) => f.id == selected).name;
      });
    }
  }

  void _pickTags() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TagPickerSheet(
        allTags: _allTags,
        selectedTags: _tags,
        onUpdated: (updated) {
          setState(() {
            _tags = updated;
          });
        },
      ),
    );
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final text = title.isNotEmpty ? '$title\\n\\n$content' : content;
    if (text.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  Future<void> _duplicateNote() async {
    if (_existingNote == null) return;
    await database.createNote(NotesCompanion.insert(
      title: '${_existingNote!.title} (copy)',
      content: drift.Value(_contentController.text),
      folderId: drift.Value(_folderId),
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note duplicated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _archiveNote() async {
    setState(() => _isArchived = !_isArchived);
  }

  Future<void> _deleteNote() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.unsavedChangesLost),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && _existingNote != null) {
      await database.trashNote(_existingNote!.id);
      if (mounted) context.pop();
    }
  }

  // ── Attachment Methods ──

  Future<void> _attachImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file != null) {
      try {
        await _fileStorage.initialize();
        final persistentPath = await _fileStorage.importFile(file.path);
        setState(() {
          _attachments.add(_NoteAttachment(path: persistentPath, type: _AttachmentType.image));
        });
      } catch (e) {
        debugPrint('[NoteEditor] Failed to persist image: $e');
        // Fallback: try to copy manually to documents dir
        try {
          final dir = await getApplicationDocumentsDirectory();
          final ext = file.path.split('.').last;
          final destPath = '${dir.path}/note_img_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await File(file.path).copy(destPath);
          setState(() {
            _attachments.add(_NoteAttachment(path: destPath, type: _AttachmentType.image));
          });
        } catch (e2) {
          debugPrint('[NoteEditor] Fallback copy also failed: $e2');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to attach image'), behavior: SnackBarBehavior.floating),
            );
          }
        }
      }
    }
  }

  Future<void> _attachFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.isNotEmpty) {
      for (final f in result) {
        if (f.path != null) {
          final ext = f.name.split('.').last.toLowerCase();
          _AttachmentType type;
          if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
            type = _AttachmentType.video;
          } else if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].contains(ext)) {
            type = _AttachmentType.audio;
          } else {
            type = _AttachmentType.file;
          }
          try {
            await _fileStorage.initialize();
            final persistentPath = await _fileStorage.importFile(f.path!, customName: f.name);
            setState(() {
              _attachments.add(_NoteAttachment(path: persistentPath, type: type, name: f.name));
            });
          } catch (e) {
            debugPrint('[NoteEditor] Failed to persist file: $e');
            // Fallback: copy to documents dir
            try {
              final dir = await getApplicationDocumentsDirectory();
              final destPath = '${dir.path}/note_file_${DateTime.now().millisecondsSinceEpoch}_$ext';
              await File(f.path!).copy(destPath);
              setState(() {
                _attachments.add(_NoteAttachment(path: destPath, type: type, name: f.name));
              });
            } catch (e2) {
              debugPrint('[NoteEditor] Fallback file copy also failed: $e2');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to attach ${f.name}'), behavior: SnackBarBehavior.floating),
                );
              }
            }
          }
        }
      }
    }
  }

  Future<void> _attachVideo() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      try {
        await _fileStorage.initialize();
        final persistentPath = await _fileStorage.importFile(file.path);
        setState(() {
          _attachments.add(_NoteAttachment(path: persistentPath, type: _AttachmentType.video));
        });
      } catch (e) {
        debugPrint('[NoteEditor] Failed to persist video: $e');
        try {
          final dir = await getApplicationDocumentsDirectory();
          final ext = file.path.split('.').last;
          final destPath = '${dir.path}/note_vid_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await File(file.path).copy(destPath);
          setState(() {
            _attachments.add(_NoteAttachment(path: destPath, type: _AttachmentType.video));
          });
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to attach video'), behavior: SnackBarBehavior.floating),
            );
          }
        }
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _attachments.add(_NoteAttachment(path: path, type: _AttachmentType.audio, name: 'Voice note'));
        }
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        final tempPath = '${Directory.systemTemp.path}/note_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
          path: tempPath,
        );
        setState(() => _isRecording = true);
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  /// Open a full-screen preview of an attachment
  void _previewAttachment(_NoteAttachment attachment) {
    if (!File(attachment.path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AttachmentPreviewScreen(
          attachment: attachment,
          fileStorage: _fileStorage,
        ),
      ),
    );
  }

  // ── Save ──

  bool get _hasChanges {
    if (_titleController.text.trim() != _originalTitle) return true;
    if (_contentController.text.trim() != _originalContent) return true;
    if (_folderId != _originalFolderId) return true;
    if (_isFavorite != _originalIsFavorite) return true;
    if (_isPinned != _originalIsPinned) return true;
    if (_isArchived != _originalIsArchived) return true;
    if (_color != _originalColor) return true;
    final currentTagIds = _tags.map((t) => t.id).toList()..sort();
    final origIds = List<int>.from(_originalTagIds)..sort();
    if (currentTagIds.length != origIds.length || !_listEquals(currentTagIds, origIds)) return true;
    final currentAttJson = jsonEncode(_attachments.map((a) => {'path': a.path, 'type': a.type.name, 'name': a.name}).toList());
    if (currentAttJson != _originalAttachments) return true;
    return false;
  }

  bool _listEquals(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _attachments.isNotEmpty;

  Future<void> _showBackDialog() async {
    final isNew = _existingNote == null && _hasContent;
    final hasChanges = _existingNote != null && _hasChanges;

    // New note with content → auto-save
    if (isNew) {
      await _saveWithoutPop();
      if (mounted) context.pop();
      return;
    }

    // Existing note with no changes → just pop
    if (!hasChanges) {
      if (mounted) context.pop();
      return;
    }

    // Existing note with changes → show Save/Discard dialog
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.save_alt_rounded, size: 36),
        title: const Text('Unsaved Changes'),
        content: const Text('Do you want to save your changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'save') {
      await _saveWithoutPop();
      if (mounted) context.pop();
    } else if (result == 'discard') {
      if (mounted) context.pop();
    }
  }

  Future<void> _saveWithoutPop() async {
    final title = _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim();
    final content = _contentController.text.trim();

    final attachmentJson = jsonEncode(_attachments.map((a) => {
      'path': a.path,
      'type': a.type.name,
      'name': a.name,
    }).toList());

    if (_existingNote != null) {
      await database.updateNote(NotesCompanion(
        id: drift.Value(_existingNote!.id),
        title: drift.Value(title),
        content: drift.Value(content),
        folderId: drift.Value(_folderId),
        isFavorite: drift.Value(_isFavorite),
        isPinned: drift.Value(_isPinned),
        isArchived: drift.Value(_isArchived),
        color: drift.Value(_color),
        attachments: drift.Value(attachmentJson),
        modifiedAt: drift.Value(DateTime.now()),
      ));
    } else {
      final id = await database.createNote(NotesCompanion.insert(
        title: title,
        content: drift.Value(content),
        folderId: drift.Value(_folderId),
        isFavorite: drift.Value(_isFavorite),
        isPinned: drift.Value(_isPinned),
        isArchived: drift.Value(_isArchived),
        color: drift.Value(_color),
        attachments: drift.Value(attachmentJson),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));
      _existingNote = (await database.getNote(id));
    }
    if (_existingNote != null) {
      await database.removeNoteTags(_existingNote!.id);
      for (final tag in _tags) {
        await database.addNoteTag(_existingNote!.id, tag.id);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final dateStr = _existingNote != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(_existingNote!.modifiedAt)
        : '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _showBackDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _showBackDialog,
          ),
          title: _existingNote != null
              ? Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
              : Text(l10n.newNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
              color: _isFavorite ? Colors.amber : null,
              tooltip: _isFavorite ? l10n.removeFavorite : l10n.addFavorite,
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
              color: _isPinned ? AppTheme.primaryColor : null,
              tooltip: _isPinned ? l10n.unpin : l10n.pin,
              onPressed: _togglePin,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'folder': _pickFolder();
                  case 'tags': _pickTags();
                  case 'archive': _archiveNote();
                  case 'share': _shareNote();
                  case 'duplicate': _duplicateNote();
                  case 'delete': _deleteNote();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'folder', child: Row(children: [const Icon(Icons.folder_outlined, size: 20), const SizedBox(width: 12), Text(l10n.folder)])),
                PopupMenuItem(value: 'tags', child: Row(children: [const Icon(Icons.label_outline_rounded, size: 20), const SizedBox(width: 12), Text('Tags')])),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(_isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(_isArchived ? l10n.unarchive : l10n.archive),
                  ]),
                ),
                PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share_outlined, size: 20), const SizedBox(width: 12), Text(l10n.share)])),
                PopupMenuItem(value: 'duplicate', child: Row(children: [const Icon(Icons.copy_outlined, size: 20), const SizedBox(width: 12), Text('Duplicate')])),
                const PopupMenuDivider(),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 20, color: Colors.red), const SizedBox(width: 12), Text(l10n.delete, style: const TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (_folderName != null || _tags.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_folderName != null)
                      ActionChip(
                        avatar: const Icon(Icons.folder_outlined, size: 16),
                        label: Text(_folderName!, style: const TextStyle(fontSize: 12)),
                        onPressed: _pickFolder,
                        visualDensity: VisualDensity.compact,
                      ),
                    ..._tags.map((tag) => ActionChip(
                      avatar: const Icon(Icons.label_rounded, size: 16),
                      label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                      onPressed: _pickTags,
                      visualDensity: VisualDensity.compact,
                    )),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: EdgeInsets.only(
                        left: isRtl ? 4 : 16,
                        right: isRtl ? 16 : 4,
                        top: 18,
                        bottom: 18,
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: l10n.titleHint,
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 200),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: EdgeInsets.only(
                        left: isRtl ? 4 : 16,
                        right: isRtl ? 16 : 4,
                        top: 18,
                        bottom: 14,
                      ),
                      child: TextField(
                        controller: _contentController,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 10,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 16, height: 1.7),
                        decoration: InputDecoration(
                          hintText: l10n.contentHint,
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Attachments header
                      Row(
                        children: [
                          Icon(Icons.attach_file_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Attachments (${_attachments.length})',
                            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Attachment grid
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_attachments.length, (i) {
                          final a = _attachments[i];
                          return GestureDetector(
                            onTap: () => _previewAttachment(a),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: _buildAttachmentPreview(a, theme),
                                  ),
                                ),
                                // Remove button
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => _removeAttachment(i),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Tap to view indicator
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.open_in_full_rounded, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Bottom Toolbar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _buildAttachButton(Icons.image_rounded, 'Image', _attachImage, theme),
                    _buildAttachButton(Icons.attach_file_rounded, 'File', _attachFile, theme),
                    _buildAttachButton(Icons.videocam_rounded, 'Video', _attachVideo, theme),
                    _buildRecordButton(theme),
                    _buildColorButton(theme),
                    const Spacer(),
                    Icon(Icons.text_fields_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('$_wordCount words • $_charCount chars', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                    if (_isArchived) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.archive_rounded, size: 12, color: Colors.orange), SizedBox(width: 4), Text('Archived', style: TextStyle(fontSize: 11, color: Colors.orange))]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButton(IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Color', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ColorPicker(
              selectedColor: _color,
              onColorSelected: (c) {
                setState(() {
                  _color = c;
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(ThemeData theme) {
    final color = parseColor(_color);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: _showColorPicker,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.palette_rounded,
            size: 22,
            color: color ?? AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: _toggleRecording,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red.withValues(alpha: 0.12) : AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            size: 22,
            color: _isRecording ? Colors.red : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(_NoteAttachment a, ThemeData theme) {
    final fileExists = File(a.path).existsSync();

    switch (a.type) {
      case _AttachmentType.image:
        if (fileExists) {
          return Image.file(
            File(a.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackPreview(a, theme),
          );
        }
        return _buildFallbackPreview(a, theme);
      case _AttachmentType.video:
        return Stack(
          alignment: Alignment.center,
          children: [
            if (fileExists)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/video_placeholder.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                ),
              )
            else
              Icon(Icons.videocam_off_rounded, size: 28, color: theme.colorScheme.error),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: Icon(
                fileExists ? Icons.play_arrow_rounded : Icons.error_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        );
      case _AttachmentType.audio:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fileExists ? Icons.audiotrack_rounded : Icons.volume_off_rounded,
              size: 28,
              color: fileExists ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
            ),
            const SizedBox(height: 4),
            Text(
              a.name ?? 'Audio',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fileExists ? null : theme.colorScheme.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case _AttachmentType.file:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fileExists ? Icons.insert_drive_file_rounded : Icons.broken_image_rounded,
              size: 28,
              color: fileExists ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
            ),
            const SizedBox(height: 4),
            Text(
              a.name ?? 'File',
              style: theme.textTheme.labelSmall?.copyWith(
                color: fileExists ? null : theme.colorScheme.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }

  Widget _buildFallbackPreview(_NoteAttachment a, ThemeData theme) {
    final mimeType = lookupMimeType(a.path);
    final isImage = mimeType?.startsWith('image/') ?? false;
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isImage ? Icons.broken_image_rounded : Icons.insert_drive_file_rounded,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            a.name ?? 'File',
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Attachment Preview Screen (full-screen viewer)
// ═══════════════════════════════════════════════════════════════════════════

class _AttachmentPreviewScreen extends StatelessWidget {
  final _NoteAttachment attachment;
  final FileStorageService fileStorage;

  const _AttachmentPreviewScreen({
    required this.attachment,
    required this.fileStorage,
  });

  String get _fileName {
    if (attachment.name != null) return attachment.name!;
    return attachment.path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(attachment.path);
    final exists = file.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (exists)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(files: [XFile(attachment.path)]),
                );
              },
            ),
          if (exists)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                // Try to open with system default app
                // This requires open_file or similar package
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File: ${attachment.path}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: exists ? _buildPreview(context, theme, file) : _buildNotFound(context, theme),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeData theme, File file) {
    switch (attachment.type) {
      case _AttachmentType.image:
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.file(
              File(attachment.path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildError(theme),
            ),
          ),
        );
      case _AttachmentType.video:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fileName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatFileSize(file.lengthSync()),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Open with system video player
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Video: ${attachment.path}'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play Video'),
              ),
            ],
          ),
        );
      case _AttachmentType.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fileName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatFileSize(file.lengthSync()),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Audio: ${attachment.path}'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play Audio'),
              ),
            ],
          ),
        );
      case _AttachmentType.file:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insert_drive_file_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _fileName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _formatFileSize(file.lengthSync()),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File: ${attachment.path}'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open File'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNotFound(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(          Icons.folder_off_rounded, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            'File not found',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'This file may have been moved or deleted.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            attachment.path,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text('Failed to load image', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

enum _AttachmentType { image, video, audio, file }

class _NoteAttachment {
  final String path;
  final _AttachmentType type;
  final String? name;
  const _NoteAttachment({required this.path, required this.type, this.name});
}

class _FolderPickerSheet extends StatelessWidget {
  final List<Folder> folders;
  final int? currentFolderId;
  const _FolderPickerSheet({required this.folders, this.currentFolderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Select Folder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.folder_off_outlined, color: theme.colorScheme.onSurfaceVariant),
                  title: const Text('No folder'),
                  trailing: currentFolderId == null ? Icon(Icons.check_rounded, color: AppTheme.primaryColor) : null,
                  onTap: () => Navigator.pop(context, 0),
                ),
                ...folders.map((folder) => ListTile(
                  leading: Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
                  title: Text(folder.name),
                  trailing: currentFolderId == folder.id ? Icon(Icons.check_rounded, color: AppTheme.primaryColor) : null,
                  onTap: () => Navigator.pop(context, folder.id),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  final List<Tag> allTags;
  final List<Tag> selectedTags;
  final ValueChanged<List<Tag>> onUpdated;
  const _TagPickerSheet({required this.allTags, required this.selectedTags, required this.onUpdated});

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late List<Tag> _selected;
  final _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedTags);
  }

  @override
  void dispose() { _newTagController.dispose(); super.dispose(); }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_selected.any((t) => t.id == tag.id)) {
        _selected.removeWhere((t) => t.id == tag.id);
      } else {
        _selected.add(tag);
      }
    });
  }

  Future<void> _createTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;
    final id = await database.createTag(TagsCompanion.insert(
      name: name,
      createdAt: DateTime.now(),
    ));
    final allTags = await database.watchAllTags().first;
    final newTag = allTags.firstWhere((t) => t.id == id);
    _selected.add(newTag);
    _newTagController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    decoration: InputDecoration(
                      hintText: 'New tag name',
                      prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _createTag(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _createTag,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Tag>>(
              stream: database.watchAllTags(),
              builder: (context, snapshot) {
                final tags = snapshot.data ?? [];
                if (tags.isEmpty) {
                  return const Center(child: Text('No tags yet. Create one above.'));
                }
                return ListView(
                  children: tags.map((tag) {
                    final isSelected = _selected.any((t) => t.id == tag.id);
                    return ListTile(
                      leading: Icon(Icons.label_rounded, color: isSelected ? AppTheme.primaryColor : theme.colorScheme.onSurfaceVariant),
                      title: Text(tag.name),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
                          : Icon(Icons.radio_button_unchecked, color: theme.colorScheme.outline),
                      onTap: () => _toggleTag(tag),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  widget.onUpdated(_selected);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
