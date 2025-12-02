import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/music_provider.dart';
import '../widgets/song_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // If query is empty, clear immediately
    if (query.trim().isEmpty) {
      context.read<MusicProvider>().clearSearch();
      return;
    }

    // Debounce: wait 500ms after user stops typing before searching
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        context.read<MusicProvider>().searchMusic(query);
      }
    });
  }

  void _showAddToPlaylistSheet(BuildContext context, song) {
    final provider = context.read<MusicProvider>();
    final playlists = provider.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Playlist',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No playlists yet. Create one first!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...playlists.map(
                (playlist) => ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${playlist.songCount} songs',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    provider.addSongToPlaylist(playlist.id, song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to ${playlist.name}'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          top: false, // AppBar handles top
          child: Column(
            children: [
              // Search Bar
              Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: _focusNode.hasFocus
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearch,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for songs, artists...',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Results
            Expanded(
              child: _buildSearchContent(provider),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildSearchContent(MusicProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (provider.searchQuery.isEmpty) {
      return _buildSearchSuggestions();
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final song = provider.searchResults[index];
        final isCurrent = provider.currentSong?.id == song.id;
        final isPlaying = isCurrent && provider.isPlaying;
        final isLoading = isCurrent && provider.isLoadingSong;

        return SongCard(
          song: song,
          isPlaying: isPlaying,
          isLoading: isLoading,
          onTap: () {
            provider.playSong(song, playlist: provider.searchResults);
          },
          onAddTap: () => _showAddToPlaylistSheet(context, song),
          onMoreTap: () {
            // Show more options
          },
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Top Hits 2024',
      'Chill Vibes',
      'Workout Mix',
      'Bollywood Hits',
      'Arijit Singh',
      'EDM Party',
      'Acoustic Covers',
      'Lofi Hip Hop',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = suggestion;
                  _onSearch(suggestion);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.surfaceLighter,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Browse Categories',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Pop', 'icon': Icons.music_note_rounded, 'color': Colors.pink},
      {'name': 'Rock', 'icon': Icons.audiotrack_rounded, 'color': Colors.red},
      {'name': 'Hip Hop', 'icon': Icons.headphones_rounded, 'color': Colors.orange},
      {'name': 'Electronic', 'icon': Icons.equalizer_rounded, 'color': Colors.cyan},
      {'name': 'Jazz', 'icon': Icons.piano_rounded, 'color': Colors.amber},
      {'name': 'Classical', 'icon': Icons.library_music_rounded, 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = category['name'] as String;
            _onSearch(category['name'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (category['color'] as Color).withValues(alpha: 0.8),
                  (category['color'] as Color).withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    category['icon'] as IconData,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    category['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
