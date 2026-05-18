import 'dart:math';

class ReactivityData {
  final double bass;
  final double beat;
  final double vocal;

  const ReactivityData({
    required this.bass,
    required this.beat,
    required this.vocal,
  });
}

class AudioReactivityService {
  /// Generates organic, pseudo-random visualizer reactivity based purely on 
  /// the current playback time. This ensures 0% CPU/Audio engine overhead 
  /// while still feeling like it's reacting to the music perfectly.
  static ReactivityData generate(Duration position, bool isPlaying, double intensity) {
    if (!isPlaying) {
      return const ReactivityData(bass: 0.0, beat: 0.0, vocal: 0.0);
    }

    final ms = position.inMilliseconds.toDouble();
    
    // Simulate Bass (slow, organic thumping, large waves)
    // We combine two sine waves at slightly different low frequencies
    final bassRaw = (sin(ms * 0.0021) * 0.5 + 0.5) * (cos(ms * 0.0013) * 0.5 + 0.5);
    // Add sharp peaks for "kicks"
    final kick = pow(sin(ms * 0.0035), 8).toDouble();
    final bass = (bassRaw * 0.6 + kick * 0.4) * intensity;
    
    // Simulate Beat (snappy, regular interval but with some variation)
    final beatRaw = pow(sin(ms * 0.0042), 4).toDouble() * (sin(ms * 0.0007) * 0.3 + 0.7);
    final beat = beatRaw * intensity;
    
    // Simulate Vocals/Highs (fast, erratic but smooth, shimmering)
    final vocalRaw = (sin(ms * 0.0087) * 0.3 + 0.7) * (cos(ms * 0.012) * 0.4 + 0.6) * (sin(ms * 0.005) * 0.5 + 0.5);
    final vocal = vocalRaw * intensity;

    return ReactivityData(
      bass: bass.clamp(0.0, 1.0),
      beat: beat.clamp(0.0, 1.0),
      vocal: vocal.clamp(0.0, 1.0),
    );
  }
}
