import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioService {
  YoutubeExplode? _yt;

  // Cache for audio URLs with expiration (YouTube URLs expire after ~6 hours)
  final Map<String, _CachedUrl> _urlCache = {};
  static const Duration _cacheExpiration = Duration(hours: 5);

  YoutubeExplode get yt {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  /// Get audio stream URL with caching
  /// Cached URLs significantly speed up replay of recent songs
  Future<String?> getAudioStreamUrl(String videoId) async {
    // Check cache first
    final cached = _urlCache[videoId];
    if (cached != null && !cached.isExpired) {
      if (kDebugMode) debugPrint('🎵 Cache HIT for audio URL: $videoId');
      return cached.url;
    }

    if (kDebugMode) debugPrint('🎵 Cache MISS - fetching audio stream for: $videoId');

    try {
      // Get stream manifest
      final manifest = await yt.videos.streamsClient.getManifest(videoId);

      String? audioUrl;

      // For iOS compatibility, prefer muxed streams (mp4) over audio-only (webm)
      // Muxed streams are mp4 format which iOS handles better
      if (manifest.muxed.isNotEmpty) {
        final muxedStreams = manifest.muxed.sortByBitrate();
        // Use highest quality muxed stream
        final selectedStream = muxedStreams.last;
        if (kDebugMode) debugPrint('Using muxed stream: ${selectedStream.bitrate.kiloBitsPerSecond} kbps');
        audioUrl = selectedStream.url.toString();
      }

      // Fallback to audio-only if no muxed available
      if (audioUrl == null && manifest.audioOnly.isNotEmpty) {
        // Try to find mp4a codec (AAC) which works on iOS
        final audioStreams = manifest.audioOnly.toList();

        // Sort by bitrate
        audioStreams.sort((a, b) => a.bitrate.compareTo(b.bitrate));

        // Prefer AAC/mp4a codec for iOS compatibility
        AudioOnlyStreamInfo? selectedStream;
        for (final stream in audioStreams.reversed) {
          final codec = stream.audioCodec.toLowerCase();
          if (codec.contains('mp4a') || codec.contains('aac')) {
            selectedStream = stream;
            break;
          }
        }

        // If no AAC found, use highest bitrate
        selectedStream ??= audioStreams.last;
        if (kDebugMode) debugPrint('Selected audio stream: ${selectedStream.bitrate.kiloBitsPerSecond} kbps');
        audioUrl = selectedStream.url.toString();
      }

      // Cache the URL if found
      if (audioUrl != null) {
        _urlCache[videoId] = _CachedUrl(audioUrl);
        if (kDebugMode) debugPrint('✅ Cached audio URL for: $videoId');
      } else {
        if (kDebugMode) debugPrint('No streams available for video: $videoId');
      }

      return audioUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error getting audio stream for $videoId: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // Try recreating the client on error
      _yt?.close();
      _yt = null;

      return null;
    }
  }

  /// Pre-fetch audio URL for a video (for background pre-loading)
  /// Call this to warm up the cache for upcoming songs
  Future<void> prefetchAudioUrl(String videoId) async {
    // Check if already cached
    final cached = _urlCache[videoId];
    if (cached != null && !cached.isExpired) {
      if (kDebugMode) debugPrint('⏩ Already cached: $videoId');
      return;
    }

    if (kDebugMode) debugPrint('⏩ Pre-fetching audio URL: $videoId');

    // Fetch in background (don't await in calling code)
    await getAudioStreamUrl(videoId);
  }

  /// Pre-fetch multiple audio URLs (for queue pre-loading)
  Future<void> prefetchMultiple(List<String> videoIds) async {
    for (final videoId in videoIds) {
      await prefetchAudioUrl(videoId);
    }
  }

  /// Check if a URL is cached and valid
  bool isCached(String videoId) {
    final cached = _urlCache[videoId];
    return cached != null && !cached.isExpired;
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    _urlCache.removeWhere((_, cached) => cached.isExpired);
    if (kDebugMode) debugPrint('🧹 Cleared expired audio URL cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validCount = _urlCache.values.where((c) => !c.isExpired).length;
    return {
      'totalCached': _urlCache.length,
      'validCached': validCount,
      'expiredCount': _urlCache.length - validCount,
    };
  }

  Future<AudioStreamInfo?> getAudioStreamInfo(String videoId) async {
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();

      if (audioStreams.isNotEmpty) {
        return audioStreams.last;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting audio stream info: $e');
      return null;
    }
  }

  void dispose() {
    _yt?.close();
    _yt = null;
    _urlCache.clear();
  }
}

/// Cached URL with expiration time
class _CachedUrl {
  final String url;
  final DateTime cachedAt;

  _CachedUrl(this.url) : cachedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > YouTubeAudioService._cacheExpiration;
}
