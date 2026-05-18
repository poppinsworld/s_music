import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../shared/song_tile.dart';
import '../../shared/section_header.dart';
import '../theme/app_colors.dart';
import '../library/song_provider.dart';
import 'search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _searchFocusNode.unfocus();
  }

  void _triggerRecentSearch(String query) {
    _searchController.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final songState = ref.watch(songProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    ref.read(recentSearchesProvider.notifier).addSearch(val);
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: _clearSearch,
                        )
                      : const Icon(Icons.mic, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable Search Body
          Expanded(
            child: _buildSearchBody(
              songState,
              searchQuery,
              searchResults,
              recentSearches,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBody(
    SongState songState,
    String searchQuery,
    List<SongModel> searchResults,
    List<String> recentSearches,
  ) {
    if (!songState.hasPermission) {
      return _buildPermissionState();
    }

    if (searchQuery.trim().isEmpty) {
      return _buildInitialSearchState(recentSearches);
    }

    if (searchResults.isEmpty) {
      return _buildNoResultsState(searchQuery);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140), // Space for mini player
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final song = searchResults[index];
        return SongTile(
          song: song,
          queue: searchResults,
        );
      },
    );
  }

  Widget _buildInitialSearchState(List<String> recentSearches) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Browse All', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
          if (recentSearches.isNotEmpty) ...[
            SectionHeader(
              title: 'Recent Searches',
              actionText: 'Clear all',
              onAction: () => ref.read(recentSearchesProvider.notifier).clearAll(),
            ),
            ...recentSearches.map((query) => _buildRecentSearchItem(query)),
          ],
        ],
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
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return ListTile(
      leading: const Icon(Icons.history, color: AppColors.textSecondary),
      title: Text(query, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
        onPressed: () => ref.read(recentSearchesProvider.notifier).removeSearch(query),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () => _triggerRecentSearch(query),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.05),
                border: Border.all(color: AppColors.secondary.withOpacity(0.15), width: 1.5),
              ),
              child: const Icon(Icons.search_off_rounded, size: 64, color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any songs matching "$query". Double-check spelling or try searching with artist names.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.05),
                border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
              ),
              child: const Icon(Icons.folder_off_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Storage Permission Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'S_Music requires storage access permission to index and search local audio files.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              onPressed: () => ref.read(songProvider.notifier).requestPermissions(),
              child: const Text('Grant Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
