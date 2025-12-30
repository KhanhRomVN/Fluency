import 'package:flutter/material.dart';

class QuizMultipleChoice extends StatelessWidget {
  const QuizMultipleChoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Multiple Choice Question',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('What is the correct answer?'),
        const SizedBox(height: 20),
        ...List.generate(
            4,
            (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('Option ${index + 1}'),
                  ),
                )),
      ],
    );
  }
}
