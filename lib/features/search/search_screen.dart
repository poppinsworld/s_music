import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../shared/section_header.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: Icon(Icons.mic, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Browse All', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildCategoryCard('Pop Hits', [AppColors.primary, AppColors.secondary]),
                _buildCategoryCard('Neon Vibes', [Colors.blue, AppColors.primary]),
                _buildCategoryCard('Mood', [Colors.orange, Colors.red]),
                _buildCategoryCard('Podcasts', [Colors.green, Colors.teal]),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Searches', actionText: 'See all'),
            _buildRecentSearchItem('Arctic Coast'),
            _buildRecentSearchItem('Midnight Dreams'),
            _buildRecentSearchItem('The Weekenders'),
            _buildRecentSearchItem('Luna Wave'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.topLeft,
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return ListTile(
      leading: const Icon(Icons.history, color: AppColors.textSecondary),
      title: Text(query, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
      contentPadding: EdgeInsets.zero,
      onTap: () {},
    );
  }
}
