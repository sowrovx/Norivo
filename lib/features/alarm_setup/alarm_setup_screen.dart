/// Placeholder screen for configuring alarms.
library;

import 'package:flutter/material.dart';

class AlarmSetupScreen extends StatelessWidget {
  const AlarmSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm Setup')),
      body: const Center(child: Text('Alarm setup placeholder')),
    );
  }
}
