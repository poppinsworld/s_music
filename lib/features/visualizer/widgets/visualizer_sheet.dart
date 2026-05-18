import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visualizer_state.dart';
import '../providers/visualizer_provider.dart';
import '../../theme/dynamic_theme_provider.dart';

void showVisualizerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const VisualizerSheet(),
  );
}

class VisualizerSheet extends ConsumerWidget {
  const VisualizerSheet({super.key});

  String _formatModeName(VisualizerMode mode) {
    switch (mode) {
      case VisualizerMode.ambientBars:
        return 'Ambient Bars';
      case VisualizerMode.neonPulse:
        return 'Neon Pulse';
      case VisualizerMode.softWaveform:
        return 'Soft Waveform';
      case VisualizerMode.particleDrift:
        return 'Particle Drift';
      case VisualizerMode.cinematicGlow:
        return 'Cinematic Glow';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visualizerProvider);
    final notifier = ref.read(visualizerProvider.notifier);
    final theme = ref.watch(dynamicThemeProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visualizer Ambience',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: state.isEnabled,
                  onChanged: (v) => notifier.setEnabled(v),
                  activeColor: theme.glowColor,
                  activeTrackColor: theme.glowColor.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white12,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Intensity Slider
          Opacity(
            opacity: state.isEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !state.isEnabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reactivity Intensity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.glowColor,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: theme.glowColor,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: state.intensity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (v) => notifier.setIntensity(v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Mode Selection
          Opacity(
            opacity: state.isEnabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !state.isEnabled,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visualizer Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: VisualizerMode.values.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final mode = VisualizerMode.values[index];
                          final isSelected = state.mode == mode;
                          
                          return GestureDetector(
                            onTap: () => notifier.setMode(mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 110,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? theme.glowColor.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? theme.glowColor 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForMode(mode),
                                    color: isSelected ? theme.glowColor : Colors.white54,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _formatModeName(mode),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isSelected ? Colors.white : Colors.white54,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMode(VisualizerMode mode) {
    switch (mode) {
      case VisualizerMode.ambientBars:
        return Icons.bar_chart_rounded;
      case VisualizerMode.neonPulse:
        return Icons.wifi_tethering_rounded;
      case VisualizerMode.softWaveform:
        return Icons.waves_rounded;
      case VisualizerMode.particleDrift:
        return Icons.blur_on_rounded;
      case VisualizerMode.cinematicGlow:
        return Icons.lens_blur_rounded;
    }
  }
}
