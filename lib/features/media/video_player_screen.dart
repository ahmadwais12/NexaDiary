import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../../core/database/app_database.dart';
import '../../main.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int? fileId;
  final String? filePath;
  const VideoPlayerScreen({super.key, this.fileId, this.filePath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  AppFile? _file;
  bool _isLoading = true;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isLandscape = false;

  // Gesture overlays
  double? _gestureValue; // 0..1 progress for brightness/volume overlay
  String _gestureType = ''; // 'brightness' | 'volume' | 'seek'
  int? _seekDeltaSeconds;

  // VLC-like features
  bool _isOrientationLocked = false;
  BoxFit _fitMode = BoxFit.contain;

  static const List<double> _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0];

  String get _resolvedPath =>
      widget.filePath ?? _file?.filePath ?? '';

  @override
  void initState() {
    super.initState();
    _loadAndPlay();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _loadAndPlay() async {
    try {
      if (widget.fileId != null) {
        _file = await database.getFile(widget.fileId!);
      }
      final path = _resolvedPath;
      if (path.isEmpty) throw Exception('No file');

      _controller = VideoPlayerController.file(File(path));
      await _controller!.initialize();
      _controller!.addListener(_onVideoUpdate);

      if (mounted) {
        setState(() => _isLoading = false);
        _controller!.play();
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  Future<void> _toggleFullscreen() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() => _isLandscape = !_isLandscape);
  }

  void _setSpeed(double speed) {
    _controller!.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
    Navigator.of(context).pop();
  }

  void _showSpeedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Playback Speed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ..._speeds.map((s) => RadioListTile<double>(
                  value: s,
                  groupValue: _playbackSpeed,
                  onChanged: (v) => _setSpeed(v!),
                  activeColor: Theme.of(context).colorScheme.primary,
                  title: Text(s == 1.0 ? 'Normal' : '${s}x',
                      style: const TextStyle(color: Colors.white)),
                )),
          ],
        ),
      ),
    );
  }

  // ── VLC-like features ──

  void _toggleOrientationLock() {
    setState(() => _isOrientationLocked = !_isOrientationLocked);
    if (_isOrientationLocked) {
      final current = _isLandscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp];
      SystemChrome.setPreferredOrientations(current);
    } else {
      SystemChrome.setPreferredOrientations([]); // Allow auto-rotate
    }
  }

  void _showFitModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aspect Ratio',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _buildFitOption('Contain', Icons.fit_screen, BoxFit.contain),
            _buildFitOption('Fill', Icons.fullscreen, BoxFit.fill),
            _buildFitOption('Fit Width', Icons.swap_horiz, BoxFit.fitWidth),
            _buildFitOption('Fit Height', Icons.swap_vert, BoxFit.fitHeight),
            _buildFitOption('Cover', Icons.zoom_out_map, BoxFit.cover),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFitOption(String label, IconData icon, BoxFit mode) {
    return ListTile(
      leading: Icon(icon, color: _fitMode == mode ? Theme.of(context).colorScheme.primary : Colors.white),
      title: Text(label, style: TextStyle(
        color: _fitMode == mode ? Theme.of(context).colorScheme.primary : Colors.white,
        fontWeight: _fitMode == mode ? FontWeight.bold : FontWeight.normal,
      )),
      trailing: _fitMode == mode ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _fitMode = mode);
        Navigator.pop(context);
      },
    );
  }

  // ── Gestures ──

  void _onVerticalDragStart(DragStartDetails details) {
    final width = context.size?.width ?? 1;
    _gestureType = details.localPosition.dx < width / 2 ? 'brightness' : 'volume';
    if (_gestureType == 'brightness') {
      ScreenBrightness().application.then((v) {
        if (mounted) {
          setState(() => _brightness = v.clamp(0.0, 1.0));
        }
      });
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final height = context.size?.height ?? 1;
    final delta = -details.delta.dy / (height * 0.7);

    if (_gestureType == 'brightness') {
      _brightness = (_brightness + delta).clamp(0.05, 1.0);
      ScreenBrightness().setApplicationScreenBrightness(_brightness);
      setState(() => _gestureValue = _brightness);
    } else {
      final current = _controller!.value.volume;
      final newVolume = (current + delta).clamp(0.0, 1.0);
      _controller!.setVolume(newVolume);
      setState(() => _gestureValue = newVolume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() => _gestureValue = null);
  }

  double _brightness = 1.0;

  void _seekBy(int seconds) {
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;
    var newPos = position + Duration(seconds: seconds);
    if (newPos.isNegative) newPos = Duration.zero;
    if (newPos > duration) newPos = duration;
    _controller!.seekTo(newPos);
    setState(() => _seekDeltaSeconds = seconds);
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekDeltaSeconds = null);
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    ScreenBrightness().resetApplicationScreenBrightness();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: (_showControls && !_isLandscape)
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(
                _file?.name ?? (widget.filePath != null ? widget.filePath!.split('/').last : ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isOrientationLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
                    color: _isOrientationLocked ? Colors.amber : Colors.white,
                  ),
                  onPressed: _toggleOrientationLock,
                  tooltip: _isOrientationLocked ? 'Unlock rotation' : 'Lock rotation',
                ),
                IconButton(icon: const Icon(Icons.aspect_ratio), onPressed: _showFitModeSheet),
                IconButton(icon: Icon(Icons.speed, color: _playbackSpeed == 1.0 ? Colors.white : Colors.amber), onPressed: _showSpeedSheet),
                IconButton(icon: const Icon(Icons.fullscreen), onPressed: _toggleFullscreen),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _controller == null || !_controller!.value.isInitialized
              ? const Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 64))
              : GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTapDown: (d) {
                    final width = context.size?.width ?? 1;
                    _seekBy(d.localPosition.dx < width / 2 ? -10 : 10);
                  },
                  onVerticalDragStart: _onVerticalDragStart,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: FittedBox(
                          fit: _fitMode,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),

                      // Buffering indicator
                      if (!_controller!.value.isPlaying &&
                          _controller!.value.isBuffering)
                        const CircularProgressIndicator(color: Colors.white),

                      // Double-tap seek ripple indicator
                      if (_seekDeltaSeconds != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _seekDeltaSeconds! > 0 ? Icons.forward_10 : Icons.replay_10,
                                color: Colors.white,
                                size: 48,
                              ),
                              Text('${_seekDeltaSeconds! > 0 ? '+' : ''}${_seekDeltaSeconds}s',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      // Brightness/Volume gesture overlay
                      if (_gestureValue != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _gestureType == 'brightness'
                                    ? Icons.brightness_high
                                    : _controller!.value.volume > 0
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: LinearProgressIndicator(
                                  value: _gestureValue,
                                  color: Colors.white,
                                  backgroundColor: Colors.white30,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${(_gestureValue! * 100).round()}%',
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),

                      // Big play/pause when controls hidden
                      if (!_showControls && _seekDeltaSeconds == null && _gestureValue == null)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller!.value.isPlaying
                                    ? _controller!.pause()
                                    : _controller!.play();
                              });
                              _startHideControlsTimer();
                            },
                          ),
                        ),

                      // Controls overlay
                      if (_showControls)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildControlsOverlay(),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildControlsOverlay() {
    final controller = _controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
            max: duration.inMilliseconds.toDouble(),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Colors.white30,
            onChanged: (value) => _controller!.seekTo(Duration(milliseconds: value.toInt())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(_formatDuration(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: Text('-${_formatDuration(duration - position)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.replay_10, color: Colors.white), onPressed: () => _seekBy(-10)),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  });
                  if (controller.value.isPlaying) _startHideControlsTimer();
                },
              ),
              IconButton(icon: const Icon(Icons.forward_10, color: Colors.white), onPressed: () => _seekBy(10)),
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                onSelected: _setSpeed,
                itemBuilder: (context) => _speeds.map((s) => PopupMenuItem(value: s, child: Text(s == 1.0 ? 'Normal' : '${s}x'))).toList(),
                icon: Badge(
                  isLabelVisible: _playbackSpeed != 1.0,
                  label: Text('${_playbackSpeed}x', style: const TextStyle(fontSize: 9, color: Colors.white)),
                  child: const Icon(Icons.speed, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
          if (_isLandscape) const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
