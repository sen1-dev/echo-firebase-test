import 'package:flutter/material.dart';
import 'result_summary_screen.dart';

class TestGameScreen extends StatelessWidget {
  const TestGameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audiometry Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unity Audiometry Game Placeholder', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ResultSummaryScreen()),
                );
              },
              child: const Text('Finish Test'),
            ),
          ],
        ),
      ),
    );
  }
} 