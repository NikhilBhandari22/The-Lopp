import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImageUrl;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      songs: (json['songs'] as List<dynamic>?)
              ?.map((s) => Song.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      coverImageUrl: json['coverImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songs': songs.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImageUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  int get songCount => songs.length;

  String? get firstSongThumbnail =>
      songs.isNotEmpty ? songs.first.thumbnailUrl : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
