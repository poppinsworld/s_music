import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../shared/playlist_row.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          children: [
            _buildLibraryItem(context, Icons.music_note, 'Songs', '1284'),
            _buildLibraryItem(context, Icons.album, 'Albums', '96'),
            _buildLibraryItem(context, Icons.person, 'Artists', '74'),
            _buildLibraryItem(context, Icons.playlist_play, 'Playlists', '42'),
            _buildLibraryItem(context, Icons.category, 'Genres', '18'),
            _buildLibraryItem(context, Icons.favorite, 'Liked Songs', '312', isLiked: true),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recently Added', style: Theme.of(context).textTheme.titleLarge),
                  Text('See all', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const PlaylistRow(title: 'Glow', subtitle: 'Osho Jain'),
            const PlaylistRow(title: 'Eclipse', subtitle: 'Luna Wave'),
            const PlaylistRow(title: 'Infinity', subtitle: 'Point Break'),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryItem(BuildContext context, IconData icon, String title, String count, {bool isLiked = false}) {
    return ListTile(
      leading: Icon(icon, color: isLiked ? AppColors.secondary : AppColors.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: () {},
    );
  }
}
