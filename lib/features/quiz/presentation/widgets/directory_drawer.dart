import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/data/services/bookmark_storage.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart'
    hide debugPrint;
import 'package:fluency/features/quiz/presentation/widgets/add_to_collection_drawer.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class DirectoryDrawer extends StatefulWidget {
  const DirectoryDrawer({
    required this.isOpen,
    required this.onClose,
    required this.word,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String? word;

  @override
  State<DirectoryDrawer> createState() => _DirectoryDrawerState();
}

class _DirectoryDrawerState extends State<DirectoryDrawer> {
  DirectoryEntry? _entry;
  bool _loading = false;
  String? _error;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    bookmarkStorage.init();
    if (widget.isOpen && widget.word != null) {
      _fetchWord();
    }
  }

  @override
  void didUpdateWidget(DirectoryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch if:
    // 1. Drawer was closed and is now open (and has a word)
    // 2. Word changed (and drawer is open)
    if ((widget.isOpen && !oldWidget.isOpen && widget.word != null) ||
        (widget.isOpen &&
            widget.word != null &&
            widget.word != oldWidget.word)) {
      _fetchWord();
    }
  }

  Future<void> _fetchWord() async {
    if (widget.word == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
    });

    final result = await directoryStorage.fetchAndSave(widget.word!);

    if (mounted) {
      setState(() {
        _entry = result;
        _error = result == null
            ? 'Could not find definition for "${widget.word}"'
            : null;
        _loading = false;
        _isBookmarked = bookmarkStorage.isBookmarked(widget.word!);
      });
    }
  }

  void _openCollectionDrawer() {
    if (_entry == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCollectionDrawer(entry: _entry!),
    ).then((_) {
      // Refresh bookmark status if needed (though collection status is separate for now)
      if (mounted && widget.word != null) {
        setState(() {
          _isBookmarked = bookmarkStorage.isBookmarked(widget.word!);
        });
      }
    });
  }

  Future<void> _speakWord() async {
    if (_entry == null) return;
    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isInitialized) {
      await ttsProvider.initService();
    }
    await ttsProvider.speakWithGender(_entry!.word);
  }

  @override
  Widget build(BuildContext context) {
    // Only show drawer if open AND data is ready (or has error to show)
    if (!widget.isOpen || (_loading || (_entry == null && _error == null))) {
      return const SizedBox.shrink();
    }

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        // Bottom Drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: appColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header
                  _buildHeader(context, appColors),

                  Divider(color: appColors.border.withOpacity(0.5), height: 1),

                  // Content Body
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Text(_error!,
                                    style: const TextStyle(color: Colors.red)))
                            : _entry != null
                                ? _buildContent(context, appColors)
                                : const Center(
                                    child: Text('Type to search dictionary'),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension appColors) {
    final ipa = _entry?.phonetics.isNotEmpty == true
        ? _entry!.phonetics.first.text
        : '';
    final term = widget.word ?? '';

    // Icons SVGs
    // Bookmark icon provided by user
    const bookmarkSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-bookmark-icon lucide-bookmark"><path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"/></svg>''';
    // X icon provided by user
    const closeSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x-icon lucide-x"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>''';
    // Volume icon (Lucide Volume 2)
    const volumeSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-volume-2"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>''';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Term and IPA horizontal
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    term,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
                  ),
                ),
                if (ipa.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    ipa,
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right: 3 buttons (IPA, Bookmark, Close)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // a/ IPA (Speaker)
              IconButton(
                onPressed: _speakWord,
                icon: SvgPicture.string(
                  volumeSvg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    appColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              // b/ Bookmark
              IconButton(
                onPressed: _openCollectionDrawer,
                icon: SvgPicture.string(
                  bookmarkSvg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    _isBookmarked ? appColors.primary : appColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              // c/ X (Close)
              IconButton(
                onPressed: widget.onClose,
                icon: SvgPicture.string(
                  closeSvg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    appColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppColorsExtension appColors) {
    if (_entry == null) return const SizedBox.shrink();

    // Group meanings by POS
    final Map<String, List<Definition>> groupedDefinitions = {};
    for (var meaning in _entry!.meanings) {
      // Normalize POS to lower case for grouping to avoid 'Verb' vs 'verb' splits
      final pos = meaning.partOfSpeech.toLowerCase();
      if (!groupedDefinitions.containsKey(pos)) {
        groupedDefinitions[pos] = [];
      }
      groupedDefinitions[pos]!.addAll(meaning.definitions);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // REMOVED 'Meaning' Header

          // Meanings Grouped by POS
          ...groupedDefinitions.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _PosSection(
                pos: entry.key,
                definitions: entry.value,
                appColors: appColors,
              ),
            );
          }),

          const SizedBox(height: 8),
          Divider(color: appColors.border.withOpacity(0.5)),
          const SizedBox(height: 16),

          // Forms (max 5)
          if (_entry!.forms.isNotEmpty) ...[
            Text(
              'Forms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _entry!.forms.take(5).map((f) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: appColors.border),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${f.word} ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: appColors.textPrimary,
                          ),
                        ),
                        if (f.tags.isNotEmpty)
                          TextSpan(
                            text: '(${f.tags.join(', ')})',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: appColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _PosSection extends StatefulWidget {
  final String pos;
  final List<Definition> definitions;
  final AppColorsExtension appColors;

  const _PosSection({
    required this.pos,
    required this.definitions,
    required this.appColors,
  });

  @override
  State<_PosSection> createState() => _PosSectionState();
}

class _PosSectionState extends State<_PosSection> {
  int _page = 0;
  static const int _limit = 5;

  Color _getPosColor(String pos) {
    switch (pos.toLowerCase()) {
      case 'noun':
      case 'n.':
        return Colors.blue;
      case 'verb':
      case 'v.':
        return Colors.teal;
      case 'adjective':
      case 'adj.':
      case 'adj':
        return Colors.orange;
      case 'adverb':
      case 'adv.':
      case 'adv':
        return Colors.purple;
      case 'pronoun':
      case 'pron.':
        return Colors.indigo;
      case 'preposition':
      case 'prep.':
        return Colors.brown;
      case 'conjunction':
      case 'conj.':
        return Colors.pink;
      case 'interjection':
      case 'interj.':
        return Colors.deepOrange;
      default:
        return widget.appColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defs = widget.definitions;
    if (defs.isEmpty) return const SizedBox.shrink();

    final totalPages = (defs.length / _limit).ceil();
    final start = _page * _limit;
    final end = (start + _limit < defs.length) ? start + _limit : defs.length;
    final currentDefs = defs.sublist(start, end);

    final posColor = _getPosColor(widget.pos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Label + Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.pos.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: posColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Pagination
            if (totalPages > 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: _page > 0
                          ? widget.appColors.textSecondary
                          : widget.appColors.textSecondary.withOpacity(0.3),
                    ),
                    onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.appColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_page + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: _page < totalPages - 1
                          ? widget.appColors.textSecondary
                          : widget.appColors.textSecondary.withOpacity(0.3),
                    ),
                    onPressed: _page < totalPages - 1
                        ? () => setState(() => _page++)
                        : null,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List of definitions
        ...currentDefs.asMap().entries.map((entry) {
          final index = entry.key;
          final def = entry.value;
          final globalNumber = start + index + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.appColors.textPrimary,
                      height: 1.4,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: '$globalNumber. ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: def.definition),
                    ],
                  ),
                ),
                if (def.example != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      '"${def.example}"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: widget.appColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
