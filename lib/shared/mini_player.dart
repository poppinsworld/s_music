import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/player/player_provider.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GlassContainer(
        onTap: () => context.push('/player'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: playerState.currentSong != null 
                  ? QueryArtworkWidget(
                      id: playerState.currentSong!.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(8),
                      nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white, size: 24),
                    )
                  : const Icon(Icons.music_note, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playerState.currentSong?.title ?? 'No Song Selected', style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(playerState.currentSong?.artist ?? 'Unknown Artist', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(playerState.isPlaying),
                  color: Colors.white,
                ),
              ),
              onPressed: () => notifier.togglePlay(),
            ),
          ],
        ),
      ),
    );
  }
}
