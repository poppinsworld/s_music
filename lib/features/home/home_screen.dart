import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../shared/section_header.dart';
import '../../shared/album_card.dart';
import '../../theme/app_colors.dart';
import '../library/song_provider.dart';
import '../player/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songState = ref.watch(songProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140), // Space for mini player
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Evening', style: Theme.of(context).textTheme.headlineMedium),
                        Text('Let\'s enjoy some music', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                  ],
                ),
              ),
              // Hero Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryVariant, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 24,
                      top: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Discover\nYour Flow', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Music for every moment', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Local Tracks', actionText: 'See all'),
              
              if (songState.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (!songState.hasPermission)
                _buildPermissionState(context, ref)
              else if (songState.songs.isEmpty)
                _buildEmptyState(context)
              else
                ...songState.songs.take(5).map((song) => _buildSongRow(context, song, playerNotifier)),
              
              const SizedBox(height: 16),
              const SectionHeader(title: 'Made for You', actionText: 'See all'),
              SizedBox(
                height: 200,
                child: ListView(
                  padding: const EdgeInsets.only(right: 16),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    AlbumCard(title: 'Chill Vibes', subtitle: 'Mix'),
                    AlbumCard(title: 'Night Ride', subtitle: 'Mix'),
                    AlbumCard(title: 'Focus Flow', subtitle: 'Mix'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.folder_off_rounded, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text('Storage Permission Required', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('We need permission to scan your local music.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.read(songProvider.notifier).requestPermissions(),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.music_off_rounded, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text('No Local Music Found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Download some songs to get started.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSongRow(BuildContext context, SongModel song, PlayerNotifier playerNotifier) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
        artworkBorder: BorderRadius.circular(8),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
      trailing: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      onTap: () {
        playerNotifier.loadSong(song);
      },
    );
  }
}
