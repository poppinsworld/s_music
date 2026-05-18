import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

// ---------------------------------------------------------------------------
// PlayerState Model
// ---------------------------------------------------------------------------
class PlayerState {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isShuffle;
  final bool isRepeat;
  final SongModel? currentSong;
  final List<SongModel> queue;

  PlayerState({
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isShuffle = false,
    this.isRepeat = false,
    this.currentSong,
    this.queue = const [],
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isShuffle,
    bool? isRepeat,
    SongModel? currentSong,
    List<SongModel>? queue,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
    );
  }
}

// ---------------------------------------------------------------------------
// PlayerNotifier
// ---------------------------------------------------------------------------
class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];
  int _currentLoadSession = 0;

  PlayerNotifier() : super(PlayerState()) {
    _init();
  }

  void _init() {
    debugPrint('[PlayerNotifier] Initializing clean local playback engine');

    // Sync playing state
    _subscriptions.add(_audioPlayer.playingStream.listen((playing) {
      debugPrint('[PlayerNotifier] playingStream: $playing');
      state = state.copyWith(isPlaying: playing);
    }));

    // Sync position
    _subscriptions.add(_audioPlayer.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    }));

    // Sync duration
    _subscriptions.add(_audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        debugPrint('[PlayerNotifier] durationStream: $duration');
        state = state.copyWith(totalDuration: duration);
      }
    }));

    // Sync current index for automatic queue advancement
    _subscriptions.add(_audioPlayer.currentIndexStream.listen((index) {
      debugPrint('[PlayerNotifier] currentIndexStream: index=$index');
      if (index != null && index >= 0 && index < state.queue.length) {
        final song = state.queue[index];
        if (state.currentSong?.id != song.id) {
          debugPrint('[PlayerNotifier] Synced active song to: "${song.title}"');
          state = state.copyWith(currentSong: song);
        }
      }
    }));

    // Handle auto-advance at the end of a track
    _subscriptions.add(_audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        debugPrint('[PlayerNotifier] Track completed. Advancing queue...');
        skipNext();
      }
    }));
  }

  AudioSource? _buildSource(SongModel song) {
    // Strategy 1: Direct absolute file path (100% robust for local storage)
    if (song.data.isNotEmpty) {
      try {
        final file = File(song.data);
        if (file.existsSync()) {
          return AudioSource.uri(Uri.file(song.data));
        }
      } catch (e) {
        debugPrint('[PlayerNotifier] File path check failed for "${song.title}": $e');
      }
    }

    // Strategy 2: Fallback to content URI
    if (song.uri != null && song.uri!.isNotEmpty) {
      try {
        final contentUri = Uri.parse(song.uri!);
        return AudioSource.uri(contentUri);
      } catch (e) {
        debugPrint('[PlayerNotifier] Content URI parse failed for "${song.title}": $e');
      }
    }

    debugPrint('[PlayerNotifier] ❌ Failed to build playable source for: "${song.title}"');
    return null;
  }

  Future<void> loadSong(SongModel song, List<SongModel> queue, {bool forceFileUri = false}) async {
    final sessionId = ++_currentLoadSession;
    debugPrint('[PlayerNotifier] loadSong() sessionId=$sessionId, title="${song.title}"');

    if (queue.isEmpty) {
      debugPrint('[PlayerNotifier] Aborting loadSong: Queue is empty');
      return;
    }

    // Optimize: if the new queue is identical to the current one, seek directly to target song index
    if (_isSameQueue(queue) && _audioPlayer.audioSource != null) {
      final targetIndex = state.queue.indexWhere((s) => s.id == song.id);
      final finalIndex = targetIndex != -1 ? targetIndex : 0;
      final currentIdx = _audioPlayer.currentIndex ?? -1;

      debugPrint('[PlayerNotifier] Same queue active. currentIdx=$currentIdx, targetIdx=$finalIndex');

      if (currentIdx == finalIndex) {
        if (!_audioPlayer.playing) {
          await _safePlay();
        }
        return;
      }

      await _audioPlayer.seek(Duration.zero, index: finalIndex);
      await _safePlay();
      return;
    }

    try {
      final sources = <AudioSource>[];
      final validQueue = <SongModel>[];

      for (final s in queue) {
        final src = _buildSource(s);
        if (src != null) {
          sources.add(src);
          validQueue.add(s);
        }
      }

      if (sources.isEmpty) {
        throw Exception('No playable local audio sources could be found on the device.');
      }

      if (sessionId != _currentLoadSession) return;

      final targetIndex = validQueue.indexWhere((s) => s.id == song.id);
      final finalIndex = targetIndex != -1 ? targetIndex : 0;

      // Optimistically update Riverpod state so UI updates immediately
      state = state.copyWith(
        currentSong: validQueue[finalIndex],
        queue: validQueue,
        currentPosition: Duration.zero,
        totalDuration: Duration.zero,
      );

      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: sources,
      );

      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: finalIndex,
        initialPosition: Duration.zero,
      );

      if (sessionId != _currentLoadSession) return;

      await _safePlay();
    } catch (e) {
      if (sessionId != _currentLoadSession) return;
      debugPrint('[PlayerNotifier] ❌ Playback loading failed: $e');
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> _safePlay() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[PlayerNotifier] play() error: $e');
    }
  }

  bool _isSameQueue(List<SongModel> newQueue) {
    if (state.queue.length != newQueue.length) return false;
    for (int i = 0; i < newQueue.length; i++) {
      if (state.queue[i].id != newQueue[i].id) return false;
    }
    return true;
  }

  void togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      if (state.currentSong != null && _audioPlayer.audioSource != null) {
        _safePlay();
      }
    }
  }

  void stop() {
    _audioPlayer.stop();
    state = state.copyWith(isPlaying: false, currentPosition: Duration.zero);
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    final next = !state.isShuffle;
    state = state.copyWith(isShuffle: next);
    _audioPlayer.setShuffleModeEnabled(next);
  }

  void toggleRepeat() {
    final next = !state.isRepeat;
    state = state.copyWith(isRepeat: next);
    _audioPlayer.setLoopMode(next ? LoopMode.one : LoopMode.off);
  }

  void skipNext() {
    if (state.queue.isEmpty || _audioPlayer.audioSource == null) return;

    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    } else {
      // Loop back to start
      _audioPlayer.seek(Duration.zero, index: 0);
    }
  }

  void skipPrevious() {
    if (state.queue.isEmpty || _audioPlayer.audioSource == null) return;

    if (state.currentPosition.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
    } else {
      // Loop to end of queue
      _audioPlayer.seek(Duration.zero, index: state.queue.length - 1);
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});
