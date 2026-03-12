import 'dart:async';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/cambridge_autocomplete_service.dart';
import 'package:flutter/material.dart';

class AddTermDrawer extends StatefulWidget {
  const AddTermDrawer({
    required this.onWordSelected,
    super.key,
  });

  final Function(String) onWordSelected;

  @override
  State<AddTermDrawer> createState() => _AddTermDrawerState();
}

class _AddTermDrawerState extends State<AddTermDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final CambridgeAutocompleteService _autocompleteService =
      CambridgeAutocompleteService();
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);
      final suggestions = await _autocompleteService.getSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
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
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 24, endIndent: 24),
          Expanded(child: _buildSuggestionsList(appColors)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Word',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: appColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Search from Cambridge Dictionary',
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  color: appColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: appColors.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _searchController.text.isNotEmpty
                ? appColors.primary.withValues(alpha: 0.5)
                : appColors.border.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            if (_searchController.text.isNotEmpty)
              BoxShadow(
                color: appColors.primary.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
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
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Type a word to search...',
            hintStyle: TextStyle(
              color: appColors.textSecondary.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _searchController.text.isNotEmpty
                  ? appColors.primary
                  : appColors.textSecondary,
              size: 22,
            ),
            suffixIcon: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
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
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onWordSelected(suggestion);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: appColors.cardBackground.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: appColors.border.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.text_fields_rounded,
                          color: appColors.primary, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: appColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: appColors.textSecondary.withValues(alpha: 0.3),
                      size: 14,
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
