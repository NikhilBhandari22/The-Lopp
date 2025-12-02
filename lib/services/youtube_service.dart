import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import 'api_keys.dart';
import 'cache_service.dart';

/// Exception thrown when YouTube API quota is exceeded
class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException([this.message = 'YouTube API quota exceeded']);

  @override
  String toString() => message;
}

class YouTubeService {
  static const String _baseUrl = ApiKeys.youtubeBaseUrl;

  final CacheService _cacheService = CacheService();
  final ApiKeyManager _keyManager = ApiKeyManager();

  /// Get current API key from the key manager
  String get _apiKey => _keyManager.currentKey;

  /// Execute an API call with automatic key rotation on quota exceeded
  /// Retries with the next available API key when quota is exceeded
  Future<T> _executeWithKeyRotation<T>(
    Future<T> Function() apiCall,
    String operationName,
  ) async {
    int attempts = 0;
    final maxAttempts = ApiKeys.youtubeApiKeys.length;

    while (attempts < maxAttempts) {
      try {
        return await apiCall();
      } on QuotaExceededException {
        attempts++;
        if (_keyManager.rotateToNextKey()) {
          if (kDebugMode) {
            debugPrint('🔄 Rotating to key ${_keyManager.getStatus()['currentKeyIndex']} for $operationName (attempt $attempts/$maxAttempts)');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ All API keys exhausted for $operationName');
          }
          throw Exception('All YouTube API keys have exceeded their quota. Please try again later.');
        }
      }
    }

    throw Exception('All YouTube API keys have exceeded their quota. Please try again later.');
  }

  /// Search for music videos on YouTube with caching
  /// Cache TTL: 24 hours - saves ~100 units per cached search
  /// Automatically rotates API keys on quota exceeded errors
  Future<List<Song>> searchMusic(String query, {int maxResults = 20}) async {
    if (_apiKey == 'PLACEHOLDER_API_KEY') {
      return _getMockSongs(query);
    }

    // Check cache first
    final cachedResults = await _cacheService.getCachedSearchResults(query);
    if (cachedResults != null) {
      if (kDebugMode) debugPrint('Cache HIT for search: "$query"');
      return cachedResults.map((item) => Song.fromCacheMap(item)).toList();
    }

    if (kDebugMode) debugPrint('Cache MISS for search: "$query" - calling API');

    return _executeWithKeyRotation(() async {
      final url = Uri.parse(
        '$_baseUrl/search?part=snippet&q=$query&type=video&videoCategoryId=${ApiKeys.musicCategoryId}&maxResults=$maxResults&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        final songs = items.map((item) => Song.fromYouTubeApi(item)).toList();

        // Cache the results
        final cacheData = songs.map((song) => song.toCacheMap()).toList();
        await _cacheService.cacheSearchResults(query, cacheData);

        return songs;
      } else if (_keyManager.isQuotaExceeded(response.statusCode, response.body)) {
        if (kDebugMode) debugPrint('⚠️ Quota exceeded for key ${_keyManager.getStatus()['currentKeyIndex']}');
        throw QuotaExceededException();
      } else {
        if (kDebugMode) debugPrint('❌ Search API error: ${response.statusCode}');
        throw Exception('Failed to search music: ${response.statusCode}');
      }
    }, 'search "$query"');
  }

