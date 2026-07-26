/// Placeholder screen used when an alarm is ringing.
library;

import 'package:flutter/material.dart';

class AlarmRingingScreen extends StatelessWidget {
  const AlarmRingingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm Ringing')),
      body: const Center(child: Text('Alarm ringing placeholder')),
    );
  }
}
