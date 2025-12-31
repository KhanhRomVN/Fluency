import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/quiz/presentation/widgets/media_player.dart';
import 'package:fluency/features/quiz/presentation/widgets/rich_text_parser.dart';
import 'package:flutter/material.dart';

class TranscriptDrawer extends StatelessWidget {
  const TranscriptDrawer({
    super.key,
    required this.transcript,
    required this.audioPath,
  });

  final String transcript;
  final String? audioPath;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                children: RichTextParser.buildRichText(context, transcript),
              ),
            ),
          ),
          // Media Player (Pinned to bottom of drawer)
          if (audioPath != null)
            MediaPlayer(
              key: ValueKey(audioPath! + '_drawer'), // Unique key
              audioPath: audioPath!,
              title: audioPath!.split('/').last,
            ),
        ],
      ),
    );
  }
}
