import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// FavoritesNotifier
//
// Stores a Set<int> of liked song IDs in SharedPreferences.
// Key design decisions:
//  • Uses a Set for O(1) lookup when checking isFavorite
//  • Persists as a comma-separated string — no heavy JSON parsing needed
//  • Loads once at init; writes are async fire-and-forget (UI never waits)
//  • Falls back gracefully if prefs are unavailable
// ---------------------------------------------------------------------------
class FavoritesNotifier extends StateNotifier<Set<int>> {
  static const _prefsKey = 's_music_favorites';

  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey) ?? '';
      if (raw.isEmpty) return;
      final ids = raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toSet();
      state = ids;
    } catch (_) {
      // Prefs unavailable — start with empty favorites
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, state.join(','));
    } catch (_) {}
  }

  /// Toggle favorite state. Returns true if the song is now liked.
  bool toggle(int songId) {
    final updated = Set<int>.from(state);
    if (updated.contains(songId)) {
      updated.remove(songId);
    } else {
      updated.add(songId);
    }
    state = updated;
    _save(); // fire-and-forget — UI responds instantly
    return state.contains(songId);
  }

  bool isFavorite(int songId) => state.contains(songId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  return FavoritesNotifier();
});

/// Convenience provider: is a specific song ID favorited?
/// Use this with select() at call sites for zero-cost watch granularity.
/// Example: ref.watch(isFavoriteProvider(song.id))
final isFavoriteProvider = Provider.family<bool, int>((ref, songId) {
  return ref.watch(favoritesProvider).contains(songId);
});
