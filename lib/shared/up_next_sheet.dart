import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../features/player/player_provider.dart';
import '../theme/app_colors.dart';

/// Shows the Up Next bottom sheet and auto-scrolls to the current song.
void showUpNextSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => const _UpNextSheet(),
  );
}

// ---------------------------------------------------------------------------
// Sheet root — reads provider once via ConsumerWidget, passes data down.
// ---------------------------------------------------------------------------
class _UpNextSheet extends ConsumerWidget {
  const _UpNextSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue       = ref.watch(playerProvider.select((s) => s.queue));
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final isPlaying   = ref.watch(playerProvider.select((s) => s.isPlaying));

    return _UpNextSheetBody(
      queue: queue,
      currentSong: currentSong,
      isPlaying: isPlaying,
    );
  }
}

class _UpNextSheetBody extends StatefulWidget {
  final List<SongModel> queue;
  final SongModel?      currentSong;
  final bool            isPlaying;

  const _UpNextSheetBody({
    required this.queue,
    required this.currentSong,
    required this.isPlaying,
  });

  @override
  State<_UpNextSheetBody> createState() => _UpNextSheetBodyState();
}

class _UpNextSheetBodyState extends State<_UpNextSheetBody> {
  final ScrollController _scroll = ScrollController();
  static const double _tileHeight = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients || widget.currentSong == null) return;
    final idx = widget.queue.indexWhere((s) => s.id == widget.currentSong!.id);
    if (idx <= 0) return;
    final target = (idx * _tileHeight - 60.0).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
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

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Up Next',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.queue.length} songs in queue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Queue count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.queue_music_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.queue.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Thin divider ─────────────────────────────────────────────
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 4),

              // ── Queue list ───────────────────────────────────────────────
              Expanded(
                child: widget.queue.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: widget.queue.length,
                        itemExtent: _tileHeight,
                        itemBuilder: (context, index) {
                          final song = widget.queue[index];
                          final isCurrent = song.id == widget.currentSong?.id;
                          return _QueueTile(
                            song: song,
                            index: index,
                            isCurrent: isCurrent,
                            isPlaying: widget.isPlaying,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.queue_music_rounded, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            'Queue is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a song to start playing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual queue tile — self-contained Consumer for tap-to-play
// ---------------------------------------------------------------------------
class _QueueTile extends ConsumerWidget {
  final SongModel song;
  final int       index;
  final bool      isCurrent;
  final bool      isPlaying;

  const _QueueTile({
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
  });

  String _fmt(int? ms) {
    if (ms == null || ms == 0) return '0:00';
    final d = Duration(milliseconds: ms);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: isCurrent
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          final queue = ref.read(playerProvider).queue;
          ref.read(playerProvider.notifier).loadSong(song, queue);
        },
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isCurrent
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Row(
            children: [
              // Position index or wave indicator
              SizedBox(
                width: 28,
                child: isCurrent
                    ? _MiniWave(isPlaying: isPlaying)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 10),

              // Artwork thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(8),
                    artworkWidth: 44,
                    artworkHeight: 44,
                    artworkFit: BoxFit.cover,
                    keepOldArtwork: true,
                    nullArtworkWidget: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: isCurrent
                              ? [AppColors.primary, AppColors.secondary]
                              : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
                        ),
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: isCurrent ? Colors.white : Colors.white30,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + artist
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? AppColors.primary : Colors.white,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.65)
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Duration
              Text(
                _fmt(song.duration),
                style: TextStyle(
                  color: isCurrent ? AppColors.primary.withValues(alpha: 0.8) : Colors.white30,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact three-bar wave indicator for the queue tile
// ---------------------------------------------------------------------------
class _MiniWave extends StatefulWidget {
  final bool isPlaying;
  const _MiniWave({required this.isPlaying});

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_MiniWave old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _ctrl.repeat() : _ctrl.stop();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            double h = 4;
            if (widget.isPlaying) {
              final v = _ctrl.value;
              h = 4 + 10 * math.sin((v + i * 0.33) * 2 * math.pi).abs();
            }
            return Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
