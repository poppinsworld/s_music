import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../shared/up_next_sheet.dart';
import '../../shared/favorite_button.dart';
import '../../shared/add_to_playlist_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/dynamic_theme_provider.dart';
import '../lyrics/lyrics_widget.dart';
import '../equalizer/equalizer_sheet.dart';
import 'player_provider.dart';

// ---------------------------------------------------------------------------
// PlayerScreen — uses granular select() so position ticks do NOT rebuild
// the artwork or song-info widgets; only the slider / timestamps rebuild.
// ---------------------------------------------------------------------------
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Non-position state — rebuilds only when song / flags change
    final currentSong   = ref.watch(playerProvider.select((s) => s.currentSong));
    final isPlaying     = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isShuffle     = ref.watch(playerProvider.select((s) => s.isShuffle));
    final isRepeat      = ref.watch(playerProvider.select((s) => s.isRepeat));
    // Position state — rebuilds on every tick, but only reaches the slider
    final position      = ref.watch(playerProvider.select((s) => s.currentPosition));
    final total         = ref.watch(playerProvider.select((s) => s.totalDuration));
    // Dynamic theme — rebuilds only when song changes (palette extraction)
    final dynTheme      = ref.watch(dynamicThemeProvider);

    final notifier = ref.read(playerProvider.notifier);
    final progressValue = total.inSeconds > 0
        ? (position.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      body: AnimatedContainer(
        // Smooth 700ms color transition when song changes
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [dynTheme.backgroundStart, dynTheme.backgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────────────────
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong?.album ?? 'Unknown Album',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Colors.white),
                          onPressed: () => showEqualizerSheet(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          onPressed: () {
                            if (currentSong != null) {
                              showAddToPlaylistSheet(context, currentSong);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ── Album artwork or Lyrics ───────────────────────────────────
              ArtworkLyricsSwitcher(
                currentSong: currentSong,
                isPlaying: isPlaying,
                glowColor: dynTheme.glowColor,
                accentColor: dynTheme.accentColor,
              ),
              const Spacer(),
              // ── Song info ─────────────────────────────────────────────────
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
                            currentSong?.title ?? 'No Song Selected',
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
                            currentSong?.artist ?? 'Unknown Artist',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (currentSong != null)
                      FavoriteButton(
                        songId: currentSong.id,
                        size: 32,
                        activeColor: dynTheme.glowColor,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Progress slider (only this subtree rebuilds on position) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: dynTheme.glowColor,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                        thumbColor: dynTheme.glowColor,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: progressValue,
                        onChanged: (v) {
                          final pos = Duration(seconds: (v * total.inSeconds).round());
                          notifier.seek(pos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white54, fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(total),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white54, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── Playback controls ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     IconButton(
                       icon: Icon(Icons.shuffle_rounded,
                           color: isShuffle ? dynTheme.glowColor : Colors.white54, size: 28),
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
                          gradient: LinearGradient(
                            colors: [dynTheme.glowColor, dynTheme.accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: dynTheme.glowColor.withValues(alpha: isPlaying ? 0.55 : 0.25),
                              blurRadius: isPlaying ? 32 : 16,
                              spreadRadius: isPlaying ? 4 : 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            key: ValueKey(isPlaying),
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42),
                      onPressed: () => notifier.skipNext(),
                    ),
                     IconButton(
                       icon: Icon(Icons.repeat_rounded,
                           color: isRepeat ? dynTheme.glowColor : Colors.white54, size: 28),
                       onPressed: () => notifier.toggleRepeat(),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Up Next button ────────────────────────────────────────────
              TextButton.icon(
                onPressed: () => showUpNextSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
                icon: const Icon(Icons.queue_music_rounded, size: 20),
                label: const Text(
                  'Up Next',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PremiumAlbumArtwork
//
// KEY DESIGN DECISIONS for flicker elimination:
//  1. Keyed by songId at the call site — Flutter reuses the element when
//     the same song is playing, so QueryArtworkWidget never re-runs its
//     internal FutureBuilder unless the song actually changes.
//  2. The QueryArtworkWidget is the `child` passed to AnimatedBuilder — it
//     is built only ONCE and cached; the AnimatedBuilder rebuilds only the
//     outer Container (shadows) every frame.
//  3. RepaintBoundary around the artwork prevents the shadow animation from
//     propagating a repaint into the image layer.
// ---------------------------------------------------------------------------
class PremiumAlbumArtwork extends StatefulWidget {
  final SongModel? currentSong;
  final bool isPlaying;
  /// Dynamic glow color derived from album artwork palette
  final Color glowColor;
  /// Dynamic accent color (complement) derived from album artwork palette
  final Color accentColor;

  const PremiumAlbumArtwork({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    this.glowColor = AppColors.primary,
    this.accentColor = AppColors.secondary,
  });

  @override
  State<PremiumAlbumArtwork> createState() => _PremiumAlbumArtworkState();
}

class _PremiumAlbumArtworkState extends State<PremiumAlbumArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PremiumAlbumArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
        );
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
    final size = MediaQuery.of(context).size.width * 0.85;

    // Build the artwork image widget once. It is passed as `child` to
    // AnimatedBuilder so Flutter never rebuilds or repaints it during glow
    // animation frames.
    final artworkChild = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: widget.currentSong != null
            ? QueryArtworkWidget(
                id: widget.currentSong!.id,
                type: ArtworkType.AUDIO,
                artworkBorder: BorderRadius.circular(32),
                artworkWidth: size,
                artworkHeight: size,
                artworkFit: BoxFit.cover,
                keepOldArtwork: true,   // prevents artwork flash during rebuilds
                nullArtworkWidget: _Fallback(size: size),
              )
            : _Fallback(size: size),
      ),
    );

    return AnimatedBuilder(
      animation: _glow,
      child: artworkChild, // cached — not rebuilt every animation frame
      builder: (context, child) {
        final v = _glow.value;

        // Layer 1 — tight neon edge (corner emphasis)
        final coreAlpha   = 0.25 + 0.20 * v; // 0.25 → 0.45
        final coreBlur    = 18.0 + 14.0 * v;  // 18  → 32
        final coreSpread  = 2.0  + 4.0  * v;  // 2   → 6

        // Layer 2 — wide atmospheric halo
        final haloAlpha   = 0.18 + 0.17 * v; // 0.18 → 0.35
        final haloBlur    = 72.0 + 38.0 * v;  // 72  → 110
        final haloSpread  = 8.0  + 10.0 * v;  // 8   → 18

        // Layer 3 — top secondary accent (pink)
        final topAlpha    = 0.14 + 0.16 * v; // 0.14 → 0.30
        final topBlur     = 42.0 + 23.0 * v;  // 42  → 65
        final topSpread   = 0.0  + 6.0  * v;  // 0   → 6

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.glowColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              // Wide atmospheric halo (bottom) — dynamic color
              BoxShadow(
                color: widget.glowColor.withValues(alpha: haloAlpha),
                blurRadius: haloBlur,
                spreadRadius: haloSpread,
                offset: const Offset(0, 20),
              ),
              // Tight neon edge / corner glow — dynamic color
              BoxShadow(
                color: widget.glowColor.withValues(alpha: coreAlpha),
                blurRadius: coreBlur,
                spreadRadius: coreSpread,
                offset: const Offset(0, 4),
              ),
              // Top accent (chroma complement) — dynamic color
              BoxShadow(
                color: widget.accentColor.withValues(alpha: topAlpha),
                blurRadius: topBlur,
                spreadRadius: topSpread,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          // child is the cached, non-rebuilding artwork widget
          child: child,
        );
      },
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  const _Fallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 100, color: Colors.white54),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ArtworkLyricsSwitcher
// Toggles smoothly between the Album Artwork and the Synchronized Lyrics
// ---------------------------------------------------------------------------
class ArtworkLyricsSwitcher extends StatefulWidget {
  final SongModel? currentSong;
  final bool isPlaying;
  final Color glowColor;
  final Color accentColor;

  const ArtworkLyricsSwitcher({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    required this.glowColor,
    required this.accentColor,
  });

  @override
  State<ArtworkLyricsSwitcher> createState() => _ArtworkLyricsSwitcherState();
}

class _ArtworkLyricsSwitcherState extends State<ArtworkLyricsSwitcher> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.85;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showLyrics = !_showLyrics;
            });
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showLyrics
                ? SizedBox(
                    key: const ValueKey('lyrics'),
                    height: size,
                    width: size,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: LyricsWidget(
                          glowColor: widget.glowColor,
                          accentColor: widget.accentColor,
                        ),
                      ),
                    ),
                  )
                : PremiumAlbumArtwork(
                    key: ValueKey(widget.currentSong?.id ?? 0),
                    currentSong: widget.currentSong,
                    isPlaying: widget.isPlaying,
                    glowColor: widget.glowColor,
                    accentColor: widget.accentColor,
                  ),
          ),
        ),
        const SizedBox(height: 20),
        // Indicator dots for Artwork / Lyrics
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _showLyrics ? 6 : 20,
              height: 4,
              decoration: BoxDecoration(
                color: _showLyrics ? Colors.white.withValues(alpha: 0.3) : widget.glowColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _showLyrics ? 20 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: _showLyrics ? widget.glowColor : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

