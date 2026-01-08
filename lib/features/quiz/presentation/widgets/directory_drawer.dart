import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart'
    hide debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluency/features/quiz/data/services/bookmark_storage.dart';

class DirectoryDrawer extends StatefulWidget {
  const DirectoryDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.word,
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
  Map<String, dynamic> _stats = {'count': 0, 'size': '0 B'};

  @override
  void initState() {
    super.initState();
    bookmarkStorage.init();
    _loadStats();
    directoryStorage.subscribe(_loadStats);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(DirectoryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && widget.word != null && widget.word != oldWidget.word) {
      _fetchWord();
    }
  }

  void _loadStats() {
    if (mounted) {
      setState(() {
        _stats = directoryStorage.getStats();
      });
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

  Future<void> _toggleBookmark() async {
    if (widget.word == null) return;

    await bookmarkStorage.toggle(widget.word!);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarkStorage.isBookmarked(widget.word!);
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
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              color: appColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dictionary',
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: appColors.border
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'Cached: ${_stats['count']} | ${_stats['size']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: appColors.textSecondary,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.word != null) ...[
                              InkWell(
                                onTap: _toggleBookmark,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(
                                    _isBookmarked
                                        ? 'assets/icons/bookmark_check.svg'
                                        : 'assets/icons/bookmark.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      appColors.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            IconButton(
                              onPressed: widget.onClose,
                              icon: Icon(
                                Icons.close,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(color: appColors.border.withValues(alpha: 0.5)),

                  // Content
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.red),
                                    ),
                                  ],
                                ),
                              )
                            : _entry != null
                                ? _buildEntryContent(_entry!)
                                : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryContent(DirectoryEntry entry) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Header
          Row(
            children: [
              Text(
                entry.word,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appColors.border),
                ),
                child: Text(
                  entry.source == 'FreeDict'
                      ? 'Free Dictionary API'
                      : 'Dictionary API',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Meanings
          ...entry.meanings.map((meaning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      meaning.partOfSpeech,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: appColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...meaning.definitions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final def = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: appColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  def.definition,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: appColors.textPrimary,
                                      ),
                                ),
                                if (def.translations.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      def.translations.join(', '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: appColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
