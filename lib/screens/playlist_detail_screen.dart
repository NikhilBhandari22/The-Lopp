import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/playlist.dart';
import '../providers/music_provider.dart';
import '../widgets/song_card.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        // Get updated playlist from provider
        final updatedPlaylist = provider.playlists.firstWhere(
          (p) => p.id == playlist.id,
          orElse: () => playlist,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            top: false, // SliverAppBar handles top
            child: CustomScrollView(
              slivers: [
                // App Bar with Cover
                SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      // Show options
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image
                      if (updatedPlaylist.firstSongThumbnail != null)
                        Image.network(
                          updatedPlaylist.firstSongThumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                        )
                      else
                        _buildCoverPlaceholder(),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.5),
                              AppColors.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Playlist Info
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedPlaylist.name,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${updatedPlaylist.songCount} songs',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Play All Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: updatedPlaylist.songs.isNotEmpty
                              ? () {
                                  provider.playSong(
                                    updatedPlaylist.songs.first,
                                    playlist: updatedPlaylist.songs,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            'Play All',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Shuffle play
                            if (updatedPlaylist.songs.isNotEmpty) {
                              provider.toggleShuffle();
                              provider.playSong(
                                updatedPlaylist.songs.first,
                                playlist: updatedPlaylist.songs,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.shuffle_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Songs List
              if (updatedPlaylist.songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No songs in this playlist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for songs and add them here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = updatedPlaylist.songs[index];
                      final isPlaying =
                          provider.currentSong?.id == song.id && provider.isPlaying;

                      return Dismissible(
                        key: Key(song.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          provider.removeSongFromPlaylist(
                            updatedPlaylist.id,
                            song.id,
                          );
                        },
                        child: SongCard(
                          song: song,
                          isPlaying: isPlaying,
                          showAddButton: false,
                          onTap: () {
                            provider.playSong(
                              song,
                              playlist: updatedPlaylist.songs,
                            );
                          },
                          onMoreTap: () {
                            _showSongOptions(
                              context,
                              provider,
                              updatedPlaylist.id,
                              song.id,
                            );
                          },
                        ),
                      );
                    },
                    childCount: updatedPlaylist.songs.length,
                  ),
                ),

              // Bottom padding for mini player
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: Colors.white,
          size: 80,
        ),
      ),
    );
  }

  void _showSongOptions(
    BuildContext context,
    MusicProvider provider,
    String playlistId,
    String songId,
  ) {
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
          children: [
            ListTile(
              leading: const Icon(
                Icons.playlist_remove_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Remove from playlist',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
              onTap: () {
                provider.removeSongFromPlaylist(playlistId, songId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.queue_rounded,
                color: AppColors.accent,
              ),
              title: Text(
                'Add to queue',
                style: GoogleFonts.poppins(color: AppColors.textPrimary),
              ),
              onTap: () {
                // Add to queue logic
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
