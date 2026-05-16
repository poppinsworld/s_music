import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

final audioQueryProvider = Provider<OnAudioQuery>((ref) {
  return OnAudioQuery();
});

class SongState {
  final List<SongModel> songs;
  final bool isLoading;
  final bool hasPermission;

  SongState({
    this.songs = const [],
    this.isLoading = true,
    this.hasPermission = false,
  });

  SongState copyWith({
    List<SongModel>? songs,
    bool? isLoading,
    bool? hasPermission,
  }) {
    return SongState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class SongNotifier extends StateNotifier<SongState> {
  final OnAudioQuery _audioQuery;

  SongNotifier(this._audioQuery) : super(SongState()) {
    _init();
  }

  Future<void> _init() async {
    await requestPermissions();
    if (state.hasPermission) {
      await fetchSongs();
    }
  }

  Future<void> requestPermissions() async {
    state = state.copyWith(isLoading: true);
    
    // Check permission status
    PermissionStatus status = await Permission.audio.status;
    if (!status.isGranted) {
       status = await Permission.audio.request();
    }
    
    // Fallback for older Android versions
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      state = state.copyWith(hasPermission: true);
    } else {
      state = state.copyWith(hasPermission: false, isLoading: false);
    }
  }

  Future<void> fetchSongs() async {
    state = state.copyWith(isLoading: true);
    try {
      final songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      state = state.copyWith(songs: songs, isLoading: false);
    } catch (e) {
      state = state.copyWith(songs: [], isLoading: false);
    }
  }
}

final songProvider = StateNotifierProvider<SongNotifier, SongState>((ref) {
  final query = ref.watch(audioQueryProvider);
  return SongNotifier(query);
});