  /// Get trending music videos with caching
  /// Cache TTL: 6 hours - saves ~1 unit per cached request
  /// Automatically rotates API keys on quota exceeded errors
  Future<List<Song>> getTrendingMusic({int maxResults = 20}) async {
    if (_apiKey == 'PLACEHOLDER_API_KEY') {
      return _getMockTrendingSongs();
    }

    // Check cache first
    final cachedTrending = await _cacheService.getCachedTrendingSongs();
    if (cachedTrending != null) {
      if (kDebugMode) debugPrint('Cache HIT for trending songs');
      return cachedTrending.map((item) => Song.fromCacheMap(item)).toList();
    }

    if (kDebugMode) debugPrint('Cache MISS for trending songs - calling API');

    return _executeWithKeyRotation(() async {
      final url = Uri.parse(
        '$_baseUrl/videos?part=snippet&chart=mostPopular&videoCategoryId=${ApiKeys.musicCategoryId}&maxResults=$maxResults&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>;
        final songs = items.map((item) => Song.fromYouTubeApi(item)).toList();

        // Cache the results
        final cacheData = songs.map((song) => song.toCacheMap()).toList();
        await _cacheService.cacheTrendingSongs(cacheData);

        return songs;
      } else if (_keyManager.isQuotaExceeded(response.statusCode, response.body)) {
        if (kDebugMode) debugPrint('⚠️ Quota exceeded for key ${_keyManager.getStatus()['currentKeyIndex']}');
        throw QuotaExceededException();
      } else {
        if (kDebugMode) debugPrint('❌ API Error: ${response.statusCode}');
        throw Exception('Failed to get trending music: ${response.statusCode}');
      }
    }, 'trending music');
  }

  /// Get video details by ID with caching
  /// Cache TTL: 7 days - video details rarely change
  /// Automatically rotates API keys on quota exceeded errors
  Future<Song?> getVideoDetails(String videoId) async {
    if (_apiKey == 'PLACEHOLDER_API_KEY') {
      return null;
    }

    // Check cache first
    final cachedDetails = await _cacheService.getCachedVideoDetails(videoId);
    if (cachedDetails != null) {
      if (kDebugMode) debugPrint('Cache HIT for video: $videoId');
      return Song.fromCacheMap(cachedDetails);
    }

    if (kDebugMode) debugPrint('Cache MISS for video: $videoId - calling API');

    try {
      return await _executeWithKeyRotation(() async {
        final url = Uri.parse(
          '$_baseUrl/videos?part=snippet,contentDetails&id=$videoId&key=$_apiKey',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>;
          if (items.isNotEmpty) {
            final song = Song.fromYouTubeApi(items.first);

            // Cache the result
            await _cacheService.cacheVideoDetails(videoId, song.toCacheMap());

            return song;
          }
          return null;
        } else if (_keyManager.isQuotaExceeded(response.statusCode, response.body)) {
          if (kDebugMode) debugPrint('⚠️ Quota exceeded for key ${_keyManager.getStatus()['currentKeyIndex']}');
          throw QuotaExceededException();
        }
        return null;
      }, 'video details $videoId');
    } catch (e) {
      if (e is QuotaExceededException) rethrow;
      return null;
    }
  }

  /// Batch get video details - only fetches uncached videos
  /// Reduces API calls significantly for playlists
  /// Automatically rotates API keys on quota exceeded errors
  Future<List<Song>> getVideoDetailsBatch(List<String> videoIds) async {
    if (_apiKey == 'PLACEHOLDER_API_KEY') {
      return [];
    }

    final List<Song> results = [];
    final List<String> uncachedIds = [];

    // Check cache for each video
    for (final videoId in videoIds) {
      final cachedDetails = await _cacheService.getCachedVideoDetails(videoId);
      if (cachedDetails != null) {
        results.add(Song.fromCacheMap(cachedDetails));
      } else {
        uncachedIds.add(videoId);
      }
    }

    if (kDebugMode) {
      debugPrint('Batch: ${results.length} cached, ${uncachedIds.length} need API call');
    }

    // Fetch uncached videos in batches of 50 (API limit)
    if (uncachedIds.isNotEmpty) {
      for (var i = 0; i < uncachedIds.length; i += 50) {
        final batch = uncachedIds.skip(i).take(50).toList();
        final idsString = batch.join(',');

        try {
          final batchResults = await _executeWithKeyRotation(() async {
            final url = Uri.parse(
              '$_baseUrl/videos?part=snippet,contentDetails&id=$idsString&key=$_apiKey',
            );

            final response = await http.get(url);

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final items = data['items'] as List<dynamic>;
              final songs = <Song>[];

              for (final item in items) {
                final song = Song.fromYouTubeApi(item);
                songs.add(song);

                // Cache each video
                await _cacheService.cacheVideoDetails(song.videoId, song.toCacheMap());
              }
              return songs;
            } else if (_keyManager.isQuotaExceeded(response.statusCode, response.body)) {
              if (kDebugMode) debugPrint('⚠️ Quota exceeded for key ${_keyManager.getStatus()['currentKeyIndex']}');
              throw QuotaExceededException();
            }
            return <Song>[];
          }, 'batch video details');

          results.addAll(batchResults);
        } catch (e) {
          if (kDebugMode) debugPrint('Error fetching batch: $e');
        }
      }
    }

