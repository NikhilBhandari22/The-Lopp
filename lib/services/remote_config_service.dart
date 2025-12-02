import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service to manage Firebase Remote Config for dynamic API keys
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  /// Initialize Remote Config with default values
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1), // Fetch new values every hour
      ));

      // Set default values (fallback if Firebase is not reachable)
      await _remoteConfig!.setDefaults({
        'youtube_api_keys': '', // Empty default - will use placeholder if not set
      });

      // Fetch and activate remote config
      await _fetchAndActivate();

      _isInitialized = true;
      if (kDebugMode) debugPrint('✅ Remote Config initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Remote Config init error: $e');
      // Continue without Remote Config - will use fallback keys
    }
  }

  /// Fetch and activate remote config values
  Future<bool> _fetchAndActivate() async {
    try {
      final updated = await _remoteConfig!.fetchAndActivate();
      if (kDebugMode) {
        debugPrint('Remote Config fetched, updated: $updated');
      }
      return updated;
    } catch (e) {
      if (kDebugMode) debugPrint('Remote Config fetch error: $e');
      return false;
    }
  }

  /// Get YouTube API keys from Remote Config
  /// Returns list of API keys (comma-separated in Firebase)
  List<String> getYouTubeApiKeys() {
    if (_remoteConfig == null) {
      if (kDebugMode) debugPrint('Remote Config not initialized, using fallback');
      return [];
    }

    final keysString = _remoteConfig!.getString('youtube_api_keys');

    if (keysString.isEmpty) {
      if (kDebugMode) debugPrint('No API keys in Remote Config');
      return [];
    }

    // Split comma-separated keys and trim whitespace
    final keys = keysString
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList();

    if (kDebugMode) debugPrint('Loaded ${keys.length} API keys from Remote Config');
    return keys;
  }

  /// Force refresh Remote Config (useful when all keys are exhausted)
  Future<void> forceRefresh() async {
    if (_remoteConfig == null) return;

    try {
      // Temporarily set minimum fetch interval to 0 for immediate fetch
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));

      await _fetchAndActivate();

      // Reset to normal fetch interval
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      if (kDebugMode) debugPrint('✅ Remote Config force refreshed');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Force refresh error: $e');
    }
  }

  /// Check if Remote Config is initialized
  bool get isInitialized => _isInitialized;
}
