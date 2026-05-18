enum VisualizerMode {
  ambientBars,
  neonPulse,
  softWaveform,
  particleDrift,
  cinematicGlow
}

class VisualizerState {
  final bool isEnabled;
  final VisualizerMode mode;
  final double intensity;

  VisualizerState({
    required this.isEnabled,
    required this.mode,
    required this.intensity,
  });

  VisualizerState copyWith({
    bool? isEnabled,
    VisualizerMode? mode,
    double? intensity,
  }) {
    return VisualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
    );
  }
}
