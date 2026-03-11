import 'package:flutter/material.dart';

void main() {
  runApp(const AIEvolutionApp());
}

/// Root widget for the AI Evolution game.
class AIEvolutionApp extends StatelessWidget {
  const AIEvolutionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Evolution',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('AI Evolution — Loading…'),
        ),
      ),
    );
  }
}
