import 'dart:convert';
import 'dart:io';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/domain/entities/passage_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

class PassageDrawer extends StatefulWidget {
  const PassageDrawer({
    required this.isOpen,
    required this.onClose,
    super.key,
    this.passagePath,
    this.parentFilePath,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String? passagePath;
  final String? parentFilePath;

  @override
  State<PassageDrawer> createState() => _PassageDrawerState();
}

class _PassageDrawerState extends State<PassageDrawer> {
  PassageData? _passageData;
  bool _isLoading = false;
  String? _error;
  int? _activeSegmentIndex;

  @override
  void didUpdateWidget(PassageDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen &&
        (widget.passagePath != oldWidget.passagePath ||
            widget.parentFilePath != oldWidget.parentFilePath)) {
      _loadPassage();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isOpen && widget.passagePath != null) {
      _loadPassage();
    }
  }

  Future<void> _loadPassage() async {
    if (widget.passagePath == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _activeSegmentIndex = null;
    });

    try {
      var fullPath = widget.passagePath!;
      // Resolve relative path if needed
      if (widget.passagePath!.startsWith('./') &&
          widget.parentFilePath != null) {
        final parentDir = p.dirname(widget.parentFilePath!);
        fullPath = p.join(parentDir, widget.passagePath!.substring(2));
      }

      String jsonString;
      if (kIsWeb) {
        // On Web, load from assets (rootBundle)
        // Ensure path doesn't start with / or ./ for rootBundle if it's absolute from assets
        // But here fullPath is constructed. If parentFilePath was 'assets/...', fullPath is 'assets/...'
        jsonString = await rootBundle.loadString(fullPath);
      } else {
        // On Mobile, load from File System
        final file = File(fullPath);
        if (file.existsSync()) {
          jsonString = await file.readAsString();
        } else {
          setState(() {
            _error = 'Passage file not found';
            _isLoading = false;
          });
          return;
        }
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _passageData = PassageData.fromJson(jsonMap);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load passage: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Backdrop
        IgnorePointer(
          ignoring: !widget.isOpen,
          child: GestureDetector(
            onTap: widget.onClose,
            child: AnimatedOpacity(
              opacity: widget.isOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),

        // Drawer
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          bottom: widget.isOpen ? 0 : -MediaQuery.of(context).size.height,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Container(
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
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
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
                              'assets/icons/pilcrow.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                appColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                'Passage',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: appColors.textPrimary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
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
        child: Text(
          'Loading...',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_passageData == null) {
      return Center(
        child: Text(
          'No passage available.',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _passageData!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          // Segments RichText
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: appColors.textPrimary,
                    height: 1.6,
                    fontSize: 16,
                  ),
              children: _buildTextSpans(appColors),
            ),
          ),

          // Bottom padding
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(AppColorsExtension appColors) {
    if (_passageData == null) return [];

    final spans = <InlineSpan>[];

    for (var i = 0; i < _passageData!.segments.length; i++) {
      final segment = _passageData!.segments[i];
      final isActive = _activeSegmentIndex == i;

      // Unifying content and translation into a single TextSpan block per segment?
      // Actually, TranscriptDrawer creates a TextSpan for original and one for translation within a single parent.
      // But PassageDrawer renders segments consecutively. We can just add them to the list.

      spans.add(
        TextSpan(
          children: [
            // Original Text
            TextSpan(
              text: _parseHtmlContent(segment.content), // Basic parsing
              style: isActive
                  ? TextStyle(
                      backgroundColor: appColors.primary.withValues(alpha: 0.2),
                    )
                  : null,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _activeSegmentIndex = isActive ? null : i;
                  });
                },
            ),
            // Translation Text (Inline)
            if (isActive)
              TextSpan(
                text:
                    ' ${_parseHtmlContent(segment.translate)}', // Space prefix
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
          ],
        ),
      );
    }

    return spans;
  }

  // HTML parser - handle styles inline without line breaks
  String _parseHtmlContent(String content) {
    if (content.isEmpty) return '';

    // Remove </n> tags and replace with space (inline) or analyze if they mean <br>
    // React code replaces </n> with <br>, but TextSpan doesn't support <br> easily unless we split.
    // For inline flow, usually space is safer for simple reading.
    // If double newline is expected, we might need '\n'.
    // Let's use space for flow as per TranscriptDrawer experience.
    final result = content.replaceAll(RegExp(r'</n\s*>'), ' ');

    // Remove other HTML tags but keep text inline
    return result.replaceAll(RegExp('<[^>]*>'), '');
  }
}
