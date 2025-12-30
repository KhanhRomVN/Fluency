import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
    this.maxVisiblePages = 5,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChange;
  final int maxVisiblePages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev Button
        IconButton(
          onPressed:
              currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),

        // Pages
        ..._buildPageItems(context),

        // Next Button
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onPageChange(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  List<Widget> _buildPageItems(BuildContext context) {
    final List<Widget> items = [];
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    // Logic to show ranges e.g. 1 ... 4 5 6 ... 10
    // Simplified logic:

    if (totalPages <= maxVisiblePages) {
      for (int i = 1; i <= totalPages; i++) {
        items.add(_buildPageButton(context, i, appColors));
      }
    } else {
      // Always show first
      items.add(_buildPageButton(context, 1, appColors));

      if (currentPage > 3) {
        items.add(const Text("..."));
      }

      final start = (currentPage - 1).clamp(2, totalPages - 2);
      final end = (currentPage + 1).clamp(2, totalPages - 1);

      // Adjust if close to edges
      // This is a rough approximation of the logic, can be refined
      for (int i = start; i <= end; i++) {
        items.add(_buildPageButton(context, i, appColors));
      }

      if (currentPage < totalPages - 2) {
        items.add(const Text("..."));
      }

      // Always show last
      items.add(_buildPageButton(context, totalPages, appColors));
    }

    return items;
  }

  Widget _buildPageButton(
      BuildContext context, int page, AppColorsExtension? colors) {
    final isActive = page == currentPage;
    return InkWell(
      onTap: () => onPageChange(page),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color:
              isActive ? (colors?.primary ?? Colors.blue) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive
              ? null
              : Border.all(color: colors?.border ?? Colors.grey[300]!),
        ),
        child: Text(
          "$page",
          style: TextStyle(
            color:
                isActive ? Colors.white : (colors?.textPrimary ?? Colors.black),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
