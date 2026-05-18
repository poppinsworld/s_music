import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_provider.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class LyricsState {
  final bool isLoading;
  final String? plainLyrics;
  final List<LyricLine>? syncedLyrics;
  final String? error;

  LyricsState({
    this.isLoading = false,
    this.plainLyrics,
    this.syncedLyrics,
    this.error,
  });

  LyricsState copyWith({
    bool? isLoading,
    String? plainLyrics,
    List<LyricLine>? syncedLyrics,
    String? error,
    bool clearError = false,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LyricsNotifier extends StateNotifier<LyricsState> {
  LyricsNotifier() : super(LyricsState());

  SongModel? _currentSong;

  void updateSong(SongModel? song) {
    if (song?.id == _currentSong?.id) return;
    _currentSong = song;
    
    if (song == null) {
      state = LyricsState();
      return;
    }

    _fetchLyrics(song);
  }

  Future<void> _fetchLyrics(SongModel song) async {
    state = LyricsState(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'lyrics_${song.id}';
      
      // Try cache first
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final data = jsonDecode(cached);
        _parseAndSetState(data);
        return;
      }

      // Fetch from API
      // Using lrclib.net which is lightweight and doesn't require auth
      final uri = Uri.parse(
        'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist ?? '')}&track_name=${Uri.encodeComponent(song.title)}'
      );
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        prefs.setString(cacheKey, response.body); // Cache it
        _parseAndSetState(data);
      } else {
        state = state.copyWith(isLoading: false, error: 'Lyrics not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load lyrics');
    }
  }

  void _parseAndSetState(Map<String, dynamic> data) {
    final synced = data['syncedLyrics'] as String?;
    final plain = data['plainLyrics'] as String?;

    List<LyricLine>? parsedSynced;
    
    if (synced != null && synced.trim().isNotEmpty) {
      parsedSynced = _parseSyncedLyrics(synced);
    }

    state = LyricsState(
      isLoading: false,
      plainLyrics: plain,
      syncedLyrics: (parsedSynced != null && parsedSynced.isNotEmpty) ? parsedSynced : null,
      error: (parsedSynced == null && (plain == null || plain.isEmpty)) ? 'No lyrics available' : null,
    );
  }

  List<LyricLine> _parseSyncedLyrics(String lrc) {
    final lines = lrc.split('\n');
    final result = <LyricLine>[];
    final regex = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisText = match.group(3)!;
        final milliseconds = millisText.length == 2 
            ? int.parse(millisText) * 10 
            : int.parse(millisText);
            
        final text = match.group(4)!.trim();
        
        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );
        
        result.add(LyricLine(time: time, text: text));
      }
    }
    
    return result;
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  final notifier = LyricsNotifier();
  
  ref.listen<SongModel?>(
    playerProvider.select((s) => s.currentSong),
    (previous, next) {
      notifier.updateSong(next);
    },
    fireImmediately: true,
  );
  
  return notifier;
});
