import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class PassageDrawer extends StatefulWidget {
  const PassageDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.passagePath,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String? passagePath;

  @override
  State<PassageDrawer> createState() => _PassageDrawerState();
}

class _PassageDrawerState extends State<PassageDrawer> {
  int? _activeSegmentIndex;

  // Simplified passage segments for demonstration
  final List<Map<String, String>> _segments = [
    {
      'content': 'This is a sample passage segment. ',
      'translate': 'Đây là một đoạn văn mẫu. ',
    },
    {
      'content': 'Click to see translation. ',
      'translate': 'Nhấp để xem bản dịch. ',
    },
  ];

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
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            color: appColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passage',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: appColors.border.withValues(alpha: 0.5)),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: appColors.textPrimary,
                              height: 1.6,
                            ),
                        children: _segments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final segment = entry.value;
                          final isActive = _activeSegmentIndex == index;

                          return WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeSegmentIndex = isActive ? null : index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? appColors.primary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      segment['content']!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: appColors.textPrimary,
                                            height: 1.6,
                                          ),
                                    ),
                                    if (isActive)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          segment['translate']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: appColors.textSecondary,
                                                fontStyle: FontStyle.italic,
                                                height: 1.5,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
