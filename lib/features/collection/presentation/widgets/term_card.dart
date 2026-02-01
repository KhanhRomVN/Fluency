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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần đầu: số, term, badge, trash icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Số thứ tự và term
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
                  const SizedBox(width: 8),
                  // Badge
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
                  const SizedBox(width: 8),
                  // Trash icon
                  GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: appColors.cardBackground,
                            title: Text(
                              'Delete Term?',
                              style: TextStyle(color: appColors.textPrimary),
                            ),
                            content: Text(
                              'Remove "${term.term}" from this collection?',
                              style: TextStyle(color: appColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: appColors.primary),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Phonetics (nếu có)
              if (term.phonetics.isNotEmpty) ...[
                Text(
                  term.phonetics.join(', '),
                  style: TextStyle(
                    fontSize: 13,
                    color: appColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Definition chính
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
      ),
    );
  }
}
