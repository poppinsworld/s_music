import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/song_tile.dart';
import '../../theme/app_colors.dart';
import '../library/song_provider.dart';
import '../player/player_provider.dart';
import 'favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds   = ref.watch(favoritesProvider);
    final songState     = ref.watch(songProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    // Filter all scanned songs to only liked ones, preserving scan order
    final favoriteSongs = songState.songs
        .where((s) => favoriteIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liked Songs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            Text(
              '${favoriteSongs.length} song${favoriteSongs.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (favoriteSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.secondary,
                  size: 36,
                ),
                onPressed: () {
                  playerNotifier.loadSong(favoriteSongs.first, favoriteSongs);
                },
              ),
            ),
        ],
      ),
      body: favoriteSongs.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 140),
              itemCount: favoriteSongs.length,
              itemBuilder: (context, index) {
                final song = favoriteSongs[index];
                return SongTile(song: song, queue: favoriteSongs);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neon heart glow container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.20),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.10),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Liked Songs Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the ♡ icon on any song\nto add it to your Liked Songs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
