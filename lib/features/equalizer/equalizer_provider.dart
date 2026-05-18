import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../player/player_provider.dart';

enum EqualizerPreset { balanced, bassBoost, vocal, cinematic, night }

const List<double> advancedFrequencies = [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];

class EqualizerState {
  final bool isEnabled;
  final EqualizerPreset activePreset; 
  final List<double> bandGains; 
  final AndroidEqualizerParameters? parameters;
  
  // Advanced features
  final bool isAdvancedMode;
  final bool isDynamicEnlargementEnabled;
  final String activeAdvancedPreset;
  final List<double> advancedBandGains;

  EqualizerState({
    this.isEnabled = false,
    this.activePreset = EqualizerPreset.balanced,
    this.bandGains = const [],
    this.parameters,
    this.isAdvancedMode = false,
    this.isDynamicEnlargementEnabled = false,
    this.activeAdvancedPreset = 'Flat',
    this.advancedBandGains = const [0,0,0,0,0,0,0,0,0,0],
  });

  EqualizerState copyWith({
    bool? isEnabled,
    EqualizerPreset? activePreset,
    List<double>? bandGains,
    AndroidEqualizerParameters? parameters,
    bool? isAdvancedMode,
    bool? isDynamicEnlargementEnabled,
    String? activeAdvancedPreset,
    List<double>? advancedBandGains,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      activePreset: activePreset ?? this.activePreset,
      bandGains: bandGains ?? this.bandGains,
      parameters: parameters ?? this.parameters,
      isAdvancedMode: isAdvancedMode ?? this.isAdvancedMode,
      isDynamicEnlargementEnabled: isDynamicEnlargementEnabled ?? this.isDynamicEnlargementEnabled,
      activeAdvancedPreset: activeAdvancedPreset ?? this.activeAdvancedPreset,
      advancedBandGains: advancedBandGains ?? this.advancedBandGains,
    );
  }
}

class EqualizerNotifier extends StateNotifier<EqualizerState> {
  final Ref ref;

