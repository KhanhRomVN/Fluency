import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/quiz/data/services/bookmark_storage.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/cambridge_autocomplete_service.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/thesaurus_autocomplete_service.dart';
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
    this.collectionId,
    this.onTermAdded,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String? word;
  final String? collectionId;
  final VoidCallback? onTermAdded;

  @override
  State<DirectoryDrawer> createState() => _DirectoryDrawerState();
}

class _DirectoryDrawerState extends State<DirectoryDrawer> {
  DirectoryEntry? _entry;
  bool _isBookmarked = false;
  bool _loading = false;
  String? _error;
  final CollectionRepository _collectionRepository = CollectionRepositoryImpl();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final CambridgeAutocompleteService _cambridgeService =
      CambridgeAutocompleteService();
  final ThesaurusAutocompleteService _thesaurusService =
      ThesaurusAutocompleteService();
  List<String> _suggestions = [];
  Timer? _debounce;
  final Map<String, DirectoryEntry?> _suggestionMetadata = {};
  bool _isFromRecommendation = false;
  bool _isSearching = false;
  String? _selectedPos;
  bool _isSpeaking = false;
  final Set<String> _fetchingWords = {};
  final List<DirectoryEntry> _history = [];
  static const int _pageSize = 10;
  int _suggestionPage = 0;
  int _extraPage = 0;

