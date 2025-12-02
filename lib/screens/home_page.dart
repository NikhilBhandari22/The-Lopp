import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/music_provider.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/song_card.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'full_screen_player_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<LibraryScreenState> _libraryKey =
      GlobalKey<LibraryScreenState>();
  bool _isPlayerModalOpen = false;

  @override
  void initState() {
    super.initState();
    // Set up callback to open full player when a song starts loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MusicProvider>();
      provider.onSongStartedLoading = _openFullScreenPlayerIfNotOpen;
    });
  }

  @override
  void dispose() {
    // Clean up the callback
    final provider = context.read<MusicProvider>();
    provider.onSongStartedLoading = null;
    super.dispose();
  }

  void _openFullScreenPlayerIfNotOpen() {
    if (!_isPlayerModalOpen) {
      _openFullScreenPlayer();
    }
  }

  void _navigateToTab(int tabIndex) {
    setState(() {
      if (tabIndex == 2) {
        // Navigate to Library -> Favorites tab
        _currentIndex = 2;
        Future.microtask(() {
          _libraryKey.currentState?.switchToTab(1);
        });
      } else if (tabIndex == 3) {
        // Navigate to Library -> Recent tab
        _currentIndex = 2;
        Future.microtask(() {
          _libraryKey.currentState?.switchToTab(2);
        });
      } else {
        _currentIndex = tabIndex;
      }
    });
  }

  void _openFullScreenPlayer() {
    if (_isPlayerModalOpen) return;

    _isPlayerModalOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FullScreenPlayerModal(),
    ).whenComplete(() {
      _isPlayerModalOpen = false;
    });
  }

  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/applogo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'The Loop',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developed by',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Nikhil K',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A beautiful music streaming app built with Flutter',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/applogo.jpeg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'The Loop',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showAboutDialog(context);
            },
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onNavigateToTab: _navigateToTab),
          const SearchScreen(),
          LibraryScreen(key: _libraryKey),
        ],
      ),
      bottomNavigationBar: Consumer<MusicProvider>(
        builder: (context, provider, _) {
          return Container(
            // Add margin at top when mini player is showing
            margin: EdgeInsets.only(top: provider.hasCurrentSong ? 0 : 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini Player above nav bar
                if (provider.hasCurrentSong)
                  MiniPlayerBar(onTap: _openFullScreenPlayer),
                // Navigation Bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, 'Home'),
                        _buildNavItem(1, Icons.search_rounded, 'Search'),
                        _buildNavItem(
                          2,
                          Icons.library_music_rounded,
                          'Library',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const _HomeTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          top: false, // AppBar handles top
          child: RefreshIndicator(
            onRefresh: provider.loadTrendingSongs,
            color: AppColors.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want to listen to?',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.favorite_rounded,
                            label: 'Liked Songs',
                            color: Colors.pink,
                            onTap: () {
                              // Navigate to Library tab (index 2) and select Favorites tab (index 1)
                              onNavigateToTab(2);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.history_rounded,
                            label: 'Recently Played',
                            color: Colors.orange,
                            onTap: () {
                              // Navigate to Library tab (index 2) and select Recent tab (index 2)
                              onNavigateToTab(3);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recently Played Section
                  if (provider.recentlyPlayed.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Recently Played'),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.recentlyPlayed.take(10).length,
                        itemBuilder: (context, index) {
                          final song = provider.recentlyPlayed[index];
                          final isCurrent = provider.currentSong?.id == song.id;
                          final isPlaying = isCurrent && provider.isPlaying;
                          final isLoading = isCurrent && provider.isLoadingSong;

                          return SongCardCompact(
                            song: song,
                            isPlaying: isPlaying,
                            isLoading: isLoading,
                            onTap: () {
                              provider.playSong(
                                song,
                                playlist: provider.recentlyPlayed,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hindi Songs Section
                  _buildSectionHeader(context, 'Hindi Songs'),
                  if (provider.isLoadingHindi)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  else if (provider.hindiSongs.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.hindiSongs.length,
                        itemBuilder: (context, index) {
                          final song = provider.hindiSongs[index];
                          final isCurrent = provider.currentSong?.id == song.id;
                          final isPlaying = isCurrent && provider.isPlaying;
                          final isLoading = isCurrent && provider.isLoadingSong;

                          return SongCardCompact(
                            song: song,
                            isPlaying: isPlaying,
                            isLoading: isLoading,
                            onTap: () {
                              provider.playSong(
                                song,
                                playlist: provider.hindiSongs,
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Hindi Rap Songs Section
                  _buildSectionHeader(context, 'Hindi Rap'),
                  if (provider.isLoadingHindiRap)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  else if (provider.hindiRapSongs.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.hindiRapSongs.length,
                        itemBuilder: (context, index) {
                          final song = provider.hindiRapSongs[index];
                          final isCurrent = provider.currentSong?.id == song.id;
                          final isPlaying = isCurrent && provider.isPlaying;
                          final isLoading = isCurrent && provider.isLoadingSong;

                          return SongCardCompact(
                            song: song,
                            isPlaying: isPlaying,
                            isLoading: isLoading,
                            onTap: () {
                              provider.playSong(
                                song,
                                playlist: provider.hindiRapSongs,
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Trending Section
                  _buildSectionHeader(context, 'Trending Now'),
                  if (provider.isLoadingTrending)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  else if (provider.trendingSongs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.music_off_rounded,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load trending songs',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: provider.loadTrendingSongs,
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.trendingSongs.length,
                      itemBuilder: (context, index) {
                        final song = provider.trendingSongs[index];
                        final isCurrent = provider.currentSong?.id == song.id;
                        final isPlaying = isCurrent && provider.isPlaying;
                        final isLoading = isCurrent && provider.isLoadingSong;

                        return SongCard(
                          song: song,
                          isPlaying: isPlaying,
                          isLoading: isLoading,
                          showAddButton: false,
                          onTap: () {
                            provider.playSong(
                              song,
                              playlist: provider.trendingSongs,
                            );
                          },
                          onMoreTap: () {
                            // Show options
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () {
              // See all
            },
            child: Text(
              'See all',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
