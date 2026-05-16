import 'package:flutter/material.dart';
import '../../shared/section_header.dart';
import '../../shared/album_card.dart';
import '../../shared/playlist_row.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140), // Space for mini player
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good Evening', style: Theme.of(context).textTheme.headlineMedium),
                        Text('Let\'s enjoy some music', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                  ],
                ),
              ),
              // Hero Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryVariant, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 24,
                      top: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Discover\nYour Flow', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Music for every moment', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recently Played', actionText: 'See all'),
              const PlaylistRow(title: 'Midnight Dreams', subtitle: 'Arctic Coast'),
              const PlaylistRow(title: 'The Night Drive', subtitle: 'Wave Theory'),
              const PlaylistRow(title: 'Neon Skyline', subtitle: 'Lone Reverie'),
              
              const SizedBox(height: 16),
              const SectionHeader(title: 'Made for You', actionText: 'See all'),
              SizedBox(
                height: 200,
                child: ListView(
                  padding: const EdgeInsets.only(right: 16),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    AlbumCard(title: 'Chill Vibes', subtitle: 'Mix'),
                    AlbumCard(title: 'Night Ride', subtitle: 'Mix'),
                    AlbumCard(title: 'Focus Flow', subtitle: 'Mix'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
