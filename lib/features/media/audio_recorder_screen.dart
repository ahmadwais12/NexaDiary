import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/database/app_database.dart';
import '../../core/storage/file_storage_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _outputPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.microphonePermissionRequired)),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.microphonePermissionRequired)),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _outputPath = '${dir.path}/recording_$timestamp.m4a';

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _outputPath!,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _duration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() => _duration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (_outputPath != null && mounted) {
      // Save to database
      final file = File(_outputPath!);
      if (await file.exists()) {
        final stat = await file.stat();
        final storageService = FileStorageService();
        await storageService.initialize();

        // Move to audio directory
        final newPath = await storageService.importFile(
          _outputPath!,
          customName: 'Recording ${DateTime.now().toString().substring(0, 16)}',
        );

        await database.createFile(AppFilesCompanion.insert(
          name: 'Recording ${DateTime.now().toString().substring(0, 16)}.m4a',
          filePath: newPath,
          mimeType: const drift.Value('audio/aac'),
          size: stat.size,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.recordingSaved)),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.voiceRecorder),
        actions: [
          if (_isRecording)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _stopRecording,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer display
            Text(
              _formatDuration(_duration),
              style: theme.textTheme.displayMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? (_isPaused ? AppLocalizations.of(context)!.paused : AppLocalizations.of(context)!.recording)
                  : AppLocalizations.of(context)!.readyToRecord,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _isRecording && !_isPaused
                    ? Colors.red
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 48),

            // Recording indicator
            if (_isRecording && !_isPaused)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel / reset
                if (_isRecording)
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await _recorder.stop();
                      _timer?.cancel();
                      setState(() {
                        _isRecording = false;
                        _isPaused = false;
                        _duration = Duration.zero;
                      });
                    },
                  ),

                const SizedBox(width: 24),

                // Main record / pause / resume button
                GestureDetector(
                  onTap: () {
                    if (!_isRecording) {
                      _startRecording();
                    } else if (_isPaused) {
                      _resumeRecording();
                    } else {
                      _pauseRecording();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording && !_isPaused
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    child: Icon(
                      !_isRecording
                          ? Icons.mic
                          : (_isPaused ? Icons.mic : Icons.pause),
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Stop and save
                if (_isRecording)
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.stop_circle),
                    onPressed: _stopRecording,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
