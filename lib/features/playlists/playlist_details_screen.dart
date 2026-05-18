import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/song_tile.dart';
import '../../theme/app_colors.dart';
import '../library/song_provider.dart';
import '../player/player_provider.dart';
import 'playlist_provider.dart';

class PlaylistDetailsScreen extends ConsumerWidget {
  final String playlistId;
  const PlaylistDetailsScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final songState = ref.watch(songProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    // Find the current playlist
    final playlist = playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: '', name: 'Not Found', songIds: []),
    );

    if (playlist.id.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Playlist not found.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    // Filter local songs to match those inside this playlist
    final playlistSongs = songState.songs
        .where((s) => playlist.songIds.contains(s.id))
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
            Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              '${playlistSongs.length} song${playlistSongs.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (playlistSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: AppColors.secondary,
                  size: 36,
                ),
                onPressed: () {
                  playerNotifier.loadSong(playlistSongs.first, playlistSongs);
                },
              ),
            ),
        ],
      ),
      body: playlistSongs.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 140),
              itemCount: playlistSongs.length,
              itemBuilder: (context, index) {
                final song = playlistSongs[index];

                return Dismissible(
                  key: ValueKey('playlist_${playlist.id}_${song.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (direction) {
                    ref
                        .read(playlistProvider.notifier)
                        .removeSongFromPlaylist(playlist.id, song.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${song.title}"'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Colors.white,
                          onPressed: () {
                            ref
                                .read(playlistProvider.notifier)
                                .addSongToPlaylist(playlist.id, song.id);
                          },
                        ),
                      ),
                    );
                  },
                  child: SongTile(song: song, queue: playlistSongs),
                );
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
                Icons.music_note_rounded,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'This Playlist is Empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Long press on any song in the app\nto add it to this playlist.',
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
