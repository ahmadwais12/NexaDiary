import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class AudioPlayerScreen extends StatefulWidget {
  final int? fileId;
  final String? filePath;
  const AudioPlayerScreen({super.key, this.fileId, this.filePath});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  AppFile? _file;
  bool _isLoading = true;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleMode = false;
  double _playbackSpeed = 1.0;
  Timer? _sleepTimer;
  Duration _sleepRemaining = Duration.zero;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  String get _resolvedPath => widget.filePath ?? _file?.filePath ?? '';
  String get _displayName =>
      _file?.name ?? (widget.filePath?.split('/').last ?? 'Audio');

  @override
  void initState() {
    super.initState();
    _loadAndPlay();
  }

  Future<void> _loadAndPlay() async {
    try {
      if (widget.fileId != null) {
        _file = await database.getFile(widget.fileId!);
      }
      final path = _resolvedPath;
      if (path.isEmpty) throw Exception('No file');

      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();

      // Record play in media history (only for DB-backed files)
      if (_file != null) {
        await database.recordMediaPlay(
          _file!.id,
          'audio',
          0,
          _audioPlayer.duration?.inMilliseconds ?? 0,
        );
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    setState(() => _playbackSpeed = speed);
    Navigator.of(context).pop();
  }

  void _showSpeedSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Playback Speed',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ..._speeds.map((s) => RadioListTile<double>(
                  value: s,
                  groupValue: _playbackSpeed,
                  onChanged: (v) => _setSpeed(v!),
                  activeColor: theme.colorScheme.primary,
                  title: Text(s == 1.0 ? 'Normal' : '${s}x'),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sleep Timer',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.timer_off),
              title: const Text('Off'),
              onTap: () {
                _sleepTimer?.cancel();
                _sleepTimer = null;
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            ...[15, 30, 45, 60].map((minutes) => ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text('$minutes minutes'),
                  onTap: () {
                    _startSleepTimer(Duration(minutes: minutes));
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    setState(() => _sleepRemaining = duration);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _sleepRemaining -= const Duration(seconds: 1));
      if (_sleepRemaining.inSeconds <= 0) {
        _audioPlayer.pause();
        timer.cancel();
        _sleepTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.nowPlaying,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.speed,
                                      color: _playbackSpeed != 1.0 ? theme.colorScheme.primary : null),
                                  onPressed: _showSpeedSheet,
                                ),
                                if (_sleepTimer != null)
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.nightlight, size: 8, color: Colors.white),
                                  ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.timer_outlined,
                                  color: _sleepTimer != null ? theme.colorScheme.primary : null),
                              onPressed: _showSleepTimerSheet,
                            ),
                          ],
                        ),
                      ),

                      // Sleep timer countdown banner
                      if (_sleepTimer != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.nightlight_round, size: 16),
                              const SizedBox(width: 8),
                              Text('Sleep in ${_formatDuration(_sleepRemaining)}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Album art with gradient background
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                              theme.colorScheme.tertiary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Animated rotating vinyl disc
                              StreamBuilder<PlayerState>(
                                stream: _audioPlayer.playerStateStream,
                                builder: (context, snapshot) {
                                  final isPlaying = snapshot.data?.playing ?? false;
                                  return AnimatedRotation(
                                    turns: isPlaying ? 1.0 : 0.0,
                                    duration: const Duration(seconds: 3),
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.grey.shade900,
                                            Colors.grey.shade800,
                                            Colors.grey.shade900,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Center disc hole
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 30,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title and artist
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              _displayName,
                              style: theme.textTheme.titleLarge,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress bar
                      StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = _audioPlayer.duration ??
                              Duration.zero;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                            enabledThumbRadius: 6),
                                    overlayShape:
                                        const RoundSliderOverlayShape(
                                            overlayRadius: 14),
                                    activeTrackColor:
                                        theme.colorScheme.primary,
                                    inactiveTrackColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                    thumbColor:
                                        theme.colorScheme.primary,
                                  ),
                                  child: Slider(
                                    value: position.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                            0,
                                            duration.inMilliseconds
                                                .toDouble()),
                                    max: duration.inMilliseconds
                                        .toDouble(),
                                    onChanged: (value) {
                                      _audioPlayer.seek(
                                        Duration(
                                            milliseconds: value.toInt()),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              _shuffleMode
                                  ? Icons.shuffle
                                  : Icons.shuffle,
                              color: _shuffleMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _shuffleMode = !_shuffleMode;
                              });
                              _audioPlayer.setShuffleModeEnabled(
                                  _shuffleMode);
                            },
                          ),
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () => _audioPlayer.seekToPrevious(),
                          ),
                          // Play/Pause
                          StreamBuilder<PlayerState>(
                            stream: _audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final isPlaying =
                                  playerState?.playing ?? false;
                              return GestureDetector(
                                onTap: () {
                                  if (isPlaying) {
                                    _audioPlayer.pause();
                                  } else {
                                    _audioPlayer.play();
                                  }
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary,
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color:
                                        theme.colorScheme.onPrimary,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(Icons.skip_next),
                            onPressed: () => _audioPlayer.seekToNext(),
                          ),
                          IconButton(
                            icon: Icon(
                              _loopMode == LoopMode.off
                                  ? Icons.repeat
                                  : _loopMode == LoopMode.one
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                              color: _loopMode != LoopMode.off
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _loopMode = _loopMode == LoopMode.off
                                    ? LoopMode.one
                                    : _loopMode == LoopMode.one
                                        ? LoopMode.all
                                        : LoopMode.off;
                              });
                              _audioPlayer.setLoopMode(_loopMode);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Bottom controls (favorite, share, info)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_file != null)
                              IconButton(
                                icon: Icon(_file!.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border),
                                color: _file!.isFavorite ? Colors.red : null,
                                onPressed: () {
                                  database.updateFile(
                                    AppFilesCompanion(
                                      id: drift.Value(_file!.id),
                                      isFavorite: drift.Value(!_file!.isFavorite),
                                    ),
                                  );
                                  setState(() {});
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () async {
                                final path = _resolvedPath;
                                if (path.isNotEmpty) {
                                  await Share.shareXFiles([XFile(path)]);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: _showFileInfo,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showFileInfo() async {
    final path = _resolvedPath;
    if (path.isEmpty) return;

    final file = File(path);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    final duration = _audioPlayer.duration ?? Duration.zero;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('File Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _infoRow('Name', _displayName),
              _infoRow('Size', _formatSize(size)),
              _infoRow('Duration', _formatDuration(duration)),
              _infoRow('Speed', _playbackSpeed == 1.0 ? 'Normal' : '${_playbackSpeed}x'),
              if (_loopMode != LoopMode.off)
                _infoRow('Loop', _loopMode == LoopMode.one ? 'Repeat One' : 'Repeat All'),
              if (_sleepTimer != null)
                _infoRow('Sleep Timer', _formatDuration(_sleepRemaining)),
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
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