  @override
  void initState() {
    super.initState();
    bookmarkStorage.init();
    _suggestionPage = 0;
    _extraPage = 0;
    if (widget.isOpen && widget.word != null) {
      _searchController.text = widget.word!;
      _fetchWord();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
      _searchController.text = widget.word!;
      _fetchWord();
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _suggestionPage = 0;
      });
      return;
    }

    // Check cache first
    final cCached = _cambridgeService.checkCache(query);
    final tCached = _thesaurusService.checkCache(query);
    if (cCached != null || tCached != null) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      final combined = <String>{
        if (cCached != null) ...cCached,
        if (tCached != null) ...tCached,
      }.toList();
      setState(() {
        _suggestions = combined;
        _isSearching = false;
      });
      _fetchMetadataForSuggestions(combined);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await Future.wait([
        _cambridgeService.getSuggestions(query),
        _thesaurusService.getSuggestions(query),
      ]);
      final combined = <String>{...results[0], ...results[1]}.toList();
      if (mounted) {
        setState(() {
          _suggestions = combined;
          _isSearching = false;
          _suggestionPage = 0;
        });
      }
    });
  }

  bool _isEntryValid(DirectoryEntry? entry) {
    if (entry == null) return false;
    for (final m in entry.meanings) {
      for (final d in m.definitions) {
        if (d.definition.trim().isNotEmpty) return true;
      }
    }
    return false;
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() {
        _entry = _history.removeLast();
        _searchController.text = _entry!.word;
        if (_entry!.meanings.isNotEmpty) {
          _selectedPos = _entry!.meanings.first.partOfSpeech.toLowerCase();
        }
        _extraPage = 0;
      });
    } else {
      final currentQuery = _searchController.text;
      setState(() {
        _entry = null;
        _isFromRecommendation = false;
        _history.clear();
      });
      // Restore suggestions if we have a query
      if (currentQuery.isNotEmpty) {
        _onSearchChanged(currentQuery);
      }
    }
  }

  void _fetchMetadataForSuggestions(List<String> suggestions) {
    // No longer doing eager updates for all suggestions at once
    // but we can clear out known nulls if they were stored from previous sessions
    if (mounted) {
      setState(() {
        _suggestions.removeWhere((s) =>
            _suggestionMetadata.containsKey(s) &&
            !_isEntryValid(_suggestionMetadata[s]));
      });
    }
  }

  Future<void> _fetchWord() async {
    if (widget.word == null) return;
    _isFromRecommendation = false; // Reset when initial word load

    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
      _suggestions = []; // Clear suggestions when direct word is fetched
      _extraPage = 0;
      _history.clear(); // Clear history on new primary word fetch
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
        if (_entry != null && _entry!.meanings.isNotEmpty) {
          _selectedPos = _entry!.meanings.first.partOfSpeech.toLowerCase();
        }
      });

      // Also check collection repository
      final inCollection =
          await _collectionRepository.isTermInAnyCollection(widget.word!);
      if (mounted) {
        setState(() {
          _isBookmarked = _isBookmarked || inCollection;
        });
      }
    }
  }

  void _openCollectionDrawer() async {
    if (_entry == null) return;

    if (widget.collectionId != null) {
      // Auto-add to specified collection
      try {
        final definitionJson = jsonEncode(_entry!.toJson());
        final term = Term(
          id: const Uuid().v4(),
          term: _entry!.word,
          definition: definitionJson,
          phonetics: _entry!.phonetics.map((p) => p.text).toList(),
          addedAt: DateTime.now(),
        );
        await _collectionRepository.addTermToCollection(
            widget.collectionId!, term);

        if (mounted) {
          widget.onTermAdded?.call();
          // Update bookmark status
          final inCollection =
              await _collectionRepository.isTermInAnyCollection(_entry!.word);
          setState(() {
            _isBookmarked =
                bookmarkStorage.isBookmarked(_entry!.word) || inCollection;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${_entry!.word}" to collection'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCollectionDrawer(
        entry: _entry!,
        onAdded: widget.onTermAdded,
      ),
    ).then((_) async {
      // Refresh bookmark status if needed
      if (mounted && widget.word != null) {
        final inCollection =
            await _collectionRepository.isTermInAnyCollection(widget.word!);
        setState(() {
          _isBookmarked =
              bookmarkStorage.isBookmarked(widget.word!) || inCollection;
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
    setState(() => _isSpeaking = true);
    await ttsProvider.speakWithGender(_entry!.word);
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) {
      return const SizedBox.shrink();
    }

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

        // Bottom Drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: appColors.drawerBackground,
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
                  _buildHeader(context, appColors),

                  if (_entry == null)
                    _buildSearchBar(appColors)
                  else
                    _buildPosTabs(appColors),

                  Divider(
                      color: appColors.border.withValues(alpha: 0.5),
                      height: 1),

                  // Content Body
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _suggestions.isNotEmpty
                            ? _buildSuggestionsList(appColors)
                            : _error != null
                                ? _buildErrorUI(appColors)
                                : _entry != null
                                    ? _buildContent(context, appColors)
                                    : const Center(
                                        child:
                                            Text('Type to search dictionary'),
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
    final ipa = _entry?.phonetics.isNotEmpty ?? false
        ? _entry!.phonetics.first.text
        : '';
    final term = _entry?.word ?? _searchController.text;

    // Icons SVGs
    const chevronLeftSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-left"><path d="m15 18-6-6 6-6"/></svg>''';
    const bookmarkSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-bookmark-icon lucide-bookmark"><path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"/></svg>''';
    const bookmarkFilledSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-bookmark-icon lucide-bookmark"><path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z"/></svg>''';
    const closeSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x-icon lucide-x"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>''';
    const volumeSvg =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-volume-2"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>''';

    final title =
        _isSearching ? 'Searching...' : (term.isNotEmpty ? term : 'Dictionary');
    final subtitle = ipa.isNotEmpty ? ipa : 'Search full definitions and more';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (_isFromRecommendation &&
                    (_entry != null || _history.isNotEmpty)) ...[
                  _buildHeaderIcon(
                    chevronLeftSvg,
                    appColors.textSecondary,
                    _goBack,
                    appColors,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontFamily: ipa.isNotEmpty ? 'NotoSans' : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_entry != null) ...[
                _buildHeaderIcon(
                  volumeSvg,
                  appColors.textSecondary,
                  _speakWord,
                  appColors,
                  isActive: _isSpeaking,
                  activeColor: appColors.primary,
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  _isBookmarked ? bookmarkFilledSvg : bookmarkSvg,
                  appColors.textSecondary,
                  _openCollectionDrawer,
                  appColors,
                  isActive: _isBookmarked,
                  activeColor: Colors.amber,
                ),
                const SizedBox(width: 8),
              ],
              _buildHeaderIcon(
                closeSvg,
                appColors.textSecondary,
                widget.onClose,
                appColors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(
    String svg,
    Color color,
    VoidCallback onTap,
    AppColorsExtension appColors, {
    bool isActive = false,
    Color? activeColor,
  }) {
    final finalColor = isActive ? (activeColor ?? color) : color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? finalColor.withValues(alpha: 0.1)
              : appColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? finalColor.withValues(alpha: 0.4)
                : appColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: SvgPicture.string(
            svg,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(finalColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: appColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: appColors.border,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: appColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search words...',
            hintStyle: TextStyle(
              color: appColors.textSecondary.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: appColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
            suffixIcon: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(appColors.primary),
                      ),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.cancel_rounded,
                            size: 18,
                            color:
                                appColors.textSecondary.withValues(alpha: 0.5)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                      )
                    : null,
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              _fetchAndShowWord(val.trim());
            }
          },
        ),
      ),
    );
  }

  void _fetchAndShowWord(String word) {
    if (_entry != null) {
      _history.add(_entry!);
    }
    setState(() {
      _suggestions = [];
      _isFromRecommendation = true;
    });
    // This triggers _fetchWord logic if we wrap it or call storage directly
    // Let's call storage directly and update state
    _fetchNewWord(word);
  }

  Widget _buildPosTabs(AppColorsExtension appColors) {
    if (_entry == null) return const SizedBox.shrink();

    final poses = _entry!.meanings
        .map((m) => m.partOfSpeech.toLowerCase())
        .where((p) => p != 'thesaurus')
        .toSet()
        .toList();

    // Collect all unique synonyms, antonyms, related words
    final allSynonyms = <String>{};
    final allAntonyms = <String>{};
    final allRelated = <String>{};
    for (final m in _entry!.meanings) {
      allSynonyms.addAll(m.synonyms);
      allAntonyms.addAll(m.antonyms);
      allRelated.addAll(m.relatedWords);
      for (final d in m.definitions) {
        allSynonyms.addAll(d.synonyms);
        allAntonyms.addAll(d.antonyms);
        allRelated.addAll(d.relatedWords);
      }
    }

    final extraTabs = [
      if (_entry!.forms.isNotEmpty) 'forms',
      if (allSynonyms.isNotEmpty) 'synonyms',
      if (allAntonyms.isNotEmpty) 'antonyms',
      if (allRelated.isNotEmpty) 'related',
    ];

    final allTabs = [...poses, ...extraTabs];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tabId = allTabs[index];
          final isSelected = _selectedPos == tabId;
          final isExtra = extraTabs.contains(tabId);
          final color = isExtra
              ? appColors.primary
              : _getPosColorForTab(tabId, appColors);

          // Get count for label
          int count = 0;
          if (isExtra) {
            if (tabId == 'forms') count = _entry!.forms.length;
            if (tabId == 'synonyms') count = allSynonyms.length;
            if (tabId == 'antonyms') count = allAntonyms.length;
            if (tabId == 'related') count = allRelated.length;
          } else {
            count = _entry!.meanings
                .where((m) => m.partOfSpeech.toLowerCase() == tabId)
                .expand((m) => m.definitions)
                .length;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPos = tabId;
                _extraPage = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : appColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? color
                      : appColors.textSecondary.withValues(alpha: 0.15),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${tabId.toUpperCase()} ($count)',
                style: TextStyle(
                  color: isSelected ? color : appColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPosColorForTab(String pos, AppColorsExtension appColors) {
    var p = pos.toLowerCase().trim();
    if (p.endsWith('.')) p = p.substring(0, p.length - 1);

    switch (p) {
      case 'noun':
      case 'n':
        return Colors.blue;
      case 'verb':
      case 'v':
        return Colors.teal;
      case 'adjective':
      case 'adj':
        return Colors.orange;
      case 'adverb':
      case 'adv':
        return Colors.purple;
      case 'pronoun':
      case 'pron':
        return Colors.indigo;
      default:
        return appColors.primary;
    }
  }

  Future<void> _fetchNewWord(String word) async {
    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
    });

    final result = await directoryStorage.fetchAndSave(word);

    if (mounted) {
      setState(() {
        _entry = result;
        _error =
            result == null ? 'Could not find definition for "$word"' : null;
        _loading = false;
        _isBookmarked = bookmarkStorage.isBookmarked(word);
        if (_entry != null && _entry!.meanings.isNotEmpty) {
          _selectedPos = _entry!.meanings.first.partOfSpeech.toLowerCase();
        }
      });
    }
  }

  Widget _buildErrorUI(AppColorsExtension appColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: appColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! No results found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: appColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ??
                  'The word you are looking for might not be in our dictionary yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: appColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _error = null;
                  _suggestions = [];
                });
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: appColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try another word',
                style: TextStyle(
                  color: appColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(AppColorsExtension appColors) {
    final visibleSuggestions = _suggestions
        .where((s) => !(_suggestionMetadata.containsKey(s) &&
            !_isEntryValid(_suggestionMetadata[s])))
        .toList();

    final start = _suggestionPage * _pageSize;
    final end = start + _pageSize < visibleSuggestions.length
        ? start + _pageSize
        : visibleSuggestions.length;
    final pageItems = start < visibleSuggestions.length
        ? visibleSuggestions.sublist(start, end)
        : <String>[];

    return Column(
      children: [
        _buildPaginationUI(
          currentPage: _suggestionPage,
          totalItems: visibleSuggestions.length,
          onPageChanged: (p) => setState(() => _suggestionPage = p),
          appColors: appColors,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              return _buildWordListItem(pageItems[index], appColors);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationUI({
    required int currentPage,
    required int totalItems,
    required void Function(int) onPageChanged,
    required AppColorsExtension appColors,
  }) {
    final maxPage = (totalItems / _pageSize).ceil();
    if (maxPage <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous Button
          _buildPageArrow(
            Icons.chevron_left_rounded,
            currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            appColors,
          ),
          const SizedBox(width: 8),
          // Current Page Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${currentPage + 1}',
              style: TextStyle(
                color: appColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Max Page Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$maxPage',
              style: TextStyle(
                color: appColors.textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Next Button
          _buildPageArrow(
            Icons.chevron_right_rounded,
            currentPage < maxPage - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
            appColors,
          ),
        ],
      ),
    );
  }

  Widget _buildPageArrow(
      IconData icon, VoidCallback? onTap, AppColorsExtension appColors) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled
              ? appColors.textSecondary.withValues(alpha: 0.1)
              : appColors.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? appColors.textPrimary
              : appColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildWordListItem(String word, AppColorsExtension appColors) {
    if (_suggestionMetadata.containsKey(word)) {
      final entry = _suggestionMetadata[word];
      if (!_isEntryValid(entry)) {
        return const SizedBox.shrink(); // Hide if no definition FOUND
      }

      final e = entry!;
      final ipa = e.phonetics.isNotEmpty ? e.phonetics.first.text : null;
      final pos = e.meanings.isNotEmpty ? e.meanings.first.partOfSpeech : null;
      var definition =
          e.meanings.isNotEmpty && e.meanings.first.definitions.isNotEmpty
              ? e.meanings.first.definitions.first.definition
              : null;

      return ListTile(
        dense: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word,
              style: TextStyle(
                color: appColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (ipa != null) ...[
              const SizedBox(width: 8),
              Text(
                ipa,
                style: TextStyle(
                  fontSize: 11,
                  color: appColors.textSecondary.withValues(alpha: 0.6),
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
            if (pos != null) ...[
              const SizedBox(width: 8),
              _buildPosBadge(pos, appColors),
            ],
          ],
        ),
        subtitle: definition != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  definition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              )
            : null,
        onTap: () => _fetchAndShowWord(word),
      );
    }

    // Metadata not present, trigger fetch if not already fetching
    if (!_fetchingWords.contains(word)) {
      _fetchingWords.add(word);
      directoryStorage.fetchAndSave(word).then((entry) {
        _fetchingWords.remove(word);
        if (mounted) {
          setState(() {
            _suggestionMetadata[word] = entry;
          });
        }
      });
    }

    // Show loading placeholder
    return ListTile(
      dense: true,
      title: Row(
        children: [
          Text(
            word,
            style: TextStyle(
              color: appColors.textPrimary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                  appColors.primary.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
      onTap: () => _fetchAndShowWord(word),
    );
  }

  Widget _buildPosBadge(String pos, AppColorsExtension appColors) {
    var p = pos.toLowerCase().trim();
    if (p.endsWith('.')) p = p.substring(0, p.length - 1);
    final color = _getPosColorForTab(p, appColors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        p,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppColorsExtension appColors) {
    if (_entry == null) return const SizedBox.shrink();

    // Group meanings by POS
    final groupedDefinitions = <String, List<Definition>>{};
    for (final meaning in _entry!.meanings) {
      // Normalize POS to lower case for grouping to avoid 'Verb' vs 'verb' splits
      final pos = meaning.partOfSpeech.toLowerCase();
      if (!groupedDefinitions.containsKey(pos)) {
        groupedDefinitions[pos] = [];
      }
      groupedDefinitions[pos]!.addAll(meaning.definitions);
    }

    if (_selectedPos == 'forms' && _entry!.forms.isNotEmpty) {
      final visibleForms = _entry!.forms
          .where((f) => !(_suggestionMetadata.containsKey(f.word) &&
              !_isEntryValid(_suggestionMetadata[f.word])))
          .toList();

      final start = _extraPage * _pageSize;
      final end = start + _pageSize < visibleForms.length
          ? start + _pageSize
          : visibleForms.length;
      final pageItems = start < visibleForms.length
          ? visibleForms.sublist(start, end)
          : <WordForm>[];

      return Column(
        children: [
          _buildPaginationUI(
            currentPage: _extraPage,
            totalItems: visibleForms.length,
            onPageChanged: (p) => setState(() => _extraPage = p),
            appColors: appColors,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pageItems.length,
              itemBuilder: (context, index) {
                return _buildWordListItem(pageItems[index].word, appColors);
              },
            ),
          ),
        ],
      );
    }

    if (_selectedPos == 'synonyms' ||
        _selectedPos == 'antonyms' ||
        _selectedPos == 'related') {
      final isSyn = _selectedPos == 'synonyms';
      final isAntony = _selectedPos == 'antonyms';
      final isRelated = _selectedPos == 'related';
      final words = <String>{};
      for (final m in _entry!.meanings) {
        if (isSyn) words.addAll(m.synonyms);
        if (isAntony) words.addAll(m.antonyms);
        if (isRelated) words.addAll(m.relatedWords);
        for (final d in m.definitions) {
          if (isSyn) words.addAll(d.synonyms);
          if (isAntony) words.addAll(d.antonyms);
          if (isRelated) words.addAll(d.relatedWords);
        }
      }
      final sortedWords = words.toList()..sort();
      // Filter out known nulls
      sortedWords.removeWhere((w) =>
          _suggestionMetadata.containsKey(w) &&
          !_isEntryValid(_suggestionMetadata[w]));

      final start = _extraPage * _pageSize;
      final end = start + _pageSize < sortedWords.length
          ? start + _pageSize
          : sortedWords.length;
      final pageItems = start < sortedWords.length
          ? sortedWords.sublist(start, end)
          : <String>[];

      return Column(
        children: [
          _buildPaginationUI(
            currentPage: _extraPage,
            totalItems: sortedWords.length,
            onPageChanged: (p) => setState(() => _extraPage = p),
            appColors: appColors,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pageItems.length,
              itemBuilder: (context, index) {
                return _buildWordListItem(pageItems[index], appColors);
              },
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meanings Grouped by POS
          if (_selectedPos != null &&
              groupedDefinitions.containsKey(_selectedPos))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PosSection(
                pos: _selectedPos!,
                definitions: groupedDefinitions[_selectedPos!]!,
                appColors: appColors,
              ),
            ),

          const SizedBox(height: 4),
          Divider(color: appColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PosSection extends StatelessWidget {
  const _PosSection({
    required this.pos,
    required this.definitions,
    required this.appColors,
  });

  final String pos;
  final List<Definition> definitions;
  final AppColorsExtension appColors;

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
        return appColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) return const SizedBox.shrink();

    final posColor = _getPosColor(pos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of definitions
        ...definitions.asMap().entries.map((entry) {
          final index = entry.key;
          final def = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textPrimary,
                      height: 1.4,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: '${index + 1}. ',
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
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: appColors.textSecondary,
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
