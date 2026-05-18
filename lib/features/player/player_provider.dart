import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import '../queue/queue_service.dart';

enum RepeatMode { off, all, one }

class PlayerState {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final SongModel? currentSong;
  final List<SongModel> queue;

  PlayerState({
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
    this.currentSong,
    this.queue = const [],
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isShuffle,
    RepeatMode? repeatMode,
    SongModel? currentSong,
    List<SongModel>? queue,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  late final AndroidEqualizer androidEqualizer;
  late final AndroidLoudnessEnhancer androidLoudnessEnhancer;
  late final AudioPlayer _audioPlayer;
  ConcatenatingAudioSource? _playlist;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _positionSaveTimer;
  int _currentLoadSession = 0;
  bool _queueRestored = false;

  PlayerNotifier(this.ref) : super(PlayerState()) {
    androidEqualizer = AndroidEqualizer();
    androidLoudnessEnhancer = AndroidLoudnessEnhancer();
    _audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [androidEqualizer, androidLoudnessEnhancer],
      ),
    );
    _init();
  }

  void _init() {
    _subscriptions.add(_audioPlayer.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
      if (!playing) _persistQueueState();
    }));

    _subscriptions.add(_audioPlayer.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    }));

    _subscriptions.add(_audioPlayer.durationStream.listen((duration) {
      if (duration != null) state = state.copyWith(totalDuration: duration);
    }));

    _subscriptions.add(_audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < state.queue.length) {
        final song = state.queue[index];
        if (state.currentSong?.id != song.id) {
          state = state.copyWith(currentSong: song);
          _persistQueueState();
        }
      }
    }));

    _subscriptions.add(_audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        skipNext();
      }
    }));

    _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.isPlaying) _persistQueueState();
    });
  }

  void _persistQueueState() {
    if (state.queue.isEmpty) return;
    final ids = state.queue.map((s) => s.id).toList();
    final idx = _audioPlayer.currentIndex ?? 0;
    final pos = state.currentPosition.inMilliseconds;
    ref.read(queuePersistenceProvider).saveQueueState(
      songIds: ids, currentIndex: idx, positionMs: pos,
    );
  }

  Future<void> tryRestoreQueue(List<SongModel> allSongs) async {
    if (_queueRestored || allSongs.isEmpty) return;
    _queueRestored = true;
    
    final persistence = ref.read(queuePersistenceProvider);
    final data = await persistence.loadQueueState();
    if (data == null) return;
    
    final List<int> ids = data['songIds'];
    final int index = data['index'];
    final int posMs = data['positionMs'];
    
    final queue = <SongModel>[];
    for (final id in ids) {
      try {
        final song = allSongs.firstWhere((s) => s.id == id);
        queue.add(song);
      } catch (e) {}
    }
    
    if (queue.isNotEmpty) {
      final actualIndex = index < queue.length ? index : 0;
      await _loadSilent(queue[actualIndex], queue, Duration(milliseconds: posMs));
    }
  }

  AudioSource? _buildSource(SongModel song) {
    if (song.data.isNotEmpty) {
      try {
        final file = File(song.data);
        if (file.existsSync()) return AudioSource.uri(Uri.file(song.data));
      } catch (e) {}
    }
    if (song.uri != null && song.uri!.isNotEmpty) {
      try { return AudioSource.uri(Uri.parse(song.uri!)); } catch (e) {}
    }
    return null;
  }

  Future<void> loadSong(SongModel song, List<SongModel> queue) async {
    final sessionId = ++_currentLoadSession;
    if (queue.isEmpty) return;

    if (_isSameQueue(queue) && _audioPlayer.audioSource != null) {
      final targetIndex = state.queue.indexWhere((s) => s.id == song.id);
      final finalIndex = targetIndex != -1 ? targetIndex : 0;
      final currentIdx = _audioPlayer.currentIndex ?? -1;
      if (currentIdx == finalIndex) {
        if (!_audioPlayer.playing) await _safePlay();
        return;
      }
      await _audioPlayer.seek(Duration.zero, index: finalIndex);
      await _safePlay();
      return;
    }

    await _prepareAndPlay(song, queue, sessionId, true, Duration.zero);
  }

  Future<void> _loadSilent(SongModel song, List<SongModel> queue, Duration initialPos) async {
    final sessionId = ++_currentLoadSession;
    await _prepareAndPlay(song, queue, sessionId, false, initialPos);
  }

  Future<void> _prepareAndPlay(SongModel song, List<SongModel> queue, int sessionId, bool autoPlay, Duration initialPos) async {
    try {
      final sources = <AudioSource>[];
      final validQueue = <SongModel>[];
      for (final s in queue) {
        final src = _buildSource(s);
        if (src != null) { sources.add(src); validQueue.add(s); }
      }
      if (sources.isEmpty) throw Exception('No playable sources.');
      if (sessionId != _currentLoadSession) return;

      final targetIndex = validQueue.indexWhere((s) => s.id == song.id);
      final finalIndex = targetIndex != -1 ? targetIndex : 0;

      state = state.copyWith(currentSong: validQueue[finalIndex], queue: validQueue, currentPosition: initialPos, totalDuration: Duration.zero);

      _playlist = ConcatenatingAudioSource(useLazyPreparation: true, children: sources);
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: finalIndex, initialPosition: initialPos);
      _persistQueueState();

      if (sessionId != _currentLoadSession) return;
      if (autoPlay) await _safePlay();
    } catch (e) {
      if (sessionId != _currentLoadSession) return;
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> playNext(SongModel song) async {
    if (_playlist == null || state.queue.isEmpty) {
      await loadSong(song, [song]);
      return;
    }
    final src = _buildSource(song);
    if (src == null) return;
    
    final currentIndex = _audioPlayer.currentIndex ?? state.queue.length - 1;
    final insertIndex = currentIndex + 1;
    final newQueue = List<SongModel>.from(state.queue);
    newQueue.insert(insertIndex, song);
    state = state.copyWith(queue: newQueue);
    
    await _playlist!.insert(insertIndex, src);
    _persistQueueState();
  }

  Future<void> addToQueue(SongModel song) async {
    if (_playlist == null || state.queue.isEmpty) {
      await loadSong(song, [song]);
      return;
    }
    final src = _buildSource(song);
    if (src == null) return;
    
    final newQueue = List<SongModel>.from(state.queue);
    newQueue.add(song);
    state = state.copyWith(queue: newQueue);
    
    await _playlist!.add(src);
    _persistQueueState();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_playlist == null || oldIndex == newIndex) return;
    if (oldIndex < newIndex) newIndex -= 1;
    
    final newQueue = List<SongModel>.from(state.queue);
    final song = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, song);
    state = state.copyWith(queue: newQueue);
    
    await _playlist!.move(oldIndex, newIndex);
    _persistQueueState();
  }

  Future<void> removeFromQueue(int index) async {
    if (_playlist == null || index < 0 || index >= state.queue.length) return;
    final newQueue = List<SongModel>.from(state.queue);
    newQueue.removeAt(index);
    if (newQueue.isEmpty) {
      stop();
      state = state.copyWith(queue: [], currentSong: null);
      _playlist = null;
    } else {
      state = state.copyWith(queue: newQueue);
      await _playlist!.removeAt(index);
    }
    _persistQueueState();
  }

  Future<void> _safePlay() async {
    try { await _audioPlayer.play(); } catch (e) {}
  }

  bool _isSameQueue(List<SongModel> newQueue) {
    if (state.queue.length != newQueue.length) return false;
    for (int i = 0; i < newQueue.length; i++) {
      if (state.queue[i].id != newQueue[i].id) return false;
    }
    return true;
  }

  void togglePlay() {
    if (_audioPlayer.playing) _audioPlayer.pause();
    else if (state.currentSong != null && _audioPlayer.audioSource != null) _safePlay();
  }

  void stop() {
    _audioPlayer.stop();
    state = state.copyWith(isPlaying: false, currentPosition: Duration.zero);
  }

  void seek(Duration position) => _audioPlayer.seek(position);

  void toggleShuffle() {
    final next = !state.isShuffle;
    state = state.copyWith(isShuffle: next);
    _audioPlayer.setShuffleModeEnabled(next);
  }

  void toggleRepeat() {
    RepeatMode nextMode;
    switch (state.repeatMode) {
      case RepeatMode.off: nextMode = RepeatMode.all; break;
      case RepeatMode.all: nextMode = RepeatMode.one; break;
      case RepeatMode.one: nextMode = RepeatMode.off; break;
    }
    state = state.copyWith(repeatMode: nextMode);
    
    LoopMode loopMode;
    switch (nextMode) {
      case RepeatMode.off: loopMode = LoopMode.off; break;
      case RepeatMode.all: loopMode = LoopMode.all; break;
      case RepeatMode.one: loopMode = LoopMode.one; break;
    }
    _audioPlayer.setLoopMode(loopMode);
  }

  void skipNext() {
    if (state.queue.isEmpty || _audioPlayer.audioSource == null) return;
    if (_audioPlayer.hasNext) _audioPlayer.seekToNext();
    else _audioPlayer.seek(Duration.zero, index: 0);
  }

  void skipPrevious() {
    if (state.queue.isEmpty || _audioPlayer.audioSource == null) return;
    if (state.currentPosition.inSeconds > 3) { seek(Duration.zero); return; }
    if (_audioPlayer.hasPrevious) _audioPlayer.seekToPrevious();
    else _audioPlayer.seek(Duration.zero, index: state.queue.length - 1);
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    for (final sub in _subscriptions) sub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) => PlayerNotifier(ref));
