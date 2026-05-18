import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'equalizer_provider.dart';
import '../theme/dynamic_theme_provider.dart';

void showEqualizerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => const EqualizerSheet(),
  );
}

class EqualizerSheet extends ConsumerWidget {
  const EqualizerSheet({super.key});

  String _formatFreq(double freqHz) {
    if (freqHz >= 1000) {
      return '${(freqHz / 1000).toStringAsFixed(1)}k';
    } else {
      return '${freqHz.round()}';
    }
  }

  String _formatPresetName(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.balanced: return 'BALANCED';
      case EqualizerPreset.bassBoost: return 'BASS BOOST';
      case EqualizerPreset.vocal: return 'VOCAL';
      case EqualizerPreset.cinematic: return 'CINEMATIC';
      case EqualizerPreset.night: return 'NIGHT';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);
    final dynTheme = ref.watch(dynamicThemeProvider);
    
    final isSupported = eqState.parameters != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eqState.isAdvancedMode ? 'Advanced EQ' : 'Audio Enhancer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (eqState.isAdvancedMode)
                      Text(
                        'Experience the Full Range of 10-Band EQ',
                        style: TextStyle(color: dynTheme.glowColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                Switch(
                  value: eqState.isEnabled,
                  onChanged: isSupported ? (_) => eqNotifier.toggleEnabled() : null,
                  activeColor: dynTheme.glowColor,
                  activeTrackColor: dynTheme.glowColor.withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.white12,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (!isSupported)
            const Expanded(
              child: Center(
                child: Text(
                  'Audio enhancement is not supported on this device.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else ...[
            // Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: eqState.isAdvancedMode ? () => eqNotifier.toggleAdvancedMode() : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !eqState.isAdvancedMode ? dynTheme.glowColor.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: !eqState.isAdvancedMode ? dynTheme.glowColor : Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text('NORMAL', style: TextStyle(
                            color: !eqState.isAdvancedMode ? dynTheme.glowColor : Colors.white54,
                            fontWeight: FontWeight.bold, fontSize: 12,
                          )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: !eqState.isAdvancedMode ? () => eqNotifier.toggleAdvancedMode() : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: eqState.isAdvancedMode ? dynTheme.glowColor.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: eqState.isAdvancedMode ? dynTheme.glowColor : Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text('ADVANCED', style: TextStyle(
                            color: eqState.isAdvancedMode ? dynTheme.glowColor : Colors.white54,
                            fontWeight: FontWeight.bold, fontSize: 12,
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Dynamic Enlargement Toggle (Advanced Mode Only)
            if (eqState.isAdvancedMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.spatial_audio_rounded, color: eqState.isDynamicEnlargementEnabled ? dynTheme.glowColor : Colors.white54),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dynamic Enlargement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Immersive spatial expansion for cinematic listening', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: eqState.isDynamicEnlargementEnabled,
                        onChanged: eqState.isEnabled ? (_) => eqNotifier.toggleDynamicEnlargement() : null,
                        activeColor: dynTheme.glowColor,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Presets List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: eqState.isAdvancedMode 
                  ? ['Flat', 'Rock', 'Pop', 'Jazz', 'Classical', 'Dance', 'R&B', 'Hip-Hop', 'Acoustic'].map((preset) {
                      final isSelected = eqState.activeAdvancedPreset == preset;
                      return _buildPresetChip(preset, isSelected, dynTheme.glowColor, () => eqNotifier.setAdvancedPreset(preset));
                    }).toList()
                  : EqualizerPreset.values.map((preset) {
                      final isSelected = eqState.activePreset == preset;
                      return _buildPresetChip(_formatPresetName(preset), isSelected, dynTheme.glowColor, () => eqNotifier.setPreset(preset));
                    }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sliders Area
            Expanded(
              child: Opacity(
                opacity: eqState.isEnabled ? 1.0 : 0.4,
                child: AbsorbPointer(
                  absorbing: !eqState.isEnabled,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: eqState.isAdvancedMode
                        ? List.generate(advancedFrequencies.length, (index) {
                            final freq = advancedFrequencies[index];
                            final max = eqState.parameters!.maxDecibels;
                            final min = eqState.parameters!.minDecibels;
                            final val = eqState.advancedBandGains[index];
                            return _buildSlider(context, dynTheme.glowColor, val, min, max, _formatFreq(freq), (newVal) => eqNotifier.updateAdvancedBand(index, newVal));
                          })
                        : List.generate(eqState.parameters!.bands.length, (index) {
                            final band = eqState.parameters!.bands[index];
                            final max = eqState.parameters!.maxDecibels;
                            final min = eqState.parameters!.minDecibels;
                            final val = eqState.bandGains[index];
                            return _buildSlider(context, dynTheme.glowColor, val, min, max, _formatFreq(band.centerFrequency / 1000.0), (newVal) => eqNotifier.updateBand(index, newVal));
                          }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip(String name, bool isSelected, Color glowColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? glowColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? glowColor : Colors.transparent,
            ),
          ),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
              color: isSelected ? glowColor : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, Color glowColor, double val, double min, double max, String label, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: glowColor,
                inactiveTrackColor: Colors.white12,
                thumbColor: glowColor,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                min: min,
                max: max,
                value: val,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
