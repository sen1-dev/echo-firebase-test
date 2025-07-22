import 'package:flutter/material.dart';
import 'test_history_screen.dart';

class ResultSummaryScreen extends StatelessWidget {
  const ResultSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Summary')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Test Results Placeholder', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
                );
              },
              child: const Text('Go to Test History'),
            ),
          ],
        ),
      ),
    );
  }
} 