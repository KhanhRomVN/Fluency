import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/note/presentation/widgets/note_card.dart';
import 'package:flutter/material.dart';

class NotePage extends StatelessWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    // Mock data for initial implementation
    final notes = [
      {
        'title': 'New vocabulary from "Master Vocabulary"',
        'content': 'Implement, Aesthetic, Seamless, Integration...',
        'date': 'Mar 18, 2026',
      },
      {
        'title': 'Grammar Notes',
        'content': 'Present Perfect vs Past Simple usage in formal contexts.',
        'date': 'Mar 17, 2026',
      },
      {
        'title': 'Ideas for Fluency',
        'content': 'Add a voice note feature to term cards.',
        'date': 'Mar 16, 2026',
      },
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notes',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            title: note['title']!,
            content: note['content']!,
            date: note['date']!,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future: Add new note implementation
        },
        backgroundColor: colors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
