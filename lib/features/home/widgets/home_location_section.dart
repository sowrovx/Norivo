import 'package:flutter/material.dart';

import '../../../shared/widgets/current_location_map_card.dart';

class HomeLocationSection extends StatelessWidget {
  const HomeLocationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your current area',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        const CurrentLocationMapCard(),
      ],
    );
  }
}
