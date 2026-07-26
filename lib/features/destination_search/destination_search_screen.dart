/// Placeholder screen for destination discovery.
library;

import 'package:flutter/material.dart';

class DestinationSearchScreen extends StatelessWidget {
  const DestinationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destination Search')),
      body: const Center(child: Text('Destination search placeholder')),
    );
  }
}
