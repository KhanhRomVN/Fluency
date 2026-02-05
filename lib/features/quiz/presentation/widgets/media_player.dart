import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:universal_io/io.dart';

class MediaPlayer extends StatefulWidget {
  const MediaPlayer({
    required this.audioPath,
    super.key,
    this.title = '',
    this.externalPlayer,
    this.segmentStart,
    this.segmentEnd,
    this.keyTimestamps,
  });

  final String audioPath;
  final String title;
  final AudioPlayer? externalPlayer;
  final double? segmentStart;
  final double? segmentEnd;
  final List<String>? keyTimestamps;

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  late AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<PlayerState>? _playerStateChangeSubscription;

  List<double>? _parsedKeyTimestamps;

  bool get _isPlaying => _playerState == PlayerState.playing;

  double _parseTime(String time) {
    if (!time.contains(':')) return 0;
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        return int.parse(parts[0]) * 60 + double.parse(parts[1]);
      } else if (parts.length == 3) {
        return int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            double.parse(parts[2]);
      }
    } catch (e) {
      debugPrint('MediaPlayer: Error parsing time string $time: $e');
    }
    return 0;
  }

  void _handleSkipForward() {
    if (_parsedKeyTimestamps == null || _parsedKeyTimestamps!.isEmpty) return;

    final currentSeconds = _position.inMilliseconds / 1000.0;

    // Find first timestamp > current + 0.5
    final target = _parsedKeyTimestamps!.firstWhere(
      (t) => t > currentSeconds + 0.5,
      orElse: () => -1.0,
    );

    if (target != -1.0) {
      // Check if within segment
      if (widget.segmentEnd != null && target > widget.segmentEnd!) return;
      _player.seek(Duration(milliseconds: (target * 1000).round()));
    }
  }

  void _handleSkipBack() {
    if (_parsedKeyTimestamps == null || _parsedKeyTimestamps!.isEmpty) return;

    final currentSeconds = _position.inMilliseconds / 1000.0;

    // Find first timestamp < current - 1.5
    final target = _parsedKeyTimestamps!.reversed.firstWhere(
      (t) => t < currentSeconds - 1.5,
      orElse: () => -1.0,
    );

    if (target != -1.0) {
      if (widget.segmentStart != null && target < widget.segmentStart!) {
        _player.seek(
            Duration(milliseconds: (widget.segmentStart! * 1000).round()));
      } else {
        _player.seek(Duration(milliseconds: (target * 1000).round()));
      }
    } else if (widget.segmentStart != null) {
      _player
          .seek(Duration(milliseconds: (widget.segmentStart! * 1000).round()));
    } else {
      _player.seek(Duration.zero);
    }
  }

  @override
  void initState() {
    super.initState();
    _parsedKeyTimestamps = widget.keyTimestamps?.map(_parseTime).toList();
    debugPrint(
        'MediaPlayer: Initial keyTimestamps count: ${_parsedKeyTimestamps?.length ?? 0}');
    // Use external player if provided, otherwise create a new one
    _player = widget.externalPlayer ?? AudioPlayer();
    _initAudio();
  }

  @override
  void didUpdateWidget(MediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyTimestamps != oldWidget.keyTimestamps) {
      setState(() {
        _parsedKeyTimestamps = widget.keyTimestamps?.map(_parseTime).toList();
      });
      debugPrint(
          'MediaPlayer: Updated keyTimestamps count: ${_parsedKeyTimestamps?.length ?? 0}');
    }
  }

  Future<void> _initAudio() async {
    // Set the release mode to stop the audio when it finishes
    await _player.setReleaseMode(ReleaseMode.stop);

    // Listen to logs for debugging
    _player.onLog.listen((msg) => debugPrint('AudioPlayer Log: $msg'));

    // Initialize audio source properly
    if (widget.externalPlayer == null) {
      await _setSource();
    } else {
      // If external player is used, source might be set by parent.
      // But we ensure it's set if not playing or if path changed.
      // For simplicity/safety, we can try setting it if state is stopped/completed.
      if (_player.state == PlayerState.stopped ||
          _player.state == PlayerState.completed) {
        await _setSource();
      }
    }

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      debugPrint('Audio duration received: $duration');
      setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      debugPrint('Audio playback completed');
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        _player.onPlayerStateChanged.listen((state) {
      debugPrint('Audio player state changed: $state');
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _setSource() async {
    try {
      debugPrint('Attempting to set source: ${widget.audioPath}');
      // Check if it's a file path (absolute path on device)
      if (widget.audioPath.startsWith('/') ||
          widget.audioPath.contains('course_cache')) {
        final file = File(widget.audioPath);
        if (await file.exists()) {
          await _player.setSource(DeviceFileSource(widget.audioPath));
          debugPrint('Audio source set successfully (DeviceFileSource)');

          // Try to get duration immediately
          final duration = await _player.getDuration();
          if (duration != null) {
            debugPrint('Immediate duration: $duration');
            setState(() => _duration = duration);
          } else {
            debugPrint('Immediate duration is NULL');
          }
          return;
        } else {
          debugPrint('Audio file NOT found at path: ${widget.audioPath}');
          // Diagnostic: List files in the same directory
          try {
            final dir = file.parent;
            if (await dir.exists()) {
              final files = await dir.list().toList();
              debugPrint('Files in ${dir.path}:');
              for (final f in files) {
                debugPrint(' - ${f.path}');
              }
            } else {
              debugPrint('Parent directory does NOT exist: ${dir.path}');
            }
          } catch (e) {
            debugPrint('Error listing directory for diagnostics: $e');
          }
        }
      }

      // Fallback: Try to load as asset
      final bytes = await DefaultAssetBundle.of(context).load(widget.audioPath);
      final audioBytes = bytes.buffer.asUint8List();
      await _player.setSourceBytes(audioBytes);
      debugPrint('Audio source set to asset bytes: ${widget.audioPath}');
    } catch (e) {
      debugPrint('Error setting audio source (${widget.audioPath}): $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();

    // Only dispose if we created it
    if (widget.externalPlayer == null) {
      _player.stop(); // Stop playback before disposing
      _player.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Duration get _effectiveDuration {
    if (widget.segmentStart != null && widget.segmentEnd != null) {
      final segmentLength = widget.segmentEnd! - widget.segmentStart!;
      return Duration(milliseconds: (segmentLength * 1000).round());
    }
    return _duration;
  }

  Duration get _effectivePosition {
    if (widget.segmentStart != null) {
      final relativePosition =
          _position.inMilliseconds / 1000.0 - widget.segmentStart!;
      return Duration(
          milliseconds:
              (relativePosition.clamp(0, double.infinity) * 1000).round());
    }
    return _position;
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.source == null) {
        await _setSource();
      }
      // If we are at the end part of the segment (or full audio), resume normally
      // But if we're at the very end, we might want to reset.
      // Logic from TSX: If at segment end, seek to segment start first.
      if (widget.segmentEnd != null &&
          _position.inMilliseconds / 1000.0 >= widget.segmentEnd! - 0.1) {
        await _player.seek(
            Duration(milliseconds: (widget.segmentStart! * 1000).round()));
      }
      await _player.resume();
    }
  }

  bool get _canSkipForward {
    if (_parsedKeyTimestamps == null || _parsedKeyTimestamps!.isEmpty) {
      return false;
    }
    final currentSeconds = _position.inMilliseconds / 1000.0;
    // Check if there is a timestamp > current + 0.5 within segment
    final target = _parsedKeyTimestamps!.firstWhere(
      (t) => t > currentSeconds + 0.5,
      orElse: () => -1.0,
    );
    if (target == -1.0) return false;
    if (widget.segmentEnd != null && target > widget.segmentEnd!) return false;
    return true;
  }

  bool get _canSkipBack {
    if (_parsedKeyTimestamps == null || _parsedKeyTimestamps!.isEmpty) {
      // Even if no timestamps, we can skip back to start if position > 0.5 (logic below)
      // But button is primarily for "Key Timestamps". If none, maybe disable?
      // Existing logic implies it skips key timestamps.
      // If no key timestamps, user might still want to replay segment?
      // Logic in _handleSkipBack handles case where no target found:
      // "else if (widget.segmentStart != null)" seek to start.
      // So let's allow "skip back" if we are not at the very start (with some buffer).
      return (_position.inMilliseconds / 1000.0) >
          ((widget.segmentStart ?? 0) + 0.5);
    }

    // With timestamps:
    final currentSeconds = _position.inMilliseconds / 1000.0;
    final target = _parsedKeyTimestamps!.reversed.firstWhere(
      (t) => t < currentSeconds - 1.5,
      orElse: () => -1.0,
    );

    if (target != -1.0) return true;

    // If no explicit timestamp before, check if we can go to start
    return currentSeconds > ((widget.segmentStart ?? 0) + 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      // Reduced padding to "move progress bar up" closer to controls?
      // No, user said "nhích progressbar lên 1 chút" -> reduce vertical spacing between rows.
      // Currently padding is 8. Row 1 has padding bottom 0.
      // Maybe reduce container padding to 0 or very small?
      // Or reduce padding between rows? There is no padding between rows.
      // Let's reduce vertical padding overall.
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
      decoration: BoxDecoration(
        color: appColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Control Buttons (Centered)
            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip Back
                  _buildIconButton(
                    onTap: _handleSkipBack,
                    svg: _skipBackSvg,
                    appColors: appColors,
                    size: 18, // Reduced from 20
                    enabled: _canSkipBack,
                  ),
                  const SizedBox(width: 16),
                  // Play/Pause
                  InkWell(
                    onTap: _togglePlay,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32, // Reduced from 36
                      height: 32,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        _isPlaying
                            ? 'assets/icons/media_pause.svg'
                            : 'assets/icons/media_play.svg',
                        colorFilter: ColorFilter.mode(
                          _isPlaying
                              ? Colors.red
                              : appColors.primary, // Red when playing
                          BlendMode.srcIn,
                        ),
                        width: 22, // Slightly reduced from 24
                        height: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Skip Forward
                  _buildIconButton(
                    onTap: _handleSkipForward,
                    svg: _skipForwardSvg,
                    appColors: appColors,
                    size: 18, // Reduced from 20
                    enabled: _canSkipForward,
                  ),
                ],
              ),
            ),

            // Row 2: Timeline (Time - Slider - Duration)
            Row(
              children: [
                Text(
                  _formatDuration(_effectivePosition),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Markers and Custom Track overlay
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: CustomPaint(
                            painter: MarkersPainter(
                              timestamps: _parsedKeyTimestamps ?? [],
                              duration: widget.segmentEnd != null
                                  ? widget.segmentEnd! -
                                      (widget.segmentStart ?? 0)
                                  : _duration.inMilliseconds / 1000.0,
                              segmentStart: widget.segmentStart ?? 0,
                              segmentEnd: widget.segmentEnd,
                              currentPosition:
                                  _effectivePosition.inMilliseconds / 1000.0,
                              markerColor: Colors.white,
                              activeTrackColor: appColors.primary,
                              inactiveTrackColor: appColors.border,
                            ),
                          ),
                        ),
                      ),

                      // Slider (Thumb only, transparent track)
                      SizedBox(
                        height: 14,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: appColors.primary,
                            overlayColor:
                                appColors.primary.withValues(alpha: 0.2),
                            trackShape: const RectangularSliderTrackShape(),
                          ),
                          child: Slider(
                            value: (_effectivePosition.inMilliseconds / 1000)
                                .clamp(
                              0.0,
                              (_effectiveDuration.inMilliseconds / 1000)
                                  .clamp(0.001, double.infinity),
                            ),
                            max: (_effectiveDuration.inMilliseconds / 1000)
                                .clamp(0.001, double.infinity),
                            onChanged: (value) {
                              final seekTime = widget.segmentStart != null
                                  ? widget.segmentStart! + value
                                  : value;
                              final position = Duration(
                                milliseconds: (seekTime * 1000).round(),
                              );
                              _player.seek(position);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_effectiveDuration),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    required String svg,
    required AppColorsExtension appColors,
    double size = 24,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null, // Disable tap if not enabled
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size + 12,
        height: size + 12,
        alignment: Alignment.center,
        child: SvgPicture.string(
          svg,
          colorFilter: ColorFilter.mode(
            enabled
                ? appColors.primary
                : appColors.textSecondary, // Gray if disabled
            BlendMode.srcIn,
          ),
          width: size,
          height: size,
        ),
      ),
    );
  }

  static const String _skipForwardSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-skip-forward-icon lucide-skip-forward"><path d="M21 4v16"/><path d="M6.029 4.285A2 2 0 0 0 3 6v12a2 2 0 0 0 3.029 1.715l9.997-5.998a2 2 0 0 0 .003-3.432z"/></svg>''';
  static const String _skipBackSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-skip-back-icon lucide-skip-back"><path d="M17.971 4.285A2 2 0 0 1 21 6v12a2 2 0 0 1-3.029 1.715l-9.997-5.998a2 2 0 0 1-.003-3.432z"/><path d="M3 20V4"/></svg>''';
}

class MarkersPainter extends CustomPainter {
  final List<double> timestamps;
  final double duration;
  final double segmentStart;
  final double? segmentEnd;
  final double currentPosition; // Add current position for active track
  final Color
      markerColor; // Make this technically 'markerColor' but we use white for markers
  final Color activeTrackColor;
  final Color inactiveTrackColor;

  MarkersPainter({
    required this.timestamps,
    required this.duration,
    required this.segmentStart,
    this.segmentEnd,
    required this.currentPosition,
    required this.markerColor,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration <= 0) return;

    // 1. Draw Inactive Track
    final trackHeight = 3.0; // Match TSX h-[3px]
    final trackRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: trackHeight);

    final inactivePaint = Paint()
      ..color = inactiveTrackColor
      ..style = PaintingStyle.fill;

    // Use RRect for rounded-full look
    canvas.drawRRect(
        RRect.fromRectAndRadius(trackRect, Radius.circular(trackHeight / 2)),
        inactivePaint);

    // 2. Draw Active Track
    // Calculate width relative to duration
    // Note: currentPosition is already relative (effectivePosition), no need to subtract segmentStart again
    final progressRatio = currentPosition / duration;
    final clampedRatio = progressRatio.clamp(0.0, 1.0);
    final activeWidth = size.width * clampedRatio;

    if (activeWidth > 0) {
      final activeRect = Rect.fromLTWH(
          0, (size.height - trackHeight) / 2, activeWidth, trackHeight);
      final activePaint = Paint()
        ..color = activeTrackColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
          RRect.fromRectAndRadius(activeRect, Radius.circular(trackHeight / 2)),
          activePaint);
    }

    // 3. Draw Markers (White, z-index 10 in TSX)
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Optional shadow
    final shadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (final t in timestamps) {
      if (segmentEnd != null && (t < segmentStart || t > segmentEnd!)) continue;

      final relativeT = t - segmentStart;
      final x = (relativeT / duration) * size.width;

      if (x < 0 || x > size.width) continue;

      // Draw vertical line inside the track
      // Width 1.5px, Height matches trackHeight (3.0)
      final rect = Rect.fromCenter(
          center: Offset(x, size.height / 2), width: 1.5, height: trackHeight);

      // Draw shadow first
      canvas.drawRect(rect, shadowPaint);

      // Draw main line
      canvas.drawRect(rect, markerPaint);
    }
  }

  @override
  bool shouldRepaint(MarkersPainter oldDelegate) {
    return oldDelegate.timestamps != timestamps ||
        oldDelegate.duration != duration ||
        oldDelegate.segmentStart != segmentStart ||
        oldDelegate.segmentEnd != segmentEnd ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.activeTrackColor != activeTrackColor ||
        oldDelegate.inactiveTrackColor != inactiveTrackColor;
  }
}
