import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/theme/dynamic_theme_provider.dart';
import '../features/player/player_provider.dart';
import 'favorite_button.dart';
import 'glass_container.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final isPlaying   = ref.watch(playerProvider.select((s) => s.isPlaying));
    final notifier    = ref.read(playerProvider.notifier);

    // Dynamic accent — granular selects, only rebuild when colors change
    final glowColor   = ref.watch(dynamicThemeProvider.select((t) => t.glowColor));
    final accentColor = ref.watch(dynamicThemeProvider.select((t) => t.accentColor));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () => context.push('/player'),
        child: AnimatedContainer(
          // Smooth 600ms transition when song/theme changes
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Subtle dynamic border glow — replaces static glassBorder
            border: Border.all(
              color: glowColor.withValues(alpha: isPlaying ? 0.35 : 0.15),
              width: 1.0,
            ),
            boxShadow: [
              // Ambient edge glow matching artwork palette
              BoxShadow(
                color: glowColor.withValues(alpha: isPlaying ? 0.12 : 0.05),
                blurRadius: 16,
                spreadRadius: 0,
                offset: Offset.zero,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // ── Glass card body ──────────────────────────────────────────
                GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: 12,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        // ── Artwork thumbnail ────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            // Dynamic fallback gradient when no artwork
                            gradient: LinearGradient(
                              colors: [glowColor, accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: currentSong != null
                              ? QueryArtworkWidget(
                                  id: currentSong.id,
                                  type: ArtworkType.AUDIO,
                                  artworkBorder: BorderRadius.circular(8),
                                  keepOldArtwork: true,
                                  nullArtworkWidget: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              : const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // ── Song info ────────────────────────────────────────
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong?.title ?? 'No Song Selected',
                                style: Theme.of(context).textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentSong?.artist ?? 'Unknown Artist',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (currentSong != null) ...[
                          FavoriteButton(
                            songId: currentSong.id,
                            size: 22,
                            activeColor: glowColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        // ── Play/Pause — dynamic icon tint when playing ──────
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(isPlaying),
                              // Neon tint when playing, white when paused
                              color: isPlaying ? glowColor : Colors.white,
                            ),
                          ),
                          onPressed: () => notifier.togglePlay(),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Top neon accent hairline ─────────────────────────────────
                // A single pixel-thin gradient line that breathes with the theme
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          glowColor.withValues(alpha: isPlaying ? 0.60 : 0.22),
                          accentColor.withValues(alpha: isPlaying ? 0.45 : 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // ── Progress bar (bottom) ────────────────────────────────────
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniPlayerProgressBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiniPlayerProgressBar extends ConsumerWidget {
  const MiniPlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position    = ref.watch(playerProvider.select((s) => s.currentPosition));
    final duration    = ref.watch(playerProvider.select((s) => s.totalDuration));
    // Dynamic accent — granular select so only color changes trigger a rebuild
    final glowColor   = ref.watch(dynamicThemeProvider.select((t) => t.glowColor));
    final accentColor = ref.watch(dynamicThemeProvider.select((t) => t.accentColor));

    final totalMs = duration.inMilliseconds;
    final progress = totalMs > 0 ? position.inMilliseconds / totalMs : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: clampedProgress),
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Container(
          height: 2.5,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.05),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [glowColor, accentColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
