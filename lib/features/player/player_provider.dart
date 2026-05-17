import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

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

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];

  PlayerNotifier() : super(PlayerState()) {
    _init();
  }

  void _init() {
    // Sync playing state
    _subscriptions.add(_audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    }));

    // Sync position
    _subscriptions.add(_audioPlayer.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    }));

    // Sync duration
    _subscriptions.add(_audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(totalDuration: duration);
      }
    }));

    // Sync processing state (e.g. for auto-next)
    _subscriptions.add(_audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        skipNext();
      }
    }));
  }

  Future<void> loadSong(SongModel song, List<SongModel> queue) async {
    try {
      state = state.copyWith(
        currentSong: song,
        queue: queue,
        currentPosition: Duration.zero,
      );
      
      await _audioPlayer.setFilePath(song.data);
      _audioPlayer.play();
    } catch (e) {
      // Handle error (invalid file, etc)
      state = state.copyWith(isPlaying: false);
    }
  }

  void togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      if (state.currentSong != null) {
        _audioPlayer.play();
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
    state = state.copyWith(isShuffle: !state.isShuffle);
    // Note: just_audio has its own shuffle but we are doing it manually for now
    // to keep it simple as per requirements.
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
    _audioPlayer.setLoopMode(state.isRepeat ? LoopMode.one : LoopMode.off);
  }

  void skipNext() {
    if (state.queue.isEmpty || state.currentSong == null) return;
    
    final currentIndex = state.queue.indexWhere((s) => s.id == state.currentSong!.id);
    if (currentIndex != -1 && currentIndex < state.queue.length - 1) {
      loadSong(state.queue[currentIndex + 1], state.queue);
    } else if (state.isRepeat) {
      loadSong(state.queue[0], state.queue);
    }
  }

  void skipPrevious() {
    if (state.queue.isEmpty || state.currentSong == null) return;

    // If we are more than 3 seconds into the song, restart it
    if (state.currentPosition.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    final currentIndex = state.queue.indexWhere((s) => s.id == state.currentSong!.id);
    if (currentIndex > 0) {
      loadSong(state.queue[currentIndex - 1], state.queue);
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

