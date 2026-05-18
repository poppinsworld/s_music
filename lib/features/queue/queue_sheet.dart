import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../player/player_provider.dart';
import '../theme/app_colors.dart';
import '../../shared/song_options_sheet.dart';

void showQueueSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => const _QueueSheetBody(),
  );
}

class _QueueSheetBody extends ConsumerStatefulWidget {
  const _QueueSheetBody();
  @override
  ConsumerState<_QueueSheetBody> createState() => _QueueSheetBodyState();
}

class _QueueSheetBodyState extends ConsumerState<_QueueSheetBody> {
  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playerProvider.select((s) => s.queue));
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
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
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Playback Queue', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                        const SizedBox(height: 2),
                        Text('${queue.length} songs', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              
              Expanded(
                child: queue.isEmpty
                    ? const Center(child: Text('Queue is empty', style: TextStyle(color: Colors.white54)))
                    : ReorderableListView.builder(
                        scrollController: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32, top: 8),
                        itemCount: queue.length,
                        onReorder: (oldIndex, newIndex) {
                          ref.read(playerProvider.notifier).reorderQueue(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2)],
                              ),
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isCurrent = song.id == currentSong?.id;
                          return Dismissible(
                            key: ValueKey('${song.id}_$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              ref.read(playerProvider.notifier).removeFromQueue(index);
                            },
                            child: _QueueTile(
                              song: song,
                              index: index,
                              isCurrent: isCurrent,
                              isPlaying: isPlaying,
                            ),
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

class _QueueTile extends ConsumerWidget {
  final SongModel song;
  final int index;
  final bool isCurrent;
  final bool isPlaying;

  const _QueueTile({required this.song, required this.index, required this.isCurrent, required this.isPlaying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: isCurrent ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: () {
          final queue = ref.read(playerProvider).queue;
          ref.read(playerProvider.notifier).loadSong(song, queue);
        },
        onLongPress: () {
          showSongOptionsSheet(context, song);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isCurrent ? BoxDecoration(border: Border(left: BorderSide(color: AppColors.primary, width: 3))) : null,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: isCurrent ? _MiniWave(isPlaying: isPlaying) : Text('${index + 1}', style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44, height: 44,
                  child: QueryArtworkWidget(
                    id: song.id, type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(8),
                    nullArtworkWidget: Container(color: AppColors.surface, child: const Icon(Icons.music_note, color: Colors.white30, size: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCurrent ? AppColors.primary : Colors.white, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isCurrent ? AppColors.primary.withValues(alpha: 0.65) : Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.drag_handle_rounded, color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    if (widget.isPlaying != old.isPlaying) widget.isPlaying ? _ctrl.repeat() : _ctrl.stop();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18, height: 18,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            double h = 4;
            if (widget.isPlaying) h = 4 + 10 * math.sin((_ctrl.value + i * 0.33) * 2 * math.pi).abs();
            return Container(width: 3, height: h, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1.5)));
          }),
        ),
      ),
    );
  }
}
