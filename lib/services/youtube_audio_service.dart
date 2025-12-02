import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioService {
  YoutubeExplode? _yt;

  YoutubeExplode get yt {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    if (kDebugMode) debugPrint('Getting audio stream for video: $videoId');

    try {
      // Get stream manifest
      final manifest = await yt.videos.streamsClient.getManifest(videoId);

      // For iOS compatibility, prefer muxed streams (mp4) over audio-only (webm)
      // Muxed streams are mp4 format which iOS handles better
      if (manifest.muxed.isNotEmpty) {
        final muxedStreams = manifest.muxed.sortByBitrate();
        // Use highest quality muxed stream
        final selectedStream = muxedStreams.last;
        if (kDebugMode) debugPrint('Using muxed stream: ${selectedStream.bitrate.kiloBitsPerSecond} kbps');
        return selectedStream.url.toString();
      }

      // Fallback to audio-only if no muxed available
      if (manifest.audioOnly.isNotEmpty) {
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
        return selectedStream.url.toString();
      }

      if (kDebugMode) debugPrint('No streams available for video: $videoId');
      return null;
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
  }
}
