/// Placeholder screen for the active journey experience.
library;

import 'package:flutter/material.dart';

class ActiveJourneyScreen extends StatelessWidget {
  const ActiveJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Journey')),
      body: const Center(child: Text('Active journey placeholder')),
    );
  }
}
