import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/player/player_provider.dart';
import '../features/theme/app_colors.dart';
import '../shared/add_to_playlist_sheet.dart';

void showSongOptionsSheet(BuildContext context, SongModel song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _SongOptionsSheet(song: song),
  );
}

class _SongOptionsSheet extends ConsumerWidget {
  final SongModel song;
  const _SongOptionsSheet({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(song.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            
            // Actions
            ListTile(
              leading: const Icon(Icons.queue_play_next_rounded, color: Colors.white70),
              title: const Text('Play Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () {
                ref.read(playerProvider.notifier).playNext(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Will play next'), backgroundColor: AppColors.primary, duration: const Duration(seconds: 1)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
              title: const Text('Add to Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () {
                ref.read(playerProvider.notifier).addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to queue'), backgroundColor: AppColors.primary, duration: const Duration(seconds: 1)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_circle_rounded, color: Colors.white70),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                showAddToPlaylistSheet(context, song);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
