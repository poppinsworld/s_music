import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/favorites/favorites_provider.dart';

// ---------------------------------------------------------------------------
// FavoriteButton
//
// Reusable animated heart icon with:
//  • Scale + opacity AnimatedSwitcher transition on toggle
//  • Glow pulse using TweenAnimationBuilder on "just liked" state
//  • Accepts songId — reads/writes favoritesProvider directly
//  • size parameter for use in both SongTile (small) and PlayerScreen (large)
// ---------------------------------------------------------------------------
class FavoriteButton extends ConsumerStatefulWidget {
  final int songId;
  final double size;
  final Color? activeColor;

  const FavoriteButton({
    super.key,
    required this.songId,
    this.size = 24.0,
    this.activeColor,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    final wasLiked = ref.read(isFavoriteProvider(widget.songId));
    ref.read(favoritesProvider.notifier).toggle(widget.songId);
    if (!wasLiked) {
      // Just liked — fire the pulse animation
      _pulseCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(isFavoriteProvider(widget.songId));
    final activeColor = widget.activeColor ?? const Color(0xFFEC4899); // pink

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: isFav ? _pulseAnim.value : 1.0,
              child: child,
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: isFav
                ? Icon(
                    Icons.favorite_rounded,
                    key: const ValueKey('fav_on'),
                    size: widget.size,
                    color: activeColor,
                    shadows: [
                      Shadow(
                        color: activeColor.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  )
                : Icon(
                    Icons.favorite_border_rounded,
                    key: const ValueKey('fav_off'),
                    size: widget.size,
                    color: Colors.white54,
                  ),
          ),
        ),
      ),
    );
  }
}
