import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lyrics_provider.dart';
import '../player/player_provider.dart';

class LyricsWidget extends ConsumerStatefulWidget {
  final Color glowColor;
  final Color accentColor;

  const LyricsWidget({
    super.key,
    required this.glowColor,
    required this.accentColor,
  });

  @override
  ConsumerState<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends ConsumerState<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;
  final List<GlobalKey> _keys = [];
  bool _isUserScrolling = false;
  DateTime _lastScrollTime = DateTime.now();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLine(int index) {
    if (_isUserScrolling) return; // Don't interrupt user reading
    if (index < 0 || index >= _keys.length) return;
    
    final key = _keys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // Scroll to center
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final position = ref.watch(playerProvider.select((s) => s.currentPosition));

    // Determine current line
    int newIndex = -1;
    if (lyricsState.syncedLyrics != null) {
      for (int i = 0; i < lyricsState.syncedLyrics!.length; i++) {
        if (position >= lyricsState.syncedLyrics![i].time) {
          newIndex = i;
        } else {
          break;
        }
      }
    }

    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only auto-scroll if it's been more than 3 seconds since user scrolled
        if (DateTime.now().difference(_lastScrollTime).inSeconds > 3) {
          _isUserScrolling = false;
        }
        _scrollToCurrentLine(_currentIndex);
      });
    }

    // Adjust keys list length
    if (lyricsState.syncedLyrics != null && _keys.length != lyricsState.syncedLyrics!.length) {
      _keys.clear();
      _keys.addAll(List.generate(lyricsState.syncedLyrics!.length, (_) => GlobalKey()));
    }

    return GestureDetector(
      onPanDown: (_) {
        _isUserScrolling = true;
        _lastScrollTime = DateTime.now();
      },
      onPanUpdate: (_) {
        _isUserScrolling = true;
        _lastScrollTime = DateTime.now();
      },
      child: _buildContent(lyricsState),
    );
  }

  Widget _buildContent(LyricsState state) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.glowColor),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lyrics_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (state.syncedLyrics != null) {
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            _isUserScrolling = true;
            _lastScrollTime = DateTime.now();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.25,
            horizontal: 24.0,
          ),
          itemCount: state.syncedLyrics!.length,
          itemBuilder: (context, index) {
            final line = state.syncedLyrics![index];
            final isActive = index == _currentIndex;

            return Padding(
              key: _keys[index],
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontFamily: 'Inter', // Try to use a clean modern font
                  fontSize: isActive ? 26.0 : 20.0,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 0.5,
                  height: 1.3,
                ),
                child: Text(line.text),
              ),
            );
          },
        ),
      );
    }

    if (state.plainLyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          state.plainLyrics!,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox();
  }
}