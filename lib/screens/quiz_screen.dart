import 'package:flutter/material.dart';
import 'calibration_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<String> _questions = List.generate(10, (i) => 'Question ${i + 1}?');
  int _current = 0;
  List<bool?> _answers = List.filled(10, null);

  void _answer(bool value) {
    setState(() {
      _answers[_current] = value;
      if (_current < _questions.length - 1) {
        _current++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hearing Wellness Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_questions[_current], style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _answer(true),
                  child: const Text('Yes'),
                ),
                ElevatedButton(
                  onPressed: () => _answer(false),
                  child: const Text('No'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_current == _questions.length - 1 && _answers[_current] != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CalibrationScreen()),
                  );
                },
                child: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
} 