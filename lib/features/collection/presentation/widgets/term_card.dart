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
    required this.onMasteryToggle,
    super.key,
  });

  final Term term;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMasteryToggle;

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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: <number>. <term> | Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
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
                ),
                GestureDetector(
                  onTap: onMasteryToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: term.isMastered
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      term.isMastered ? 'Mastered' : 'Learning',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: term.isMastered ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
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
    );
  }
}
