import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerState {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isShuffle;
  final bool isRepeat;
  final SongModel? currentSong;

  PlayerState({
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(minutes: 3, seconds: 49),
    this.isShuffle = false,
    this.isRepeat = false,
    this.currentSong,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isShuffle,
    bool? isRepeat,
    SongModel? currentSong,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      currentSong: currentSong ?? this.currentSong,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(PlayerState());
  
  Timer? _timer;

  void loadSong(SongModel song) {
    state = state.copyWith(
      currentSong: song,
      totalDuration: Duration(milliseconds: song.duration ?? 0),
      currentPosition: Duration.zero,
      isPlaying: true,
    );
    _startTimer();
  }

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
    if (state.isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.currentPosition >= state.totalDuration) {
        state = state.copyWith(currentPosition: Duration.zero, isPlaying: false);
        timer.cancel();
      } else {
        state = state.copyWith(
          currentPosition: state.currentPosition + const Duration(seconds: 1),
        );
      }
    });
  }

  void seek(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }

  void skipNext() {
    state = state.copyWith(currentPosition: Duration.zero);
  }

  void skipPrevious() {
    state = state.copyWith(currentPosition: Duration.zero);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});

