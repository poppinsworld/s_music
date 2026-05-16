import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) context.go('/home');
    });
    return const Scaffold(
      body: Center(
        child: Text('S_Music Splash'),
      ),
    );
  }
}
