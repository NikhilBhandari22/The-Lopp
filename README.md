# The Loop

A music streaming app built with Flutter that allows users to search, play, and organize their favorite music.

## Features

- **Unlimited Music Streaming** - Stream millions of songs from YouTube
- **Powerful Search** - Find any song, artist, or album instantly
- **Create Playlists** - Build and organize your music collections
- **Favorites** - Mark songs as favorites for quick access
- **Recently Played** - Automatic listening history
- **Background Playback** - Keep music playing while using other apps
- **Queue Management** - Control what plays next
- **Dark Theme** - Modern, eye-friendly interface
- **Dynamic Gradient Player** - Full-screen player with colors from album art

## Tech Stack

- **Flutter** - Cross-platform framework
- **Firebase Remote Config** - Secure API key management
- **YouTube Explode Dart** - YouTube audio streaming
- **Just Audio** - Audio playback with background support
- **Audio Service** - Background audio and media notifications
- **Palette Generator** - Dynamic color extraction from album art
- **Shared Preferences** - Local data persistence

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Firebase account
- YouTube Data API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/NikhilBhandari22/The-Lopp.git
cd the_loop
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a Firebase project
   - Add Android app with package name `com.theloop.the_loop`
   - Add iOS app with bundle ID `com.theloop.theLoop`
   - Download and add `google-services.json` to `android/app/`
   - Download and add `GoogleService-Info.plist` to `ios/Runner/`

4. Configure Firebase Remote Config:
   - Add parameter `youtube_api_key` with your YouTube Data API key

5. Set up signing for release builds:
   - Copy `android/key.properties.example` to `android/key.properties`
   - Update with your keystore details

6. Run the app:
```bash
flutter run
```

## Building for Release

### Android
```bash
flutter build appbundle --release
```
The AAB file will be at `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── song.dart            # Song data model
├── providers/
│   └── music_provider.dart  # State management
├── screens/
│   ├── home_screen.dart     # Main screen with tabs
│   ├── search_screen.dart   # Song search
│   ├── playlist_screen.dart # Playlist management
│   └── full_screen_player_modal.dart  # Full-screen player
├── services/
│   ├── youtube_service.dart       # YouTube API search
│   ├── youtube_audio_service.dart # Audio URL fetching with caching
│   └── audio_handler.dart         # Background audio handler
├── widgets/
│   └── mini_player.dart     # Bottom mini player
└── utils/
    └── logger.dart          # Logging utility
```

## Audio URL Caching

The app implements intelligent audio URL caching for faster playback:
- URLs are cached in memory with 5-hour expiration (YouTube URLs expire after ~6 hours)
- Next song is pre-fetched while current song plays
- Recently played songs are pre-fetched on app startup

## Privacy Policy

Privacy policy is hosted at: https://the-loop-9db9d.web.app/privacy-policy.html

## Play Store Listing

**Short Description:**
Stream music endlessly. Create playlists and discover songs you love.

**Category:** Music & Audio

**Contact:** theloopapp.contact@gmail.com

## AdMob Integration (Optional)

See [ADS_SETUP.md](ADS_SETUP.md) for instructions on adding ads to the app.

## License

This project is for educational purposes.

## Contact

- Email: theloopapp.contact@gmail.com
- GitHub: https://github.com/NikhilBhandari22/The-Lopp
