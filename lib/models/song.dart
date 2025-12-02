class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String videoId;
  final String duration;
  final String channelTitle;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.videoId,
    this.duration = '',
    this.channelTitle = '',
  });

  /// Decode HTML entities in a string
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoId: json['videoId'] ?? '',
      duration: json['duration'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'duration': duration,
      'channelTitle': channelTitle,
    };
  }

  factory Song.fromYouTubeApi(Map<String, dynamic> item) {
    final snippet = item['snippet'] ?? {};
    final id = item['id'];
    final videoId = id is String ? id : (id['videoId'] ?? '');
    final thumbnails = snippet['thumbnails'] ?? {};
    final highThumbnail = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};

    // Decode HTML entities from YouTube API response
    final rawTitle = snippet['title'] ?? 'Unknown Title';
    final rawArtist = snippet['channelTitle'] ?? 'Unknown Artist';

    return Song(
      id: videoId,
      title: _decodeHtmlEntities(rawTitle),
      artist: _decodeHtmlEntities(rawArtist),
      thumbnailUrl: highThumbnail['url'] ?? '',
      videoId: videoId,
      channelTitle: _decodeHtmlEntities(rawArtist),
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? videoId,
    String? duration,
    String? channelTitle,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoId: videoId ?? this.videoId,
      duration: duration ?? this.duration,
      channelTitle: channelTitle ?? this.channelTitle,
    );
  }

  // Cache serialization methods
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'duration': duration,
      'channelTitle': channelTitle,
    };
  }

  factory Song.fromCacheMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      videoId: map['videoId'] ?? '',
      duration: map['duration'] ?? '',
      channelTitle: map['channelTitle'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
