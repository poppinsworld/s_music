import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visualizer_state.dart';
import '../providers/visualizer_provider.dart';
import '../services/audio_reactivity_service.dart';
import '../../theme/dynamic_theme_provider.dart';

class VisualizerLayer extends ConsumerStatefulWidget {
  final bool isPlaying;

  const VisualizerLayer({super.key, required this.isPlaying});

  @override
  ConsumerState<VisualizerLayer> createState() => _VisualizerLayerState();
}

class _VisualizerLayerState extends ConsumerState<VisualizerLayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _timeMs = 0;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(days: 365));
    _controller.addListener(_onTick);
    if (widget.isPlaying) {
      _lastTick = DateTime.now();
      _controller.repeat();
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final delta = now.difference(_lastTick).inMilliseconds;
    _lastTick = now;
    if (widget.isPlaying) {
      _timeMs += delta;
    }
  }

  @override
  void didUpdateWidget(VisualizerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _lastTick = DateTime.now();
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualizerState = ref.watch(visualizerProvider);
    if (!visualizerState.isEnabled) return const SizedBox.shrink();

    final theme = ref.watch(dynamicThemeProvider);

    return RepaintBoundary(
      child: CustomPaint(
        painter: VisualizerPainter(
          animation: _controller,
          getTime: () => _timeMs,
          isPlaying: widget.isPlaying,
          mode: visualizerState.mode,
          intensity: visualizerState.intensity,
          glowColor: theme.glowColor,
          accentColor: theme.accentColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class VisualizerPainter extends CustomPainter {
  final Animation<double> animation;
  final double Function() getTime;
  final bool isPlaying;
  final VisualizerMode mode;
  final double intensity;
  final Color glowColor;
  final Color accentColor;

  VisualizerPainter({
    required this.animation,
    required this.getTime,
    required this.isPlaying,
    required this.mode,
    required this.intensity,
    required this.glowColor,
    required this.accentColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final timeMs = getTime();
    // Decay state smoothly when paused, or just pass reactivity
    final reactivity = AudioReactivityService.generate(
      Duration(milliseconds: timeMs.toInt()),
      isPlaying,
      intensity,
    );

    switch (mode) {
      case VisualizerMode.ambientBars:
        _paintAmbientBars(canvas, size, timeMs, reactivity);
        break;
      case VisualizerMode.neonPulse:
        _paintNeonPulse(canvas, size, timeMs, reactivity);
        break;
      case VisualizerMode.softWaveform:
        _paintSoftWaveform(canvas, size, timeMs, reactivity);
        break;
      case VisualizerMode.particleDrift:
        _paintParticleDrift(canvas, size, timeMs, reactivity);
        break;
      case VisualizerMode.cinematicGlow:
        _paintCinematicGlow(canvas, size, timeMs, reactivity);
        break;
    }
  }

  void _paintCinematicGlow(Canvas canvas, Size size, double timeMs, ReactivityData r) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Slow breathing + bass impact
    final pulse = math.sin(timeMs * 0.001) * 0.5 + 0.5;
    final radius1 = size.width * 0.8 + (r.bass * 150) + (pulse * 50);
    final radius2 = size.width * 0.6 + (r.beat * 100) - (pulse * 30);

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.15 + (r.bass * 0.15)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 100), radius: radius1));

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.1 + (r.beat * 0.1)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy + 100), radius: radius2));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  void _paintSoftWaveform(Canvas canvas, Size size, double timeMs, ReactivityData r) {
    final paint = Paint()
      ..color = glowColor.withValues(alpha: 0.3 + (r.vocal * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (r.bass * 4.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final path = Path();
    final yCenter = size.height * 0.75;
    
    for (double x = 0; x <= size.width; x += 10) {
      final normalizedX = x / size.width;
      // Combine multiple sine waves for an organic look
      final wave1 = math.sin(normalizedX * math.pi * 4 + timeMs * 0.002) * (20 + r.beat * 40);
      final wave2 = math.cos(normalizedX * math.pi * 7 - timeMs * 0.003) * (10 + r.vocal * 30);
      final wave3 = math.sin(normalizedX * math.pi * 2 + timeMs * 0.001) * (30 + r.bass * 60);
      
      final y = yCenter + wave1 + wave2 + wave3;
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw a sharper core line
    paint.strokeWidth = 1.5;
    paint.maskFilter = null;
    paint.color = Colors.white.withValues(alpha: 0.4 + (r.vocal * 0.4));
    canvas.drawPath(path, paint);
  }

  void _paintAmbientBars(Canvas canvas, Size size, double timeMs, ReactivityData r) {
    const int numBars = 12;
    final barWidth = size.width / (numBars * 2);
    final startX = (size.width - (numBars * 2 - 1) * barWidth) / 2;
    final bottomY = size.height;
    
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      final x = startX + i * 2 * barWidth;
      // Pseudo random height for each bar based on time and index
      final phase = i * 0.5;
      final noise = math.sin(timeMs * 0.005 + phase) * 0.5 + 0.5;
      final fastNoise = math.cos(timeMs * 0.01 + phase * 2) * 0.5 + 0.5;
      
      final height = 20 + (noise * 60 * r.bass) + (fastNoise * 40 * r.beat) + (r.vocal * 20);
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, bottomY - height, x + barWidth, bottomY),
        const Radius.circular(4),
      );
      
      // Glow
      paint.color = glowColor.withValues(alpha: 0.2 + (height / 200) * 0.3);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(rect, paint);
      
      // Core
      paint.color = Colors.white.withValues(alpha: 0.3 + (height / 200) * 0.5);
      paint.maskFilter = null;
      canvas.drawRRect(rect, paint);
    }
  }

  void _paintNeonPulse(Canvas canvas, Size size, double timeMs, ReactivityData r) {
    final cx = size.width / 2;
    final cy = size.height * 0.4; // Behind artwork approximately
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const numRings = 4;
    for (int i = 0; i < numRings; i++) {
      final pTime = timeMs * 0.001 + i * (math.pi / 2);
      final radiusRaw = (pTime % 4.0) / 4.0; // 0.0 to 1.0
      
      final radius = 50 + radiusRaw * size.width * 0.8 + (r.bass * 40);
      final alpha = (1.0 - radiusRaw) * (0.2 + r.beat * 0.4);
      
      if (alpha <= 0) continue;

      paint.color = i % 2 == 0 
          ? glowColor.withValues(alpha: alpha.clamp(0.0, 1.0))
          : accentColor.withValues(alpha: alpha.clamp(0.0, 1.0));
          
      // Thick glow
      paint.strokeWidth = 8.0 + r.beat * 10;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset(cx, cy), radius, paint);
      
      // Thin core
      paint.strokeWidth = 1.5;
      paint.maskFilter = null;
      paint.color = Colors.white.withValues(alpha: alpha * 1.5.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  void _paintParticleDrift(Canvas canvas, Size size, double timeMs, ReactivityData r) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    const numParticles = 40;
    for (int i = 0; i < numParticles; i++) {
      // Deterministic pseudo-randomness
      final seed = i * 12345.6789;
      final speed = 0.02 + (math.sin(seed) * 0.5 + 0.5) * 0.05 + (r.beat * 0.05);
      
      final pTime = timeMs * speed + seed;
      final y = size.height - (pTime % size.height);
      
      // Horizontal drift
      final xDrift = math.sin(timeMs * 0.001 + seed) * 40;
      final x = size.width * (math.cos(seed) * 0.5 + 0.5) + xDrift;
      
      final sizePulse = math.sin(timeMs * 0.005 + seed) * 0.5 + 0.5;
      final radius = 1.0 + sizePulse * 3.0 + (r.vocal * 3.0);
      
      final alphaRaw = math.sin(pTime * math.pi / size.height);
      final alpha = alphaRaw.clamp(0.0, 1.0) * (0.3 + r.bass * 0.5);
      
      if (alpha <= 0) continue;

      paint.color = i % 3 == 0 ? accentColor : glowColor;
      paint.color = paint.color.withValues(alpha: alpha);
      
      // Glow
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), radius * 3, paint);
      
      // Core
      paint.color = Colors.white.withValues(alpha: alpha);
      paint.maskFilter = null;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) {
    return oldDelegate.isPlaying != isPlaying || 
           oldDelegate.mode != mode ||
           oldDelegate.intensity != intensity ||
           oldDelegate.glowColor != glowColor ||
           oldDelegate.accentColor != accentColor;
           // Animation handles actual repaints
  }
}
