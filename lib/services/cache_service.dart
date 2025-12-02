import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _searchCachePrefix = 'search_cache_';
  static const String _trendingCacheKey = 'trending_cache';
  static const String _cacheTimestampSuffix = '_timestamp';

  // Cache durations in milliseconds
  static const int searchCacheDuration = 24 * 60 * 60 * 1000; // 24 hours
  static const int trendingCacheDuration = 6 * 60 * 60 * 1000; // 6 hours
  static const int videoDetailsCacheDuration = 7 * 24 * 60 * 60 * 1000; // 7 days

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Generate a normalized cache key for search queries
  String _getSearchCacheKey(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    return '$_searchCachePrefix$normalizedQuery';
  }

  // Check if cache is still valid
  bool _isCacheValid(String timestampKey, int maxAge) {
    final timestamp = _prefs.getInt(timestampKey);
    if (timestamp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - timestamp) < maxAge;
  }

  // Search Results Caching
  Future<List<Map<String, dynamic>>?> getCachedSearchResults(String query) async {
    await init();

    final cacheKey = _getSearchCacheKey(query);
    final timestampKey = '$cacheKey$_cacheTimestampSuffix';

    if (!_isCacheValid(timestampKey, searchCacheDuration)) {
      return null;
    }

    final cachedData = _prefs.getString(cacheKey);
    if (cachedData == null) return null;

    try {
      final List<dynamic> decoded = json.decode(cachedData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheSearchResults(String query, List<Map<String, dynamic>> results) async {
    await init();

    final cacheKey = _getSearchCacheKey(query);
    final timestampKey = '$cacheKey$_cacheTimestampSuffix';

    await _prefs.setString(cacheKey, json.encode(results));
    await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Trending Songs Caching
  Future<List<Map<String, dynamic>>?> getCachedTrendingSongs() async {
    await init();

    final timestampKey = '$_trendingCacheKey$_cacheTimestampSuffix';

    if (!_isCacheValid(timestampKey, trendingCacheDuration)) {
      return null;
    }

    final cachedData = _prefs.getString(_trendingCacheKey);
    if (cachedData == null) return null;

    try {
      final List<dynamic> decoded = json.decode(cachedData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheTrendingSongs(List<Map<String, dynamic>> songs) async {
    await init();

    final timestampKey = '$_trendingCacheKey$_cacheTimestampSuffix';

    await _prefs.setString(_trendingCacheKey, json.encode(songs));
    await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Video Details Caching (for playlist songs)
  Future<Map<String, dynamic>?> getCachedVideoDetails(String videoId) async {
    await init();

    final cacheKey = 'video_$videoId';
    final timestampKey = '$cacheKey$_cacheTimestampSuffix';

    if (!_isCacheValid(timestampKey, videoDetailsCacheDuration)) {
      return null;
    }

    final cachedData = _prefs.getString(cacheKey);
    if (cachedData == null) return null;

    try {
      return json.decode(cachedData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheVideoDetails(String videoId, Map<String, dynamic> details) async {
    await init();

    final cacheKey = 'video_$videoId';
    final timestampKey = '$cacheKey$_cacheTimestampSuffix';

    await _prefs.setString(cacheKey, json.encode(details));
    await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Clear old cache entries (call periodically)
  Future<void> clearExpiredCache() async {
    await init();

    final keys = _prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.endsWith(_cacheTimestampSuffix)) {
        final timestamp = _prefs.getInt(key);
        if (timestamp != null) {
          int maxAge = searchCacheDuration;

          if (key.contains(_trendingCacheKey)) {
            maxAge = trendingCacheDuration;
          } else if (key.contains('video_')) {
            maxAge = videoDetailsCacheDuration;
          }

          if ((now - timestamp) > maxAge) {
            final dataKey = key.replaceAll(_cacheTimestampSuffix, '');
            await _prefs.remove(key);
            await _prefs.remove(dataKey);
          }
        }
      }
    }
  }

  // Get cache statistics (useful for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    await init();

    final keys = _prefs.getKeys();
    int searchCacheCount = 0;
    int videoCacheCount = 0;
    bool hasTrendingCache = false;

    for (final key in keys) {
      if (key.startsWith(_searchCachePrefix) && !key.endsWith(_cacheTimestampSuffix)) {
        searchCacheCount++;
      } else if (key.startsWith('video_') && !key.endsWith(_cacheTimestampSuffix)) {
        videoCacheCount++;
      } else if (key == _trendingCacheKey) {
        hasTrendingCache = true;
      }
    }

    return {
      'searchCacheCount': searchCacheCount,
      'videoCacheCount': videoCacheCount,
      'hasTrendingCache': hasTrendingCache,
    };
  }
}
