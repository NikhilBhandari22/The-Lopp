import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class StorageService {
  static const String _playlistsKey = 'playlists';
  static const String _recentlyPlayedKey = 'recently_played';
  static const String _favoritesKey = 'favorites';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Playlists
  Future<List<Playlist>> getPlaylists() async {
    final String? data = _prefs.getString(_playlistsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final String data = json.encode(playlists.map((p) => p.toJson()).toList());
    await _prefs.setString(_playlistsKey, data);
  }

  Future<void> addPlaylist(Playlist playlist) async {
    final playlists = await getPlaylists();
    playlists.add(playlist);
    await savePlaylists(playlists);
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlist;
      await savePlaylists(playlists);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await savePlaylists(playlists);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = playlists[index];
      if (!playlist.songs.contains(song)) {
        final updatedSongs = [...playlist.songs, song];
        playlists[index] = playlist.copyWith(
          songs: updatedSongs,
          updatedAt: DateTime.now(),
        );
        await savePlaylists(playlists);
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = playlists[index];
      final updatedSongs = playlist.songs.where((s) => s.id != songId).toList();
      playlists[index] = playlist.copyWith(
        songs: updatedSongs,
        updatedAt: DateTime.now(),
      );
      await savePlaylists(playlists);
    }
  }

  // Recently Played
  Future<List<Song>> getRecentlyPlayed() async {
    final String? data = _prefs.getString(_recentlyPlayedKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map((item) => Song.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToRecentlyPlayed(Song song) async {
    final List<Song> recentlyPlayed = await getRecentlyPlayed();

    // Remove if already exists
    recentlyPlayed.removeWhere((s) => s.id == song.id);

    // Add to beginning
    recentlyPlayed.insert(0, song);

    // Keep only last 50 songs
    final trimmedList = recentlyPlayed.take(50).toList();

    final String data = json.encode(trimmedList.map((s) => s.toJson()).toList());
    await _prefs.setString(_recentlyPlayedKey, data);
  }

  // Favorites
  Future<List<Song>> getFavorites() async {
    final String? data = _prefs.getString(_favoritesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map((item) => Song.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleFavorite(Song song) async {
    final List<Song> favorites = await getFavorites();
    final exists = favorites.any((s) => s.id == song.id);

    if (exists) {
      favorites.removeWhere((s) => s.id == song.id);
    } else {
      favorites.add(song);
    }

    final String data = json.encode(favorites.map((s) => s.toJson()).toList());
    await _prefs.setString(_favoritesKey, data);
  }

  Future<bool> isFavorite(String songId) async {
    final favorites = await getFavorites();
    return favorites.any((s) => s.id == songId);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.remove(_playlistsKey);
    await _prefs.remove(_recentlyPlayedKey);
    await _prefs.remove(_favoritesKey);
  }
}
