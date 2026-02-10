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

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(appColors),
          _buildSearchBar(appColors),
          Expanded(child: _buildSuggestionsList(appColors)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add New Term',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: appColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: appColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: appColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          style: TextStyle(color: appColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search in Cambridge Dictionary...',
            hintStyle: TextStyle(
              color: appColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: appColors.textSecondary,
              size: 20,
            ),
            suffixIcon: _isLoading
                ? Container(
                    padding: const EdgeInsets.all(12),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appColors.primary,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
        child: Text(
          'No suggestions found',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        color: appColors.border.withValues(alpha: 0.3),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            suggestion,
            style: TextStyle(
              color: appColors.textPrimary,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: appColors.textSecondary,
            size: 20,
          ),
          onTap: () {
            Navigator.pop(context);
            widget.onWordSelected(suggestion);
          },
        );
      },
    );
  }
}
