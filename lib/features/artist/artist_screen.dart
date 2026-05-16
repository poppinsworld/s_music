import 'package:flutter/material.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist')),
      body: const Center(
        child: Text('Artist UI Placeholder'),
      ),
    );
  }
}
