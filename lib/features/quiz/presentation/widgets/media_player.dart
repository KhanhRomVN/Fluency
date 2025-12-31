import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediaPlayer extends StatefulWidget {
  const MediaPlayer({super.key, required this.audioPath, this.title = ''});

  final String audioPath;
  final String title;

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

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // Set the release mode to stop the audio when it finishes
    await _player.setReleaseMode(ReleaseMode.stop);

    // Initialize audio source properly
    await _setSource();

    _durationSubscription = _player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _setSource() async {
    try {
      debugPrint('AG_DEBUG: Loading audio from ${widget.audioPath}');
      // Workaround: Load bytes from rootBundle because AssetSource assumes 'assets/' prefix.
      // The provided path is a full lib path which behaves like a key in rootBundle.
      final bytes = await DefaultAssetBundle.of(context).load(widget.audioPath);
      final audioBytes = bytes.buffer.asUint8List();
      debugPrint('AG_DEBUG: Audio bytes loaded, size: ${audioBytes.length}');
      await _player.setSourceBytes(audioBytes);
      debugPrint('AG_DEBUG: Audio source set successfully');
    } catch (e) {
      debugPrint('AG_DEBUG: Error loading audio source: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.source == null) {
        await _setSource();
      }
      await _player.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColors.background, // Match app bottom nav
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // LEFT: Button Continue/Pause
            InkWell(
              onTap: _togglePlay,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40, // Reduced from 48
                height: 40, // Reduced from 48
                alignment: Alignment.center,
                // Background removed as requested
                child: SvgPicture.asset(
                  _isPlaying
                      ? 'assets/icons/media_pause.svg'
                      : 'assets/icons/media_play.svg',
                  colorFilter: ColorFilter.mode(
                    appColors.primary,
                    BlendMode.srcIn,
                  ),
                  width: 24, // Reduced from 28
                  height: 24, // Reduced from 28
                ),
              ),
            ),
            const SizedBox(width: 12), // Reduced from 16

            // RIGHT: Two lines (Title + Progress)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Line
                  Text(
                    widget.title.isNotEmpty ? widget.title : 'Audio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Progress Line
                  Row(
                    children: [
                      // Current Time
                      Text(
                        _formatDuration(_position),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: appColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(width: 8),
                      // Progress Bar
                      Expanded(
                        child: SizedBox(
                          height:
                              20, // Height for touch target, actual bar is thinner
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                              activeTrackColor: appColors.primary,
                              inactiveTrackColor: appColors.border,
                              thumbColor: appColors.primary,
                              overlayColor:
                                  appColors.primary.withValues(alpha: 0.2),
                              trackShape: const RectangularSliderTrackShape(),
                            ),
                            child: Slider(
                              value: (_position.inMilliseconds / 1000).clamp(
                                  0.0,
                                  (_duration.inMilliseconds / 1000)
                                      .clamp(0.001, double.infinity)),
                              min: 0.0,
                              max: (_duration.inMilliseconds / 1000)
                                  .clamp(0.001, double.infinity),
                              onChanged: (value) {
                                final position = Duration(
                                    milliseconds: (value * 1000).round());
                                _player.seek(position);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Total Duration
                      Text(
                        _formatDuration(_duration),
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
          ],
        ),
      ),
    );
  }
}
