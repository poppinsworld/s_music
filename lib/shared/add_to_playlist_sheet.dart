import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/playlists/playlist_provider.dart';
import '../features/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// showAddToPlaylistSheet
//
// Shows a premium bottom sheet to add a given song to a playlist.
// ---------------------------------------------------------------------------
void showAddToPlaylistSheet(BuildContext context, SongModel song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AddToPlaylistSheet(song: song),
  );
}

class AddToPlaylistSheet extends ConsumerWidget {
  final SongModel song;
  const AddToPlaylistSheet({super.key, required this.song});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter playlist name...',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.secondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C0C0C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white10, width: 1.0),
            ),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add to Playlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => _showCreateDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
              Expanded(
                child: playlists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.playlist_add_rounded,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Playlists Yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showCreateDialog(context, ref),
                              child: const Text('Create New Playlist'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final hasSong = playlist.songIds.contains(song.id);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.playlist_play_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist.songIds.length} song${playlist.songIds.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white30, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                hasSong
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: hasSong ? AppColors.secondary : Colors.white54,
                              ),
                              onPressed: () {
                                if (hasSong) {
                                  ref
                                      .read(playlistProvider.notifier)
                                      .removeSongFromPlaylist(playlist.id, song.id);
                                } else {
                                  ref
                                      .read(playlistProvider.notifier)
                                      .addSongToPlaylist(playlist.id, song.id);
                                  // Instantly close sheet on successful add with a minor toast/feedback delay
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added to ${playlist.name}'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: AppColors.secondary,
                                    ),
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              if (!hasSong) {
                                ref
                                    .read(playlistProvider.notifier)
                                    .addSongToPlaylist(playlist.id, song.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added to ${playlist.name}'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: AppColors.secondary,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
