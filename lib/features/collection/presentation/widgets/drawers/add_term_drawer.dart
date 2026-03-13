import 'dart:async';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart'
    hide debugPrint;
import 'package:fluency/features/quiz/data/services/dictionary_api/cambridge_autocomplete_service.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/thesaurus_autocomplete_service.dart';
import 'package:flutter/material.dart';

class AddTermDrawer extends StatefulWidget {
  const AddTermDrawer({
    required this.onWordSelected,
    super.key,
  });

  final void Function(String) onWordSelected;

  @override
  State<AddTermDrawer> createState() => _AddTermDrawerState();
}

class _AddTermDrawerState extends State<AddTermDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final CambridgeAutocompleteService _cambridgeService =
      CambridgeAutocompleteService();
  final ThesaurusAutocompleteService _thesaurusService =
      ThesaurusAutocompleteService();
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  final Map<String, bool> _inCollectionStatus = {};
  final Map<String, DirectoryEntry?> _suggestionMetadata = {};
  final CollectionRepository _collectionRepository = CollectionRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _checkInitialSuggestions();
  }

  Future<void> _checkInitialSuggestions() async {
    // Optional: pre-check if suggestions change
  }

  Future<void> _updateCollectionStatus(List<String> suggestions) async {
    for (final s in suggestions) {
      if (!_inCollectionStatus.containsKey(s)) {
        final exists = await _collectionRepository.isTermInAnyCollection(s);
        if (mounted) {
          setState(() {
            _inCollectionStatus[s] = exists;
          });
        }
      }
      // Also fetch metadata
      if (!_suggestionMetadata.containsKey(s)) {
        directoryStorage.fetchAndSave(s).then((entry) {
          if (mounted) {
            if (entry == null) {
              // Hide suggestions that have no definitions
              setState(() {
                _suggestions.remove(s);
              });
            } else {
              setState(() {
                _suggestionMetadata[s] = entry;
              });
            }
          }
        });
      } else if (_suggestionMetadata[s] == null) {
        // Known empty, avoid showing
        setState(() {
          _suggestions.remove(s);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    // Check cache first for instant results
    final cambridgeCached = _cambridgeService.checkCache(query);
    final thesaurusCached = _thesaurusService.checkCache(query);

    if (cambridgeCached != null || thesaurusCached != null) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      final combined = <String>{
        if (cambridgeCached != null) ...cambridgeCached,
        if (thesaurusCached != null) ...thesaurusCached,
      }.toList();

      setState(() {
        _suggestions = combined;
        _isLoading = false;
      });
      _updateCollectionStatus(combined);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _cambridgeService.getSuggestions(query),
        _thesaurusService.getSuggestions(query),
      ]);

      final combined = <String>{
        ...results[0],
        ...results[1],
      }.toList();

      if (mounted) {
        setState(() {
          _suggestions = combined;
          _isLoading = false;
        });
        _updateCollectionStatus(combined);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildHeader(appColors),
          _buildSearchBar(appColors),
          const SizedBox(height: 4),
          Expanded(child: _buildSuggestionsList(appColors)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 16, 8), // Shifted even more up
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add New Word',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: appColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: appColors.textSecondary
                    .withValues(alpha: 0.08), // Subtle bg
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.border,
                ),
              ),
              child: Icon(Icons.close_rounded,
                  color: appColors.textPrimary, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(24, 0, 24, 4), // Minimal vertical space
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38, // Slightly adjusted height
            decoration: BoxDecoration(
              color: appColors.inputBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: appColors.border,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _onSearchChanged(val);
                setState(() {});
              },
              autofocus: true,
              style: TextStyle(
                color: appColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Type a word to search...',
                hintStyle: TextStyle(
                  color: appColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: appColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                appColors.primary),
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.cancel_rounded,
                                size: 18,
                                color: appColors.textSecondary
                                    .withValues(alpha: 0.5)),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Found ${_suggestions.length} results for "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textSecondary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(AppColorsExtension appColors) {
    if (_suggestions.isEmpty &&
        !_isLoading &&
        _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48,
                color: appColors.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No matching words found',
              style: TextStyle(
                color: appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestions.isEmpty && !_isLoading && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded,
                size: 48,
                color: appColors.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Start typing to see suggestions',
              style: TextStyle(
                color: appColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final bool inCollection = _inCollectionStatus[suggestion] ?? false;
        final entry = _suggestionMetadata[suggestion];

        final ipa = entry?.phonetics.isNotEmpty == true
            ? entry!.phonetics.first.text
            : null;
        final pos = entry?.meanings.isNotEmpty == true
            ? entry!.meanings.first.partOfSpeech
            : null;
        final definition = entry?.meanings.isNotEmpty == true &&
                entry!.meanings.first.definitions.isNotEmpty == true
            ? entry.meanings.first.definitions.first.definition
            : null;

        // Custom POS styling
        Color posColor = const Color(0xFF60A5FA);
        String posLabel = pos ?? '';
        if (pos != null) {
          switch (pos.toLowerCase()) {
            case 'adjective':
            case 'adj':
              posColor = const Color(0xFFA78BFA);
              posLabel = 'adj';
              break;
            case 'verb':
              posColor = const Color(0xFF34D399);
              break;
            case 'adverb':
            case 'adv':
              posColor = const Color(0xFFFBBF24);
              posLabel = 'adv';
              break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 4), // Reduced margin
          decoration: const BoxDecoration(
            color: Colors.transparent, // No background
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onWordSelected(suggestion);
              },
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 10, 8, 10), // Adjusted padding
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                suggestion,
                                style: TextStyle(
                                  color: appColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (ipa != null && ipa.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  ipa,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: appColors.textSecondary
                                        .withValues(alpha: 0.5),
                                    fontFamily: 'NotoSans',
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (pos != null && pos.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: posColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: posColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    posLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: posColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (definition != null && definition.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              definition,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: appColors.textSecondary
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: inCollection
                            ? Colors.green.withValues(alpha: 0.1)
                            : appColors.textSecondary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: inCollection ? Colors.green : appColors.border,
                        ),
                      ),
                      child: Icon(
                        inCollection ? Icons.check_rounded : Icons.add_rounded,
                        color: inCollection
                            ? Colors.green
                            : appColors.textSecondary.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
