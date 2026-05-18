import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visualizer_state.dart';

final visualizerProvider = StateNotifierProvider<VisualizerNotifier, VisualizerState>((ref) {
  return VisualizerNotifier();
});

class VisualizerNotifier extends StateNotifier<VisualizerState> {
  VisualizerNotifier() : super(VisualizerState(isEnabled: true, mode: VisualizerMode.cinematicGlow, intensity: 0.5)) {
    _loadState();
  }

  static const _enabledKey = 'visualizer_enabled';
  static const _modeKey = 'visualizer_mode';
  static const _intensityKey = 'visualizer_intensity';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_enabledKey) ?? true;
    final modeIndex = prefs.getInt(_modeKey) ?? VisualizerMode.cinematicGlow.index;
    final intensity = prefs.getDouble(_intensityKey) ?? 0.5;

    final mode = VisualizerMode.values.length > modeIndex ? VisualizerMode.values[modeIndex] : VisualizerMode.cinematicGlow;
    state = VisualizerState(isEnabled: isEnabled, mode: mode, intensity: intensity);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setMode(VisualizerMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }

  Future<void> setIntensity(double intensity) async {
    state = state.copyWith(intensity: intensity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_intensityKey, intensity);
  }
}
