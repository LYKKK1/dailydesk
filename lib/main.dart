import 'package:flutter/material.dart';

void main() {
  runApp(const DailyDeskApp());
}

/// Placeholder app skeleton.
///
/// Theme, database, and window wiring arrive in later tasks.
class DailyDeskApp extends StatelessWidget {
  const DailyDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'DailyDesk',
      home: Scaffold(
        body: Center(
          child: Text('DailyDesk'),
        ),
      ),
    );
  }
}
