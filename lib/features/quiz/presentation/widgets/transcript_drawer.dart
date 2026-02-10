import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/domain/entities/transcript_model.dart';
import 'package:fluency/features/quiz/presentation/widgets/media_player.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TranscriptDrawer extends StatefulWidget {
  const TranscriptDrawer({
    required this.isOpen,
    required this.onClose,
    super.key,
    this.transcriptPath,
    this.audioPath,
    this.audioPlayer,
    this.onWordLongPress,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String? transcriptPath;
  final String? audioPath;
  final AudioPlayer? audioPlayer;
  final void Function(String)? onWordLongPress;

  @override
  State<TranscriptDrawer> createState() => _TranscriptDrawerState();
}

class _TranscriptDrawerState extends State<TranscriptDrawer> {
  TranscriptData? _transcriptData;
  bool _isLoading = false;
  String? _error;
  String? _activeDialogueId;
  Duration _currentTime = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;

  // Track active segment for auto-scroll
  final GlobalKey _activeSegmentKey = GlobalKey();
  int _lastActiveSegmentIndex = -1;

  @override
  void didUpdateWidget(TranscriptDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && widget.transcriptPath != oldWidget.transcriptPath) {
      _loadTranscript();
    }
    // Handle audio player changes if necessary, though unlikely to change instance
  }

  @override
  void initState() {
    super.initState();
    if (widget.isOpen && widget.transcriptPath != null) {
      _loadTranscript();
    }
    _initAudioListener();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _initAudioListener() {
    if (widget.audioPlayer != null) {
      _positionSubscription = widget.audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) {
          setState(() {
            _currentTime = p;
          });
          _checkAutoScroll();
        }
      });
    }
  }

  void _checkAutoScroll() {
    if (_transcriptData == null) return;

    final currentSeconds = _currentTime.inSeconds;
    var activeIndex = -1;

    for (var i = 0; i < _transcriptData!.transcript.length; i++) {
      final segment = _transcriptData!.transcript[i];
      final start = segment.timestamps.startSeconds;
      final end = segment.timestamps.endSeconds;

      if (currentSeconds >= start && currentSeconds < end) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex != -1 && activeIndex != _lastActiveSegmentIndex) {
      _lastActiveSegmentIndex = activeIndex;
      // Scroll to active segment
      if (_activeSegmentKey.currentContext != null) {
        Scrollable.ensureVisible(
          _activeSegmentKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5, // Center in viewport
        );
      }
    }
  }

  Future<void> _loadTranscript() async {
    if (widget.transcriptPath == null || widget.transcriptPath!.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jsonString = await rootBundle.loadString(widget.transcriptPath!);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _transcriptData = TranscriptData.fromJson(jsonData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load transcript: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: appColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/audio_lines.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                appColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Transcript',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'assets/icons/x.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                appColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: appColors.border.withValues(alpha: 0.5),
                    height: 1,
                  ),

                  // Content
                  Expanded(
                    child: _buildContent(appColors),
                  ),

                  // MediaPlayer at bottom
                  if (widget.audioPath != null) ...[
                    Divider(
                      color: appColors.border.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    MediaPlayer(
                      key: ValueKey(widget.audioPath),
                      audioPath: widget.audioPath!,
                      title: widget.audioPath!.split('/').last,
                      externalPlayer: widget.audioPlayer,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AppColorsExtension appColors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: appColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading transcript...',
              style: TextStyle(color: appColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_transcriptData == null || widget.transcriptPath == null) {
      return Center(
        child: Text(
          'No transcript available.',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: _transcriptData!.transcript.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isLast = index == _transcriptData!.transcript.length - 1;

          // Determine if active
          final start = segment.timestamps.startSeconds;
          final end = segment.timestamps.endSeconds;
          final currentSeconds = _currentTime.inSeconds;
          final isActive = currentSeconds >= start && currentSeconds < end;

          return Column(
            children: [
              _buildSegment(segment, appColors, isActive),
              if (!isLast)
                Divider(
                  color: appColors.border.withValues(alpha: 0.3),
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSegment(
    TranscriptSegment segment,
    AppColorsExtension appColors,
    bool isActive,
  ) {
    return Container(
      key: isActive ? _activeSegmentKey : null,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isActive
            ? appColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isActive ? appColors.primary : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Speaker + Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speaker
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: appColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    segment.speaker.replaceAll('_', ' '),
                    style: TextStyle(
                      color: appColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Timestamp + Seek button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? appColors.primary.withValues(alpha: 0.2)
                          : appColors.border.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isActive
                              ? appColors.primary
                              : appColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          segment.timestamps.start,
                          style: TextStyle(
                            color: isActive
                                ? appColors.primary
                                : appColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ScanEye seek button (only show when NOT active)
                  if (!isActive)
                    InkWell(
                      onTap: () {
                        // Phase 6 - Implement seek to timestamp
                        if (widget.audioPlayer != null) {
                          widget.audioPlayer!.seek(
                            Duration(seconds: segment.timestamps.startSeconds),
                          );
                          widget.audioPlayer!.resume();
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset(
                          'assets/icons/scan_eye.svg',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            appColors.textSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dialogues
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: appColors.textPrimary.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.6,
              ),
              children: segment.dialogues.map((dialogue) {
                return _buildDialogueSpan(dialogue, appColors);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  InlineSpan _buildDialogueSpan(
    Dialogue dialogue,
    AppColorsExtension appColors,
  ) {
    final isActive = _activeDialogueId == dialogue.id;
    final parsedText = _parseHtmlContent(dialogue.original);

    // Parse text into words and create spans with gestures
    final spans = <InlineSpan>[];
    // Split by whitespace but keep the whitespace in the result
    final pattern = RegExp(r'(\s+)');
    final matches = pattern.allMatches(parsedText);

    var lastIndex = 0;
    for (final match in matches) {
      // Add the word before the whitespace
      if (match.start > lastIndex) {
        final word = parsedText.substring(lastIndex, match.start);
        spans.add(_createWordSpan(word, isActive, appColors, dialogue));
      }

      // Add the whitespace
      spans.add(TextSpan(text: match.group(0)));
      lastIndex = match.end;
    }

    // Add remaining text after last whitespace
    if (lastIndex < parsedText.length) {
      final word = parsedText.substring(lastIndex);
      spans.add(_createWordSpan(word, isActive, appColors, dialogue));
    }

    // Add translation if active
    if (isActive) {
      spans.add(
        TextSpan(
          text: ' ${_parseHtmlContent(dialogue.translation)}',
          style: TextStyle(
            color: appColors.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  // Create a TextSpan for a single word with gesture recognizers
  TextSpan _createWordSpan(
    String word,
    bool isActive,
    AppColorsExtension appColors,
    Dialogue dialogue,
  ) {
    // Clean word for dictionary lookup (remove punctuation)
    final cleanWord = word.replaceAll(RegExp(r'[^\w\s-]'), '').toLowerCase();

    // Create a multi-gesture recognizer that handles both tap and long-press
    final gestureRecognizer = _createGestureRecognizer(
      onTap: () {
        setState(() {
          _activeDialogueId =
              _activeDialogueId == dialogue.id ? null : dialogue.id;
        });
      },
      onLongPress: cleanWord.isNotEmpty && widget.onWordLongPress != null
          ? () => widget.onWordLongPress!(cleanWord)
          : null,
    );

    return TextSpan(
      text: word,
      style: TextStyle(
        backgroundColor:
            isActive ? appColors.primary.withValues(alpha: 0.2) : null,
      ),
      recognizer: gestureRecognizer,
    );
  }

  // Create a custom gesture recognizer that handles both tap and long-press
  GestureRecognizer _createGestureRecognizer({
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    if (onLongPress != null) {
      // Use a combination approach: TapGestureRecognizer with custom handling
      // Track long-press timing
      var isLongPress = false;
      Timer? longPressTimer;

      final recognizer = TapGestureRecognizer()
        ..onTapDown = (_) {
          isLongPress = false;
          longPressTimer = Timer(const Duration(milliseconds: 500), () {
            isLongPress = true;
            onLongPress();
          });
        }
        ..onTapUp = (_) {
          longPressTimer?.cancel();
        }
        ..onTapCancel = () {
          longPressTimer?.cancel();
        }
        ..onTap = () {
          if (!isLongPress) {
            onTap();
          }
        };

      return recognizer;
    } else {
      // Only tap
      return TapGestureRecognizer()..onTap = onTap;
    }
  }

  // HTML parser - handle styles inline without line breaks
  String _parseHtmlContent(String content) {
    // Remove </n> tags and replace with space (inline)
    final result = content.replaceAll(RegExp(r'</n\s*>'), ' ');
    // Remove other HTML tags but keep text inline
    return result.replaceAll(RegExp('<[^>]*>'), '');
  }
}
