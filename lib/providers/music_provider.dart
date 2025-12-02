import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import '../services/youtube_audio_service.dart';
import '../services/audio_handler.dart';

enum MusicPlayerState { idle, loading, playing, paused, error }

enum RepeatMode { off, one, all }

class MusicProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final StorageService _storageService = StorageService();
  final YouTubeAudioService _audioService = YouTubeAudioService();
  final Uuid _uuid = const Uuid();

  // Flag to track if we're using fallback player
  bool _usingFallbackPlayer = false;

  // Player State
  MusicPlayerState _playerState = MusicPlayerState.idle;
  Song? _currentSong;
  List<Song> _queue = [];
  List<Song> _originalQueue = []; // Store original queue order for unshuffle
  int _currentIndex = 0;
  bool _isShuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;

  // Search State
  List<Song> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // Trending
  List<Song> _trendingSongs = [];
  bool _isLoadingTrending = false;

  // Hindi Songs
  List<Song> _hindiSongs = [];
  bool _isLoadingHindi = false;

  // Hindi Rap Songs
  List<Song> _hindiRapSongs = [];
  bool _isLoadingHindiRap = false;

  // Library
  List<Playlist> _playlists = [];
  List<Song> _recentlyPlayed = [];
  List<Song> _favorites = [];

  // Callback for when a new song starts loading (to open full player)
  VoidCallback? onSongStartedLoading;

  // Getters
  MusicPlayerState get playerState => _playerState;
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  List<Song> get trendingSongs => _trendingSongs;
  bool get isLoadingTrending => _isLoadingTrending;
  List<Song> get hindiSongs => _hindiSongs;
  bool get isLoadingHindi => _isLoadingHindi;
  List<Song> get hindiRapSongs => _hindiRapSongs;
  bool get isLoadingHindiRap => _isLoadingHindiRap;
  List<Playlist> get playlists => _playlists;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Song> get favorites => _favorites;

  bool get isPlaying {
    // Check actual player state for accurate UI
    if (_usingFallbackPlayer) {
      return simplePlayer.playing;
    } else if (isAudioHandlerInitialized) {
      return audioHandler.playing;
    }
    return _playerState == MusicPlayerState.playing;
  }
  bool get isLoadingSong => _playerState == MusicPlayerState.loading;
  bool get hasCurrentSong => _currentSong != null;

  // Initialize (quick startup - no network calls)
  Future<void> init() async {
    try {
      await _storageService.init();
      await _loadLibraryData();
      _setupAudioHandler();
      if (kDebugMode) debugPrint('✅ MusicProvider initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('MusicProvider init error: $e');
      // Continue anyway - app should still work
    }
  }

  // Load all songs in background (called after init)
  void loadAllSongsBackground() {
    Future.microtask(() async {
      if (kDebugMode) debugPrint('📀 Loading songs in background...');
      try {
        await loadTrendingSongs();
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading trending songs: $e');
      }

      try {
        await loadHindiSongs();
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading Hindi songs: $e');
      }

      try {
        await loadHindiRapSongs();
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading Hindi Rap songs: $e');
      }
      if (kDebugMode) debugPrint('✅ Background song loading complete');
    });
  }

  void _setupAudioHandler() {
    // Check if audio handler is initialized
    if (isAudioHandlerInitialized) {
      if (kDebugMode) debugPrint('✅ Setting up full AudioHandler with background support');
      _usingFallbackPlayer = false;
      _setupFullAudioHandler();
    } else {
      if (kDebugMode) debugPrint('⚠️ AudioHandler not initialized, using SimplePlayer fallback');
      _usingFallbackPlayer = true;
      _setupFallbackPlayer();
    }
  }

  void _setupFullAudioHandler() {
    // Set up callbacks for notification controls
    audioHandler.onSkipToNext = playNext;
    audioHandler.onSkipToPrevious = playPrevious;

    // Listen to position updates
    _positionSubscription = audioHandler.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration updates
    _durationSubscription = audioHandler.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // Listen to player state
    _playerStateSubscription = audioHandler.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.playing) {
        _playerState = MusicPlayerState.playing;
      } else {
        _playerState = MusicPlayerState.paused;
      }
      notifyListeners();
    });

    // Listen to processing state
    _processingStateSubscription = audioHandler.processingStateStream.listen((
      state,
    ) {
      if (state == ProcessingState.loading ||
          state == ProcessingState.buffering) {
        _playerState = MusicPlayerState.loading;
      } else if (state == ProcessingState.completed) {
        _handleSongEnded();
      }
      notifyListeners();
    });
  }

  void _setupFallbackPlayer() {
    // Initialize simple player
    initSimplePlayer();

    // Set up callbacks
    simplePlayer.onSkipToNext = playNext;
    simplePlayer.onSkipToPrevious = playPrevious;

    // Listen to position updates
    _positionSubscription = simplePlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration updates
    _durationSubscription = simplePlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // Listen to player state
    _playerStateSubscription = simplePlayer.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.playing) {
        _playerState = MusicPlayerState.playing;
      } else {
        _playerState = MusicPlayerState.paused;
      }
      notifyListeners();
    });

    // Listen to processing state
    _processingStateSubscription = simplePlayer.processingStateStream.listen((
      state,
    ) {
      if (state == ProcessingState.loading ||
          state == ProcessingState.buffering) {
        _playerState = MusicPlayerState.loading;
        notifyListeners();
      } else if (state == ProcessingState.completed) {
        _handleSongEnded();
      }
      // Don't call notifyListeners() here for other states as it may override paused state
    });
  }

  Future<void> _loadLibraryData() async {
    _playlists = await _storageService.getPlaylists();
    _recentlyPlayed = await _storageService.getRecentlyPlayed();
    _favorites = await _storageService.getFavorites();
    notifyListeners();
  }

  // Player Controls
  Future<void> playSong(Song song, {List<Song>? playlist, bool openPlayer = true}) async {
    if (kDebugMode) debugPrint('Playing song: ${song.title} (${song.videoId})');

    _playerState = MusicPlayerState.loading;
    _currentSong = song;
    notifyListeners();

    // Notify that a song started loading (to open full player)
    if (openPlayer && onSongStartedLoading != null) {
      onSongStartedLoading!();
    }

    if (playlist != null) {
      _queue = List.from(playlist);
      _originalQueue = List.from(playlist); // Store original order
      _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _originalQueue.insert(0, song);
        _currentIndex = 0;
      }

      // If shuffle is enabled, shuffle the new queue
      if (_isShuffled) {
        _queue.shuffle();
        // Move current song to front
        _queue.remove(song);
        _queue.insert(0, song);
        _currentIndex = 0;
      }
    } else if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
      _originalQueue.add(song);
      _currentIndex = _queue.length - 1;
    }

    try {
      // Get audio stream URL from YouTube
      final audioUrl = await _audioService.getAudioStreamUrl(song.videoId);

      if (audioUrl == null) {
        if (kDebugMode) debugPrint('ERROR: Failed to get audio URL for ${song.videoId}');
        _playerState = MusicPlayerState.error;
        notifyListeners();
        return;
      }

      // Add to recently played BEFORE starting playback (so UI updates immediately)
      await _storageService.addToRecentlyPlayed(song);
      _recentlyPlayed = await _storageService.getRecentlyPlayed();
      if (kDebugMode) debugPrint('Recently played updated: ${_recentlyPlayed.length} songs');
      notifyListeners(); // Notify for recently played update

      // Play using appropriate player
      if (_usingFallbackPlayer) {
        // Use simple player - don't await, let it play in background
        simplePlayer.playFromUrl(audioUrl);
      } else {
        // Use full audio handler with notification support
        final mediaItem = MediaItem(
          id: song.videoId,
          title: song.title,
          artist: song.artist,
          artUri: Uri.parse(song.thumbnailUrl),
          duration: Duration.zero,
        );
        audioHandler.playFromUrl(audioUrl, item: mediaItem);
      }

      if (kDebugMode) debugPrint('Playback started');
      _playerState = MusicPlayerState.playing;
      notifyListeners();

      // Pre-fetch next song's audio URL in background for faster playback
      _prefetchNextSong();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error playing song: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _playerState = MusicPlayerState.error;
      notifyListeners();
    }
  }

  void _handleSongEnded() {
    if (kDebugMode) debugPrint('Song ended. Repeat mode: $_repeatMode');

    switch (_repeatMode) {
      case RepeatMode.one:
        // Repeat current song
        if (_usingFallbackPlayer) {
          simplePlayer.seek(Duration.zero);
          simplePlayer.play();
        } else if (isAudioHandlerInitialized) {
          audioHandler.seek(Duration.zero);
          audioHandler.play();
        }
        break;
      case RepeatMode.all:
        // Play next and loop back to start when playlist ends
        playNext();
        break;
      case RepeatMode.off:
        // Play through playlist once, stop at end
        if (_currentIndex < _queue.length - 1) {
          playNext();
        } else {
          _playerState = MusicPlayerState.paused;
          notifyListeners();
        }
        break;
    }
  }

  void togglePlayPause() {
    try {
      // Use the actual player's playing state, not our internal state
      final bool currentlyPlaying = _usingFallbackPlayer
          ? simplePlayer.playing
          : (isAudioHandlerInitialized ? audioHandler.playing : false);

      if (kDebugMode) debugPrint('togglePlayPause: currentlyPlaying=$currentlyPlaying');

      if (currentlyPlaying) {
        if (kDebugMode) debugPrint('Pausing...');
        if (_usingFallbackPlayer) {
          simplePlayer.pause();
        } else if (isAudioHandlerInitialized) {
          audioHandler.pause();
        }
      } else {
        if (kDebugMode) debugPrint('Playing...');
        if (_usingFallbackPlayer) {
          simplePlayer.play();
        } else if (isAudioHandlerInitialized) {
          audioHandler.play();
        }
      }
      // Don't set _playerState here - let the stream listener handle it
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling play/pause: $e');
    }
  }

  void playNext() {
    if (_queue.isEmpty) return;

    // In shuffle mode, the queue is already shuffled, just go to next index
    _currentIndex = (_currentIndex + 1) % _queue.length;
    playSong(_queue[_currentIndex], openPlayer: false);
  }

  void playPrevious() {
    if (_queue.isEmpty) return;

    // If more than 3 seconds played, restart current song
    if (_currentPosition.inSeconds > 3) {
      if (_usingFallbackPlayer) {
        simplePlayer.seek(Duration.zero);
      } else if (isAudioHandlerInitialized) {
        audioHandler.seek(Duration.zero);
      }
      return;
    }

    // In shuffle mode, the queue is already shuffled, just go to previous index
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    playSong(_queue[_currentIndex], openPlayer: false);
  }

  void seekTo(Duration position) {
    if (_usingFallbackPlayer) {
      simplePlayer.seek(position);
    } else if (isAudioHandlerInitialized) {
      audioHandler.seek(position);
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;

    if (_isShuffled) {
      // Save original order and shuffle the queue
      _originalQueue = List.from(_queue);
      final currentSong = _queue.isNotEmpty ? _queue[_currentIndex] : null;

      // Shuffle the queue
      _queue.shuffle();

      // Move current song to front if playing
      if (currentSong != null) {
        _queue.remove(currentSong);
        _queue.insert(0, currentSong);
        _currentIndex = 0;
      }
    } else {
      // Restore original order
      if (_originalQueue.isNotEmpty) {
        final currentSong = _queue.isNotEmpty ? _queue[_currentIndex] : null;
        _queue = List.from(_originalQueue);

        // Find current song in original queue
        if (currentSong != null) {
          _currentIndex = _queue.indexWhere((s) => s.id == currentSong.id);
          if (_currentIndex == -1) _currentIndex = 0;
        }
      }
    }

    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  // Search
  Future<void> searchMusic(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      _searchResults = await _youtubeService.searchMusic(query);
      if (kDebugMode) debugPrint('Search found ${_searchResults.length} results for: "$query"');
    } catch (e) {
      if (kDebugMode) debugPrint('Search error for "$query": $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  // Trending
  Future<void> loadTrendingSongs() async {
    _isLoadingTrending = true;
    notifyListeners();

    try {
      _trendingSongs = await _youtubeService.getTrendingMusic();
      if (kDebugMode) debugPrint('Loaded ${_trendingSongs.length} trending songs');
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading trending songs: $e');
      _trendingSongs = [];
    }

    _isLoadingTrending = false;
    notifyListeners();
  }

  // Hindi Songs
  Future<void> loadHindiSongs() async {
    _isLoadingHindi = true;
    notifyListeners();

    try {
      _hindiSongs = await _youtubeService.searchMusic('Hindi songs 2024 latest', maxResults: 15);
      if (kDebugMode) debugPrint('Loaded ${_hindiSongs.length} Hindi songs');
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading Hindi songs: $e');
      _hindiSongs = [];
    }

    _isLoadingHindi = false;
    notifyListeners();
  }

  // Hindi Rap Songs
  Future<void> loadHindiRapSongs() async {
    _isLoadingHindiRap = true;
    notifyListeners();

    try {
      _hindiRapSongs = await _youtubeService.searchMusic('Hindi rap songs 2024', maxResults: 15);
      if (kDebugMode) debugPrint('Loaded ${_hindiRapSongs.length} Hindi Rap songs');
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading Hindi Rap songs: $e');
      _hindiRapSongs = [];
    }

    _isLoadingHindiRap = false;
    notifyListeners();
  }

  // Playlists
  Future<void> createPlaylist(String name, {String? description}) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      songs: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storageService.addPlaylist(playlist);
    _playlists = await _storageService.getPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _storageService.deletePlaylist(playlistId);
    _playlists = await _storageService.getPlaylists();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _storageService.addSongToPlaylist(playlistId, song);
    _playlists = await _storageService.getPlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _storageService.removeSongFromPlaylist(playlistId, songId);
    _playlists = await _storageService.getPlaylists();
    notifyListeners();
  }

  // Favorites
  Future<void> toggleFavorite(Song song) async {
    await _storageService.toggleFavorite(song);
    _favorites = await _storageService.getFavorites();
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favorites.any((s) => s.id == songId);
  }

  // Queue Management
  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length && index != _currentIndex) {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue = _currentSong != null ? [_currentSong!] : [];
    _currentIndex = 0;
    notifyListeners();
  }

  // Pre-fetch next song's audio URL in background
  void _prefetchNextSong() {
    if (_queue.isEmpty) return;

    // Calculate next index based on repeat mode
    int nextIndex;
    if (_repeatMode == RepeatMode.one) {
      // For repeat one, next song is the same song (already cached)
      return;
    } else {
      nextIndex = (_currentIndex + 1) % _queue.length;
    }

    // Don't prefetch if we're at the end and not repeating
    if (_repeatMode == RepeatMode.off && _currentIndex >= _queue.length - 1) {
      return;
    }

    final nextSong = _queue[nextIndex];
    if (kDebugMode) debugPrint('⏩ Pre-fetching next song: ${nextSong.title}');

    // Pre-fetch in background (don't await)
    Future.microtask(() async {
      await _audioService.prefetchAudioUrl(nextSong.videoId);
    });
  }

  // Pre-fetch audio URLs for recently played songs on app start
  void prefetchRecentlyPlayedUrls() {
    if (_recentlyPlayed.isEmpty) return;

    if (kDebugMode) debugPrint('⏩ Pre-fetching ${_recentlyPlayed.length} recently played songs...');

    // Prefetch first 5 recently played songs in background
    Future.microtask(() async {
      final songsToFetch = _recentlyPlayed.take(5).toList();
      for (final song in songsToFetch) {
        await _audioService.prefetchAudioUrl(song.videoId);
      }
      if (kDebugMode) debugPrint('✅ Pre-fetched ${songsToFetch.length} recent songs');
    });
  }

  // Check if audio URL is cached for a song
  bool isAudioCached(String videoId) {
    return _audioService.isCached(videoId);
  }

  // Cleanup
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _processingStateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
