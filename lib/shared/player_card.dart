import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.music_note, size: 40),
            const SizedBox(width: 8),
            const Expanded(child: Text('Track Title Placeholder')),
            IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
