import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HintDrawer extends StatelessWidget {
  const HintDrawer({
    required this.isOpen,
    required this.onClose,
    required this.hintContent,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final String hintContent;

  @override
  Widget build(BuildContext context) {
    // Unlike PassageDrawer, HintDrawer is simple enough to not need a Stack unless
    // we want the backdrop to be part of it. But usually drawers are overlay.
    // Let's keep the Stack structure for consistency with other drawers.

    if (!isOpen) return const SizedBox.shrink();

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Drawer
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hint',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: appColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'A little help to get you started',
                              style: TextStyle(
                                fontSize: 12,
                                color: appColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: appColors.inputBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: appColors.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/x.svg',
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                appColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  color: appColors.border.withValues(alpha: 0.5),
                  height: 1,
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: RichTextParser.buildRichText(
                          context,
                          hintContent,
                        ),
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