    return results;
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    await _cacheService.clearExpiredCache();
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  /// Mock data for development without API key
  List<Song> _getMockSongs(String query) {
    return [
      Song(
        id: 'mock1',
        title: 'Blinding Lights - $query',
        artist: 'The Weeknd',
        thumbnailUrl: 'https://picsum.photos/seed/song1/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'The Weeknd',
      ),
      Song(
        id: 'mock2',
        title: 'Shape of You - $query',
        artist: 'Ed Sheeran',
        thumbnailUrl: 'https://picsum.photos/seed/song2/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Ed Sheeran',
      ),
      Song(
        id: 'mock3',
        title: 'Stay - $query',
        artist: 'The Kid LAROI & Justin Bieber',
        thumbnailUrl: 'https://picsum.photos/seed/song3/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'The Kid LAROI',
      ),
      Song(
        id: 'mock4',
        title: 'Levitating - $query',
        artist: 'Dua Lipa',
        thumbnailUrl: 'https://picsum.photos/seed/song4/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Dua Lipa',
      ),
      Song(
        id: 'mock5',
        title: 'Peaches - $query',
        artist: 'Justin Bieber',
        thumbnailUrl: 'https://picsum.photos/seed/song5/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Justin Bieber',
      ),
    ];
  }

  List<Song> _getMockTrendingSongs() {
    return [
      const Song(
        id: 'trend1',
        title: 'Anti-Hero',
        artist: 'Taylor Swift',
        thumbnailUrl: 'https://picsum.photos/seed/trend1/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Taylor Swift',
      ),
      const Song(
        id: 'trend2',
        title: 'Unholy',
        artist: 'Sam Smith & Kim Petras',
        thumbnailUrl: 'https://picsum.photos/seed/trend2/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Sam Smith',
      ),
      const Song(
        id: 'trend3',
        title: 'Bad Habit',
        artist: 'Steve Lacy',
        thumbnailUrl: 'https://picsum.photos/seed/trend3/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Steve Lacy',
      ),
      const Song(
        id: 'trend4',
        title: 'As It Was',
        artist: 'Harry Styles',
        thumbnailUrl: 'https://picsum.photos/seed/trend4/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Harry Styles',
      ),
      const Song(
        id: 'trend5',
        title: 'Heat Waves',
        artist: 'Glass Animals',
        thumbnailUrl: 'https://picsum.photos/seed/trend5/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Glass Animals',
      ),
      const Song(
        id: 'trend6',
        title: 'Flowers',
        artist: 'Miley Cyrus',
        thumbnailUrl: 'https://picsum.photos/seed/trend6/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Miley Cyrus',
      ),
      const Song(
        id: 'trend7',
        title: 'Calm Down',
        artist: 'Rema & Selena Gomez',
        thumbnailUrl: 'https://picsum.photos/seed/trend7/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Rema',
      ),
      const Song(
        id: 'trend8',
        title: 'Creepin',
        artist: 'Metro Boomin & The Weeknd',
        thumbnailUrl: 'https://picsum.photos/seed/trend8/480/360',
        videoId: 'dQw4w9WgXcQ',
        channelTitle: 'Metro Boomin',
      ),
    ];
  }
}
