/// Reusable placeholder widget for early feature scaffolding.
library;

import 'package:flutter/material.dart';

class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
      ),
    );
  }
}
