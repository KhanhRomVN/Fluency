import 'dart:convert';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:flutter/material.dart';

class TermCard extends StatelessWidget {
  const TermCard({
    required this.term,
    required this.index,
    required this.onTap,
    required this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectedChanged,
    super.key,
  });

  final Term term;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectedChanged;

  String _getDisplayDefinition() {
    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        final meanings = json['meanings'] as List?;
        if (meanings != null && meanings.isNotEmpty) {
          final firstMeaning = meanings.first as Map<String, dynamic>;
          final definitions = firstMeaning['definitions'] as List?;
          if (definitions != null && definitions.isNotEmpty) {
            return definitions.first['definition']?.toString() ??
                term.definition;
          }
        }
      }
    } catch (_) {
      // Fallback
    }
    return term.definition;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return InkWell(
      onTap:
          isSelectionMode ? () => onSelectedChanged?.call(!isSelected) : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectedChanged,
                  activeColor: appColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: <number>. <term>
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: appColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '$index. ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: appColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: term.term,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Row 2: Main Definition
                  Text(
                    _getDisplayDefinition(),
                    style: TextStyle(
                      fontSize: 14,
                      color: appColors.textPrimary.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: term.masteryLevel,
                    strokeWidth: 3,
                    backgroundColor:
                        appColors.textSecondary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      term.masteryLevel >= 0.7
                          ? Colors.green
                          : term.masteryLevel >= 0.3
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  Text(
                    '${(term.masteryLevel * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: term.masteryLevel >= 0.7
                          ? Colors.green
                          : term.masteryLevel >= 0.3
                              ? Colors.orange
                              : Colors.red,
                    ),
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
