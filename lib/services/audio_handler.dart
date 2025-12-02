import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TheLoopAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Callbacks for next/previous
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  TheLoopAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Broadcast playback state changes
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    // Handle player state changes
    _player.playerStateStream.listen((playerState) {
      if (kDebugMode) debugPrint('Player state: ${playerState.processingState}, playing: ${playerState.playing}');
      _broadcastState();
    });

    // Handle duration changes
    _player.durationStream.listen((duration) {
      if (kDebugMode) debugPrint('Duration updated: $duration');
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    // Handle position changes
    _player.positionStream.listen((position) {
      _broadcastState();
    });

    // Handle playback completion
    _player.processingStateStream.listen((state) {
      if (kDebugMode) debugPrint('Processing state: $state');
    });
  }

  void _broadcastState() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  @override
  Future<void> play() async {
    if (kDebugMode) debugPrint('AudioHandler: play() called');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    if (kDebugMode) debugPrint('AudioHandler: pause() called');
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }

  Future<void> setAudioSource(String url, {required MediaItem item}) async {
    if (kDebugMode) debugPrint('AudioHandler: Setting audio source...');
    mediaItem.add(item);
    try {
      // Set URL with custom headers to help with YouTube streams
      await _player.setUrl(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        },
      );
      if (kDebugMode) debugPrint('AudioHandler: Audio source set successfully');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error setting audio source: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> playFromUrl(String url, {required MediaItem item}) async {
    if (kDebugMode) debugPrint('AudioHandler: playFromUrl called');

    // Stop any current playback
    await _player.stop();

    // Set the new source
    await setAudioSource(url, item: item);

    // Start playing
    await play();
    if (kDebugMode) debugPrint('AudioHandler: play() completed, playing: ${_player.playing}');
  }

  AudioPlayer get player => _player;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get playing => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing in background - don't stop
  }
}

/// Simple audio player fallback when audio_service fails
/// This provides basic playback without background/notification support
class SimpleAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  // Callbacks for next/previous
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  SimpleAudioPlayer() {
    _init();
  }

  void _init() {
    _player.playerStateStream.listen((playerState) {
      if (kDebugMode) debugPrint('SimplePlayer state: ${playerState.processingState}, playing: ${playerState.playing}');
    });

    _player.processingStateStream.listen((state) {
      if (kDebugMode) debugPrint('SimplePlayer processing state: $state');
    });
  }

  Future<void> play() async {
    if (kDebugMode) debugPrint('SimplePlayer: play() called');
    await _player.play();
  }

  Future<void> pause() async {
    if (kDebugMode) debugPrint('SimplePlayer: pause() called');
    await _player.pause();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> playFromUrl(String url) async {
    if (kDebugMode) debugPrint('SimplePlayer: playFromUrl called');

    // Stop any current playback
    await _player.stop();

    try {
      // Set URL with custom headers
      await _player.setUrl(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
        },
      );
      if (kDebugMode) debugPrint('SimplePlayer: Audio source set successfully');

      // Start playing
      await play();
      if (kDebugMode) debugPrint('SimplePlayer: play() completed, playing: ${_player.playing}');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('SimplePlayer error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get playing => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  void dispose() {
    _player.dispose();
  }
}

// Global audio handler instance (for full background support)
TheLoopAudioHandler? _audioHandler;

// Fallback simple player (when audio_service fails)
SimpleAudioPlayer? _simplePlayer;

TheLoopAudioHandler get audioHandler {
  if (_audioHandler == null) {
    throw StateError('AudioHandler not initialized. Call initAudioService() first.');
  }
  return _audioHandler!;
}

SimpleAudioPlayer get simplePlayer {
  _simplePlayer ??= SimpleAudioPlayer();
  return _simplePlayer!;
}

bool get isAudioHandlerInitialized => _audioHandler != null;
bool get isSimplePlayerAvailable => true; // Always available as fallback

Future<void> initAudioService() async {
  _audioHandler = await AudioService.init(
    builder: () => TheLoopAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.theloop.audio',
      androidNotificationChannelName: 'The Loop Music',
      androidNotificationOngoing: false,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      // Use app's purple theme color for notification
      notificationColor: Color(0xFF8B5CF6),
    ),
  );
}

/// Initialize simple player as fallback
void initSimplePlayer() {
  _simplePlayer ??= SimpleAudioPlayer();
  if (kDebugMode) debugPrint('✅ Simple audio player initialized as fallback');
}
