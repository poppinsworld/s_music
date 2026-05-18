import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueuePersistenceService {
  static const String _queueKey = 's_music_persisted_queue';
  static const String _indexKey = 's_music_persisted_index';
  static const String _positionKey = 's_music_persisted_position';

  Future<void> saveQueueState({
    required List<int> songIds,
    required int currentIndex,
    required int positionMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(songIds));
      await prefs.setInt(_indexKey, currentIndex);
      await prefs.setInt(_positionKey, positionMs);
    } catch (e) {
      // ignore silently if storage fails
    }
  }

  Future<Map<String, dynamic>?> loadQueueState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString(_queueKey);
      if (queueStr == null) return null;
      
      final List<dynamic> decoded = jsonDecode(queueStr);
      final songIds = decoded.map((e) => e as int).toList();
      final index = prefs.getInt(_indexKey) ?? 0;
      final position = prefs.getInt(_positionKey) ?? 0;
      
      return {
        'songIds': songIds,
        'index': index,
        'positionMs': position,
      };
    } catch (e) {
      return null;
    }
  }
}

final queuePersistenceProvider = Provider((ref) => QueuePersistenceService());