  EqualizerNotifier(this.ref) : super(EqualizerState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final playerNotifier = ref.read(playerProvider.notifier);
      final eq = playerNotifier.androidEqualizer;
      
      final params = await eq.parameters;
      final gains = List<double>.filled(params.bands.length, 0.0);
      
      state = state.copyWith(
        parameters: params,
        bandGains: gains,
      );
    } catch (e) {
      debugPrint('[EqualizerNotifier] Initialization error: $e');
    }
  }

  void toggleEnabled() async {
    final playerNotifier = ref.read(playerProvider.notifier);
    final eq = playerNotifier.androidEqualizer;
    final next = !state.isEnabled;
    
    try {
      await eq.setEnabled(next);
      state = state.copyWith(isEnabled: next);
    } catch (e) {
      debugPrint('[EqualizerNotifier] Toggle error: $e');
    }
  }

  void toggleAdvancedMode() {
    final next = !state.isAdvancedMode;
    state = state.copyWith(isAdvancedMode: next);
    if (next) {
      _applyAdvancedGains(state.advancedBandGains);
    } else {
      _applyNormalGains(state.bandGains);
    }
  }

  void toggleDynamicEnlargement() async {
    final next = !state.isDynamicEnlargementEnabled;
    final playerNotifier = ref.read(playerProvider.notifier);
    final le = playerNotifier.androidLoudnessEnhancer;
    
    try {
      await le.setEnabled(next);
      if (next) {
        await le.setTargetGain(0.5); // Lightweight spatial emphasis
      } else {
        await le.setTargetGain(0.0);
      }
      state = state.copyWith(isDynamicEnlargementEnabled: next);
    } catch (e) {
      debugPrint('[EqualizerNotifier] Dynamic Enlargement error: $e');
    }
  }

  // --- Normal Mode Methods ---
  
  void setPreset(EqualizerPreset preset) {
    if (state.parameters == null) return;
    
    final bands = state.parameters!.bands;
    final numBands = bands.length;
    List<double> newGains = List.filled(numBands, 0.0);
    
    final max = state.parameters!.maxDecibels;
    final min = state.parameters!.minDecibels;
    
    for (int i = 0; i < numBands; i++) {
      double normalizedPos = numBands > 1 ? i / (numBands - 1) : 0.5;
      
      switch (preset) {
        case EqualizerPreset.balanced:
          newGains[i] = 0.0;
          break;
        case EqualizerPreset.bassBoost:
          if (normalizedPos < 0.3) {
            newGains[i] = max * 0.6;
          } else {
            newGains[i] = 0.0;
          }
          break;
        case EqualizerPreset.vocal:
          if (normalizedPos >= 0.3 && normalizedPos <= 0.7) {
            newGains[i] = max * 0.5;
          } else {
            newGains[i] = min * 0.2;
          }
          break;
        case EqualizerPreset.cinematic:
          if (normalizedPos < 0.3 || normalizedPos > 0.7) {
            newGains[i] = max * 0.5;
          } else {
            newGains[i] = min * 0.1;
          }
          break;
        case EqualizerPreset.night:
          if (normalizedPos < 0.3) {
            newGains[i] = min * 0.5;
          } else if (normalizedPos > 0.7) {
            newGains[i] = min * 0.3;
          } else {
            newGains[i] = 0.0;
          }
          break;
      }
    }
    
    _applyNormalGains(newGains);
    state = state.copyWith(activePreset: preset, bandGains: newGains);
  }

  void updateBand(int index, double gain) {
    if (state.parameters == null) return;
    final newGains = List<double>.from(state.bandGains);
    newGains[index] = gain;
    _applyNormalGains(newGains);
    state = state.copyWith(bandGains: newGains, activePreset: EqualizerPreset.balanced);
  }

  void _applyNormalGains(List<double> gains) {
    final params = state.parameters;
    if (params == null) return;
    
    for (int i = 0; i < gains.length; i++) {
      try {
        params.bands[i].setGain(gains[i]);
      } catch (e) {
        debugPrint('[EqualizerNotifier] Error setting band $i: $e');
      }
    }
  }

  // --- Advanced Mode Methods ---

  void setAdvancedPreset(String presetName) {
    if (state.parameters == null) return;
    
    final max = state.parameters!.maxDecibels;
    
    // 9 Precise recreateable reference presets
    final Map<String, List<double>> presets = {
      'Flat':       [ 0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0],
      'Rock':       [ 0.6,  0.4,  0.2,  0.0, -0.2, -0.2,  0.0,  0.2,  0.4,  0.6],
      'Pop':        [-0.2, -0.2,  0.0,  0.4,  0.6,  0.6,  0.4,  0.0, -0.2, -0.2],
      'Jazz':       [ 0.4,  0.2,  0.0,  0.2,  0.4,  0.4,  0.2,  0.0,  0.2,  0.4],
      'Classical':  [ 0.6,  0.4,  0.2,  0.0,  0.0,  0.0,  0.2,  0.4,  0.6,  0.6],
      'Dance':      [ 0.8,  0.6,  0.2,  0.0, -0.2, -0.4,  0.0,  0.2,  0.4,  0.4],
      'R&B':        [ 0.6,  0.4,  0.2, -0.2, -0.4, -0.2,  0.2,  0.4,  0.6,  0.8],
      'Hip-Hop':    [ 0.8,  0.6,  0.2,  0.0, -0.2, -0.2,  0.0,  0.2,  0.4,  0.6],
      'Acoustic':   [ 0.2,  0.2,  0.4,  0.2,  0.0,  0.0,  0.2,  0.4,  0.2,  0.0],
    };

    final normalized = presets[presetName] ?? presets['Flat']!;
    final gains = normalized.map((v) => v * max).toList();
    
    _applyAdvancedGains(gains);
    state = state.copyWith(activeAdvancedPreset: presetName, advancedBandGains: gains);
  }

  void updateAdvancedBand(int index, double gain) {
    if (state.parameters == null) return;
    
    final newGains = List<double>.from(state.advancedBandGains);
    newGains[index] = gain;
    
    _applyAdvancedGains(newGains);
    state = state.copyWith(advancedBandGains: newGains, activeAdvancedPreset: 'Custom');
  }

  void _applyAdvancedGains(List<double> uiGains) {
    final params = state.parameters;
    if (params == null) return;
    
    for (int i = 0; i < params.bands.length; i++) {
      final hwFreq = params.bands[i].centerFrequency / 1000.0; // centerFrequency is in mHz for just_audio 
      final gain = _interpolateGain(hwFreq, uiGains);
      try {
        params.bands[i].setGain(gain);
      } catch (e) {
        debugPrint('[EqualizerNotifier] Error setting advanced band $i: $e');
      }
    }
  }

  double _interpolateGain(double hwFreq, List<double> uiGains) {
    if (hwFreq <= advancedFrequencies.first) return uiGains.first;
    if (hwFreq >= advancedFrequencies.last) return uiGains.last;

    for (int i = 0; i < advancedFrequencies.length - 1; i++) {
      final f1 = advancedFrequencies[i];
      final f2 = advancedFrequencies[i + 1];
      if (hwFreq >= f1 && hwFreq <= f2) {
        final logF1 = log(f1);
        final logF2 = log(f2);
        final logHw = log(hwFreq);
        final t = (logHw - logF1) / (logF2 - logF1);
        return uiGains[i] + t * (uiGains[i + 1] - uiGains[i]);
      }
    }
    return 0.0;
  }
}

final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerState>((ref) {
  return EqualizerNotifier(ref);
});
