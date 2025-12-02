import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_colors.dart';
import '../providers/music_provider.dart';

class FullScreenPlayerModal extends StatefulWidget {
  const FullScreenPlayerModal({super.key});

  @override
  State<FullScreenPlayerModal> createState() => _FullScreenPlayerModalState();
}

class _FullScreenPlayerModalState extends State<FullScreenPlayerModal> {
  Color _dominantColor = Colors.black;
  Color _vibrantColor = Colors.black;
  String? _currentThumbnailUrl;
  bool _isLoadingPalette = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePaletteIfNeeded();
  }

  void _updatePaletteIfNeeded() {
    final provider = context.read<MusicProvider>();
    final song = provider.currentSong;
    if (song != null && song.thumbnailUrl != _currentThumbnailUrl) {
      _currentThumbnailUrl = song.thumbnailUrl;
      _extractColorsFromImage(song.thumbnailUrl);
    }
  }

  Future<void> _extractColorsFromImage(String imageUrl) async {
    if (_isLoadingPalette) return;

    setState(() {
      _isLoadingPalette = true;
    });

    try {
      final imageProvider = NetworkImage(imageUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200),
        maximumColorCount: 20,
      );

      if (mounted) {
        setState(() {
          // Try to get the most vibrant/dominant color
          _dominantColor =
              paletteGenerator.dominantColor?.color ??
              paletteGenerator.vibrantColor?.color ??
              paletteGenerator.darkVibrantColor?.color ??
              paletteGenerator.mutedColor?.color ??
              Colors.black;

          // Get a secondary color for gradient variety
          _vibrantColor =
              paletteGenerator.vibrantColor?.color ??
              paletteGenerator.lightVibrantColor?.color ??
              paletteGenerator.darkMutedColor?.color ??
              _dominantColor;

          _isLoadingPalette = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = Colors.black;
          _vibrantColor = Colors.black;
          _isLoadingPalette = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
                    child: playlist.firstSongThumbnail != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              playlist.firstSongThumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.queue_music_rounded,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
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
        final song = provider.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        // Check if we need to update colors for a new song
        if (song.thumbnailUrl != _currentThumbnailUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updatePaletteIfNeeded();
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _dominantColor.withValues(alpha: 0.9),
                _vibrantColor.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.95),
                Colors.black,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                      Text(
                        'NOW PLAYING',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Show more options
                        },
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Album Art
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _dominantColor.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  song.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                    ),
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                  ),
                                ),
                                // Loading overlay on album art
                                if (provider.isLoadingSong)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: CircularProgressIndicator(
                                              color: AppColors.accent,
                                              strokeWidth: 3,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Loading...',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Glow border effect
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: _dominantColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Song Info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.artist,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Progress Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.accent,
                          inactiveTrackColor: AppColors.surfaceLight,
                          thumbColor: AppColors.accent,
                          overlayColor: AppColors.accent.withValues(alpha: 0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final maxValue =
                                provider.totalDuration.inMilliseconds > 0
                                ? provider.totalDuration.inMilliseconds
                                      .toDouble()
                                : 1.0;
                            final currentValue = provider
                                .currentPosition
                                .inMilliseconds
                                .toDouble()
                                .clamp(0.0, maxValue);
                            return Slider(
                              value: currentValue,
                              min: 0,
                              max: maxValue,
                              onChanged: (value) {
                                provider.seekTo(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(provider.currentPosition),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatDuration(provider.totalDuration),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      IconButton(
                        onPressed: provider.toggleShuffle,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: provider.isShuffled
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      // Previous
                      IconButton(
                        onPressed: provider.playPrevious,
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: AppColors.textPrimary,
                          size: 36,
                        ),
                      ),
                      // Play/Pause
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: provider.togglePlayPause,
                            borderRadius: BorderRadius.circular(36),
                            child: Icon(
                              provider.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      // Next
                      IconButton(
                        onPressed: provider.playNext,
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.textPrimary,
                          size: 36,
                        ),
                      ),
                      // Repeat
                      IconButton(
                        onPressed: provider.toggleRepeat,
                        icon: Icon(
                          provider.repeatMode == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: provider.repeatMode != RepeatMode.off
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => provider.toggleFavorite(song),
                        icon: Icon(
                          provider.isFavorite(song.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: provider.isFavorite(song.id)
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {
                          _showAddToPlaylistSheet(context, song);
                        },
                        icon: const Icon(
                          Icons.playlist_add_rounded,
                          color: AppColors.textSecondary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: () {
                          final songTitle = song.title;
                          final artist = song.artist;
                          final youtubeUrl =
                              'https://www.youtube.com/watch?v=${song.id}';
                          Share.share(
                            '🎵 Listen to "$songTitle" by $artist\n$youtubeUrl\n\nShared from The Loop',
                          );
                        },
                        icon: const Icon(
                          Icons.share_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
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
