import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../shared/playlist_row.dart';
import 'song_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songState = ref.watch(songProvider);
    final songCount = songState.isLoading ? '...' : songState.songs.length.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          children: [
            _buildLibraryItem(
              context,
              Icons.music_note,
              'Songs',
              songCount,
              onTap: () => context.push('/songs'),
            ),
            _buildLibraryItem(context, Icons.album, 'Albums', '0'),
            _buildLibraryItem(context, Icons.person, 'Artists', '0'),
            _buildLibraryItem(context, Icons.playlist_play, 'Playlists', '0'),
            _buildLibraryItem(context, Icons.category, 'Genres', '0'),
            _buildLibraryItem(context, Icons.favorite, 'Liked Songs', '0', isLiked: true),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recently Added', style: Theme.of(context).textTheme.titleLarge),
                  Text('See all', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (songState.songs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No local songs available yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ...songState.songs.take(3).map((song) => PlaylistRow(
                    title: song.title,
                    subtitle: song.artist ?? 'Unknown Artist',
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    BuildContext context,
    IconData icon,
    String title,
    String count, {
    bool isLiked = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLiked ? AppColors.secondary : AppColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}
