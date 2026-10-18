import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mime/mime.dart';
import 'dart:io' as io;

import '../../core/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fileBrowser)),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.file_upload_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(l10n.importFilesDescription, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(l10n.filesStoredLocal, style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () => _pickFiles(context), icon: const Icon(Icons.add), label: Text(l10n.pickFiles)),
      ])),
    );
  }

  void _pickFiles(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles();
      if (result.isNotEmpty) {
        int count = 0;
        for (final platformFile in result) {
          if (platformFile.path != null) {
            final file = io.File(platformFile.path!);
            final mimeType = lookupMimeType(platformFile.path!) ?? '';
            final size = await file.length();
            await database.createFile(AppFilesCompanion.insert(
              name: platformFile.name, filePath: platformFile.path!, mimeType: drift.Value(mimeType), size: size,
              createdAt: DateTime.now(), modifiedAt: DateTime.now()));
            count++;
          }
        }
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.importedFiles(count))));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }
}
