// YouTube Data API v3 Keys
//
// API keys are loaded dynamically from Firebase Remote Config.
// This allows adding/removing keys without rebuilding the app.
//
// SETUP:
// 1. Go to Firebase Console > Remote Config
// 2. Add parameter: youtube_api_keys
// 3. Value: comma-separated keys (e.g., "key1,key2,key3")
// 4. Publish changes
//
// To get API keys:
// 1. Go to https://console.cloud.google.com/
// 2. Create a new project or select an existing one
// 3. Enable the YouTube Data API v3
// 4. Go to Credentials and create an API key

import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

class ApiKeys {
  // Keys loaded from Firebase Remote Config
  static List<String> _remoteKeys = [];

  // Initialize keys from Remote Config
  static void loadFromRemoteConfig() {
    final remoteConfig = RemoteConfigService();
    _remoteKeys = remoteConfig.getYouTubeApiKeys();
    if (kDebugMode) {
      debugPrint('Loaded ${_remoteKeys.length} API keys from Firebase');
    }
  }

  // List of YouTube API keys
  static List<String> get youtubeApiKeys {
    // Use remote keys if available
    if (_remoteKeys.isNotEmpty) {
      return _remoteKeys;
    }

    // Fallback to placeholder (app won't work without keys)
    return ['PLACEHOLDER_API_KEY'];
  }

  /// Reload keys from Remote Config (call after force refresh)
  static void reloadKeys() {
    loadFromRemoteConfig();
  }

  /// Check if API keys are properly configured
  static bool get isConfigured =>
      _remoteKeys.isNotEmpty && _remoteKeys.first != 'PLACEHOLDER_API_KEY';

  // Legacy single key accessor (for backwards compatibility)
  static String get youtubeApiKey => youtubeApiKeys.first;

  // YouTube API Base URL
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';

  // Video Category ID for Music
  static const String musicCategoryId = '10';
}

/// Manages API key rotation when quota is exceeded
class ApiKeyManager {
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;
  ApiKeyManager._internal();

  int _currentKeyIndex = 0;
  final Set<int> _exhaustedKeys = {};

  /// Get the current active API key
  String get currentKey {
    final keys = ApiKeys.youtubeApiKeys;

    if (_exhaustedKeys.length >= keys.length) {
      // All keys exhausted, try to refresh from Firebase
      _tryRefreshKeys();
      _exhaustedKeys.clear();
      _currentKeyIndex = 0;
    }

    if (_currentKeyIndex >= keys.length) {
      _currentKeyIndex = 0;
    }

    return keys[_currentKeyIndex];
  }

  /// Try to refresh keys from Firebase when all are exhausted
  Future<void> _tryRefreshKeys() async {
    if (kDebugMode) debugPrint('All keys exhausted, trying to refresh from Firebase...');

    try {
      final remoteConfig = RemoteConfigService();
      await remoteConfig.forceRefresh();
      ApiKeys.reloadKeys();

      if (kDebugMode) {
        debugPrint('Refreshed keys: ${ApiKeys.youtubeApiKeys.length} available');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to refresh keys: $e');
    }
  }

  /// Mark current key as exhausted and switch to next available key
  /// Returns true if there's another key available, false if all exhausted
  bool rotateToNextKey() {
    _exhaustedKeys.add(_currentKeyIndex);
    final keys = ApiKeys.youtubeApiKeys;

    // Find next non-exhausted key
    for (int i = 0; i < keys.length; i++) {
      int nextIndex = (i + 1) % keys.length;
      if (!_exhaustedKeys.contains(nextIndex)) {
        _currentKeyIndex = nextIndex;
        if (kDebugMode) {
          debugPrint('Rotated to key ${_currentKeyIndex + 1}/${keys.length}');
        }
        return true;
      }
    }

    // All keys exhausted
    if (kDebugMode) debugPrint('All ${keys.length} API keys exhausted');
    return false;
  }

  /// Check if a response indicates quota exceeded
  bool isQuotaExceeded(int statusCode, String responseBody) {
    if (statusCode == 403) {
      return responseBody.contains('quotaExceeded') ||
             responseBody.contains('exceeded your quota');
    }
    return false;
  }

  /// Reset all keys (useful when quota resets at midnight PT)
  void resetAllKeys() {
    _exhaustedKeys.clear();
    _currentKeyIndex = 0;
  }

  /// Get status info for debugging
  Map<String, dynamic> getStatus() {
    final keys = ApiKeys.youtubeApiKeys;
    return {
      'totalKeys': keys.length,
      'currentKeyIndex': _currentKeyIndex + 1,
      'exhaustedKeys': _exhaustedKeys.length,
      'availableKeys': keys.length - _exhaustedKeys.length,
      'isConfigured': ApiKeys.isConfigured,
    };
  }
}
