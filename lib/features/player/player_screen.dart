import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../theme/app_colors.dart';
import 'player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    final progressValue = playerState.totalDuration.inSeconds > 0 
        ? playerState.currentPosition.inSeconds / playerState.totalDuration.inSeconds 
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0B2E), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                      onPressed: () => context.pop(),
                    ),
                    Column(
                      children: [
                        Text(
                          'PLAYING FROM ALBUM', 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 2.0,
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playerState.currentSong?.album ?? 'Unknown Album', 
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Album Art with Premium Neon Glow
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuint,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(playerState.isPlaying ? 0.4 : 0.2),
                        blurRadius: playerState.isPlaying ? 100 : 60,
                        spreadRadius: playerState.isPlaying ? 10 : 0,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: -5,
                        offset: const Offset(0, -10),
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.0,
                    ),
                  ),
                  child: playerState.currentSong != null
                      ? QueryArtworkWidget(
                          id: playerState.currentSong!.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.circular(32),
                          artworkWidth: double.infinity,
                          artworkHeight: double.infinity,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: const Center(
                            child: Icon(Icons.music_note_rounded, size: 100, color: Colors.white54),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.music_note_rounded, size: 100, color: Colors.white54),
                        ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerState.currentSong?.title ?? 'No Song Selected', 
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            playerState.currentSong?.artist ?? 'Unknown Artist', 
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 32),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.15),
                        thumbColor: Colors.white,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: progressValue.clamp(0.0, 1.0), 
                        onChanged: (v) {
                          final newPosition = Duration(seconds: (v * playerState.totalDuration.inSeconds).round());
                          notifier.seek(newPosition);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerState.currentPosition), 
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white54,
                              fontWeight: FontWeight.w600,
                            )
                          ),
                          Text(
                            _formatDuration(playerState.totalDuration), 
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white54,
                              fontWeight: FontWeight.w600,
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded, 
                        color: playerState.isShuffle ? AppColors.primary : Colors.white54, 
                        size: 28
                      ), 
                      onPressed: () => notifier.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 42), 
                      onPressed: () => notifier.skipPrevious(),
                    ),
                    GestureDetector(
                      onTap: () => notifier.togglePlay(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(playerState.isPlaying ? 0.6 : 0.3),
                              blurRadius: playerState.isPlaying ? 32 : 16,
                              spreadRadius: playerState.isPlaying ? 4 : 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                            key: ValueKey(playerState.isPlaying),
                            color: Colors.white, 
                            size: 40
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42), 
                      onPressed: () => notifier.skipNext(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.repeat_rounded, 
                        color: playerState.isRepeat ? AppColors.primary : Colors.white54, 
                        size: 28
                      ), 
                      onPressed: () => notifier.toggleRepeat(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
