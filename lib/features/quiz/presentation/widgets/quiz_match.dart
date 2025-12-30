import 'package:flutter/material.dart';

class QuizMatch extends StatelessWidget {
  const QuizMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Match the items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: List.generate(
                  3,
                  (index) => Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[100],
                        child: Text('Item A${index + 1}'),
                      )),
            ),
            Column(
              children: List.generate(
                  3,
                  (index) => Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        color: Colors.green[100],
                        child: Text('Item B${index + 1}'),
                      )),
            ),
          ],
        ),
      ],
    );
  }
}
