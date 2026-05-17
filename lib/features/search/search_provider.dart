import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../library/song_provider.dart';

/// Provider for holding the current search query string
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Reactive provider that filters local songs in memory based on the search query
final searchResultsProvider = Provider<List<SongModel>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final songState = ref.watch(songProvider);
  
  if (query.isEmpty) {
    return [];
  }
  
  return songState.songs.where((song) {
    final title = song.title.toLowerCase();
    final artist = (song.artist ?? 'Unknown Artist').toLowerCase();
    return title.contains(query) || artist.contains(query);
  }).toList();
});

/// Provider for managing a list of recent search queries (local UX state)
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([
    'Arctic Coast',
    'Midnight Dreams',
    'The Weekenders',
    'Luna Wave',
  ]);

  void addSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((item) => item.toLowerCase() != trimmed.toLowerCase())
    ].take(6).toList();
  }

  void removeSearch(String query) {
    state = state.where((item) => item != query).toList();
  }

  void clearAll() {
    state = [];
  }
}
