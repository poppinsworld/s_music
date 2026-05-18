import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'app_colors.dart';
import '../player/player_provider.dart';

// ---------------------------------------------------------------------------
// DynamicThemeData — AMOLED-safe colors derived from album artwork
// ---------------------------------------------------------------------------
class DynamicThemeData {
  /// Primary accent used for glow, active controls, progress bar
  final Color glowColor;

  /// Secondary accent (slightly warmer/cooler complement)
  final Color accentColor;

  /// Very dark tint of the accent — used for background gradient start
  final Color backgroundStart;

  /// Always true-black for AMOLED background gradient end
  final Color backgroundEnd;

  /// Song ID this theme was extracted for (used for cache keying)
  final int? songId;

  const DynamicThemeData({
    required this.glowColor,
    required this.accentColor,
    required this.backgroundStart,
    required this.backgroundEnd,
    this.songId,
  });

  /// Default fallback when no artwork is available
  static const fallback = DynamicThemeData(
    glowColor: AppColors.primary,
    accentColor: AppColors.secondary,
    backgroundStart: Color(0xFF1A0B2E),
    backgroundEnd: Colors.black,
    songId: null,
  );
}

// ---------------------------------------------------------------------------
// DynamicThemeNotifier
//
// Key design decisions:
//  • Uses ref.listen on currentSong.id only — never fires on position ticks
//  • Queries a small 100px thumbnail for fast, low-memory palette extraction
//  • Caches results by song ID — never re-processes the same song twice
//  • Derives AMOLED-safe colors by clamping HSL lightness & saturation
//  • Falls back gracefully if artwork is null or palette extraction fails
// ---------------------------------------------------------------------------
class DynamicThemeNotifier extends StateNotifier<DynamicThemeData> {
  final Ref _ref;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Cache: songId → computed theme. Prevents reprocessing on re-visits.
  final Map<int, DynamicThemeData> _cache = {};

  DynamicThemeNotifier(this._ref) : super(DynamicThemeData.fallback) {
    // Only trigger when the song ID changes — never on position/isPlaying ticks
    _ref.listen<int?>(
      playerProvider.select((s) => s.currentSong?.id),
      (previous, next) {
        if (next == null) {
          state = DynamicThemeData.fallback;
        } else if (next != previous) {
          _extractTheme(next);
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _extractTheme(int songId) async {
    // Serve from cache immediately — zero reprocessing
    if (_cache.containsKey(songId)) {
      state = _cache[songId]!;
      return;
    }

    try {
      // Query a small thumbnail (100px) for fast, low-memory palette extraction
      final bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: 100,
        quality: 50,
      );

      if (bytes == null || bytes.isEmpty) {
        state = DynamicThemeData.fallback;
        return;
      }

      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        size: const Size(100, 100),
        maximumColorCount: 12,
      );

      // Pick best source color: vibrant > lightVibrant > dominant > fallback
      final sourceColor =
          palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.dominantColor?.color ??
          AppColors.primary;

      final hsl = HSLColor.fromColor(sourceColor);

      // ── Glow color ──────────────────────────────────────────────────────
      // Moderate saturation + mid lightness — visible on AMOLED without
      // washing out the image or reducing contrast with white text.
      final glowColor = hsl
          .withSaturation((hsl.saturation * 0.85).clamp(0.45, 0.90))
          .withLightness(hsl.lightness.clamp(0.38, 0.62))
          .toColor();

      // ── Accent color ─────────────────────────────────────────────────────
      // Slightly more vibrant / brighter version for buttons, highlights.
      final accentColor = hsl
          .withSaturation((hsl.saturation * 1.0).clamp(0.55, 1.0))
          .withLightness((hsl.lightness * 1.15).clamp(0.45, 0.70))
          .toColor();

      // ── Background gradient start ────────────────────────────────────────
      // Extremely dark tint — lightness capped at 0.07 (near true-black).
      // Preserves AMOLED depth while adding subtle cinematic hue.
      final backgroundStart = hsl
          .withSaturation(0.75)
          .withLightness(0.07)
          .toColor();

      final theme = DynamicThemeData(
        glowColor: glowColor,
        accentColor: accentColor,
        backgroundStart: backgroundStart,
        backgroundEnd: Colors.black,
        songId: songId,
      );

      _cache[songId] = theme;
      state = theme;
    } catch (_) {
      // Any error (missing artwork, decode failure) → safe fallback
      state = DynamicThemeData.fallback;
    }
  }
}

final dynamicThemeProvider =
    StateNotifierProvider<DynamicThemeNotifier, DynamicThemeData>((ref) {
  return DynamicThemeNotifier(ref);
});
