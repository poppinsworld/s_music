import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/player/player_provider.dart';
import '../features/library/song_provider.dart';
import '../features/theme/app_colors.dart';
import 'mini_player.dart';

class BottomNavShell extends ConsumerWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(songProvider, (previous, next) {
      if (!next.isLoading && next.songs.isNotEmpty) {
        ref.read(playerProvider.notifier).tryRestoreQueue(next.songs);
      }
    });

    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                const SizedBox(height: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: currentIndex,
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                      BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
                      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                    ],
                    onTap: (index) => _onItemTapped(index, context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/library'); break;
      case 2: context.go('/search'); break;
      case 3: context.go('/settings'); break;
    }
  }
}
