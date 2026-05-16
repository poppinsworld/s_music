import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SMusicApp()));
}

class SMusicApp extends ConsumerWidget {
  const SMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'S_Music',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
