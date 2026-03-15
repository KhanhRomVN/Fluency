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

  Color _getMasteryColor(double level, AppColorsExtension appColors) {
    if (level == 0) return appColors.textSecondary.withValues(alpha: 0.5);
    if (level <= 0.25) return const Color(0xFF94A3B8);
    if (level <= 0.5) return const Color(0xFF60A5FA);
    if (level <= 0.75) return const Color(0xFFF59E0B);
    return appColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    // Determine POS color & label
    String posLabel = 'noun';
    Color posColor = const Color(0xFF60A5FA);

    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        final meanings = json['meanings'] as List?;
        if (meanings != null && meanings.isNotEmpty) {
          final first = meanings.first as Map<String, dynamic>;
          posLabel = first['partOfSpeech']?.toString() ?? 'noun';
        }
      }
    } catch (_) {}

    // Dynamic POS styling
    switch (posLabel.toLowerCase()) {
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

    final ipa = term.phonetics.isNotEmpty ? term.phonetics.first : null;
    final masteryColor = _getMasteryColor(term.masteryLevel, appColors);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSelectionMode
                  ? () => onSelectedChanged?.call(!isSelected)
                  : onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 4),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: onSelectedChanged,
                            activeColor: appColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),

                    // Index
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: appColors.textSecondary.withValues(alpha: 0.4),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Word Block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                term.term,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: appColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(
                                  color: posColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: posColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  posLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: posColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (ipa != null) ...[
                            const SizedBox(height: 2),
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
                          const SizedBox(height: 4),
                          Text(
                            _getDisplayDefinition(),
                            style: TextStyle(
                              fontSize: 13,
                              color: appColors.textSecondary,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mastery Badge
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: masteryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: masteryColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                '${(term.masteryLevel * 100).toInt()}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: masteryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
