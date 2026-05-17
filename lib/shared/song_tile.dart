import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/player/player_provider.dart';
import '../theme/app_colors.dart';

class SongTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel> queue;

  const SongTile({
    super.key,
    required this.song,
    required this.queue,
  });

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Highly optimized watchers: watch only current song state and whether it is playing
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isCurrent = currentSong?.id == song.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        onTap: () {
          ref.read(playerProvider.notifier).loadSong(song, queue);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrent 
                ? AppColors.primary.withOpacity(0.05) 
                : Colors.transparent,
            border: isCurrent 
                ? Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.0)
                : Border.all(color: Colors.transparent, width: 1.0),
          ),
          child: Row(
            children: [
              // Artwork container with glow effect if active
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isCurrent)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: isCurrent
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isCurrent ? null : AppColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                        ),
                        artworkBorder: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isCurrent ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side: Music Wave Indicator (equalizer) & Duration
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrent) ...[
                    MusicWaveIndicator(isPlaying: isPlaying),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _formatDuration(song.duration ?? 0),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MusicWaveIndicator extends StatefulWidget {
  final bool isPlaying;
  const MusicWaveIndicator({super.key, required this.isPlaying});

  @override
  State<MusicWaveIndicator> createState() => _MusicWaveIndicatorState();
}

class _MusicWaveIndicatorState extends State<MusicWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MusicWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              double heightFactor = 0.2;
              if (widget.isPlaying) {
                final value = _controller.value;
                if (index == 0) {
                  heightFactor = 0.2 + 0.8 * (math.sin(value * 2 * math.pi).abs());
                } else if (index == 1) {
                  heightFactor = 0.2 + 0.8 * (math.sin((value + 0.35) * 2 * math.pi).abs());
                } else {
                  heightFactor = 0.2 + 0.8 * (math.sin((value + 0.7) * 2 * math.pi).abs());
                }
              }
              return Container(
                width: 3.0,
                height: 16 * heightFactor,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
