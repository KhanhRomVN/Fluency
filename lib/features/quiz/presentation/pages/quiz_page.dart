import 'package:flutter/material.dart';
import '../widgets/quiz_multiple_choice.dart';
import '../widgets/quiz_match.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            Text('Quiz Templates Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(),
            SizedBox(height: 20),
            QuizMultipleChoice(),
            SizedBox(height: 40),
            Divider(),
            SizedBox(height: 20),
            QuizMatch(),
          ],
        ),
      ),
    );
  }
}
