import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Playlist Model
// ---------------------------------------------------------------------------
class Playlist {
  final String id;
  final String name;
  final List<int> songIds;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<int>? songIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      songIds: List<int>.from(map['songIds'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory Playlist.fromJson(String source) => Playlist.fromMap(json.decode(source));
}

// ---------------------------------------------------------------------------
// PlaylistNotifier
//
// Manages local playlist CRUD with JSON persistence in SharedPreferences.
// ---------------------------------------------------------------------------
class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  static const _prefsKey = 's_music_playlists';

  PlaylistNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefsKey) ?? [];
      state = rawList.map((e) => Playlist.fromJson(e)).toList();
    } catch (_) {
      // SharedPreferences error fallback
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = state.map((e) => e.toJson()).toList();
      await prefs.setStringList(_prefsKey, rawList);
    } catch (_) {}
  }

  void createPlaylist(String name) {
    if (name.trim().isEmpty) return;
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songIds: [],
    );
    state = [...state, newPlaylist];
    _save();
  }

  void renamePlaylist(String id, String newName) {
    if (newName.trim().isEmpty) return;
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(name: newName.trim()) else p
    ];
    _save();
  }

  void deletePlaylist(String id) {
    state = state.where((p) => p.id != id).toList();
    _save();
  }

  void addSongToPlaylist(String playlistId, int songId) {
    state = [
      for (final p in state)
        if (p.id == playlistId)
          p.copyWith(
            songIds: p.songIds.contains(songId)
                ? p.songIds
                : [...p.songIds, songId],
          )
        else
          p
    ];
    _save();
  }

  void removeSongFromPlaylist(String playlistId, int songId) {
    state = [
      for (final p in state)
        if (p.id == playlistId)
          p.copyWith(songIds: p.songIds.where((id) => id != songId).toList())
        else
          p
    ];
    _save();
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  return PlaylistNotifier();
});
