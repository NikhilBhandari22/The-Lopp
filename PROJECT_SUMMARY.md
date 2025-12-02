# The Loop - Music Streaming App

A beautiful music streaming app built with Flutter that streams music from YouTube with background playback support.

## Developer
**Created by Nikhil K**

## Features

### Core Features
- **YouTube Integration** - Search and play any music from YouTube
- **Background Playback** - Music continues playing when screen is locked or app is in background
- **Bluetooth Support** - Audio automatically routes to connected Bluetooth earphones/headphones with media control support
- **Offline Caching** - API responses are cached to reduce YouTube API quota usage
- **Dynamic API Keys via Firebase** - API keys managed through Firebase Remote Config for easy updates without app rebuild
- **API Key Rotation** - Automatic rotation between multiple YouTube API keys when quota is exceeded

### Music Player
- Full-screen player with album art, progress slider, and playback controls
- **Auto-open Now Playing** - Full player opens automatically when a song is selected
- **Loading indicator on album art** - Shows loading state while song is buffering
- Mini player bar for quick access while browsing
- Play/Pause, Next, Previous controls
- Shuffle mode - shuffles queue while keeping current song, restores original order when disabled
- Repeat modes - Off, Repeat All, Repeat One
- Seek functionality with progress slider

### Library Management
- **Playlists** - Create, rename, and delete custom playlists
- **Add to Playlist** - Add songs from search results or full-screen player
- **Favorites** - Like songs to save them to your favorites
- **Recently Played** - Automatic history of played songs (up to 50)

### Home Screen
- Greeting based on time of day
- Quick access cards for Liked Songs and Recently Played
- **Hindi Songs** section - Latest Hindi music
- **Hindi Rap** section - Hindi rap music
- **Trending Now** section - Currently trending music
- Recently Played horizontal scroll (if any history exists)

### Search
- Real-time YouTube music search
- Popular search suggestions
- Browse by category (Pop, Rock, Hip Hop, Electronic, Jazz, Classical)
- Add songs directly to playlists from search results

### Navigation
- Bottom navigation with Home, Search, and Library tabs
- Quick action cards navigate directly to Library sub-tabs (Favorites, Recent)

## Technical Implementation

### Packages Used
```yaml
dependencies:
  # Networking
  http: ^1.2.0

  # YouTube Integration
  youtube_player_flutter: ^9.1.1
  youtube_explode_dart: ^2.2.1

  # Background Audio
  audio_service: ^0.18.15
  just_audio: ^0.9.40

  # State Management
  provider: ^6.1.2

  # Local Storage
  shared_preferences: ^2.2.2

  # Firebase (Remote Config for dynamic API keys)
  firebase_core: ^3.8.1
  firebase_remote_config: ^5.2.1

  # UI
  google_fonts: ^6.2.1
  flutter_screenutil: ^5.9.3

  # Animations
  dotlottie_loader: ^0.0.4
  lottie: ^3.1.0

  # Utilities
  uuid: ^4.5.1

dev_dependencies:
  flutter_launcher_icons: ^0.14.3
```

### Architecture
- **Provider** for state management
- **Services** layer for YouTube API, audio handling, storage, and Firebase
- **Models** for Song and Playlist data structures
- **Widgets** for reusable UI components

### Key Files
```
lib/
├── main.dart                          # App entry point with Firebase init
├── core/
│   ├── theme/
│   │   └── app_colors.dart            # App color scheme and gradients
│   └── utils/
│       └── logger.dart                # Production-safe logging utility
├── models/
│   ├── song.dart                      # Song model with JSON serialization
│   └── playlist.dart                  # Playlist model
├── providers/
│   └── music_provider.dart            # Main state management
├── services/
│   ├── youtube_service.dart           # YouTube Data API integration with key rotation
│   ├── youtube_audio_service.dart     # Audio stream extraction
│   ├── audio_handler.dart             # Background audio service
│   ├── storage_service.dart           # Local storage (SharedPreferences)
│   ├── cache_service.dart             # API response caching
│   ├── api_keys.dart                  # API configuration & key rotation manager
│   └── remote_config_service.dart     # Firebase Remote Config for dynamic API keys
├── screens/
│   ├── home_page.dart                 # Main screen with navigation
│   ├── search_screen.dart             # Search functionality
│   ├── library_screen.dart            # Playlists, Favorites, Recent
│   ├── playlist_detail_screen.dart    # Individual playlist view
│   └── full_screen_player_modal.dart  # Full-screen music player with loading state
└── widgets/
    ├── song_card.dart                 # Song list item & compact card
    ├── playlist_card.dart             # Playlist list item
    └── mini_player_bar.dart           # Bottom mini player
```

### Audio Streaming
- Uses `youtube_explode_dart` to extract audio stream URLs from YouTube videos
- Prefers MP4/AAC muxed streams for iOS compatibility
- Falls back to audio-only streams if muxed unavailable
- Custom User-Agent headers for reliable streaming

### Background Audio
- `audio_service` for system media integration
- Lock screen controls (play/pause, next, previous)
- Notification media controls
- Bluetooth headphone button support
- Continues playback when app is backgrounded

### Caching Strategy
- Search results cached for 24 hours
- Trending songs cached for 6 hours
- Video details cached for 7 days
- Significantly reduces YouTube API quota usage

### Firebase Remote Config - Dynamic API Keys
The app uses Firebase Remote Config to manage YouTube API keys dynamically:

**Benefits:**
- **No App Rebuild** - Add/remove API keys without publishing a new version
- **Instant Updates** - New keys available to users within 1 hour
- **Unlimited Keys** - Add as many API keys as needed
- **Secure** - Keys not embedded in APK/IPA

**How It Works:**
```
App Startup
    │
    ▼
Firebase Remote Config fetches "youtube_api_keys"
    │
    ▼
Keys split from "key1,key2,key3" → [key1, key2, key3]
    │
    ▼
Cached locally (refreshes every 1 hour)
    │
    ▼
Same rotation logic as before
```

**Firebase Console Setup:**
1. Go to Firebase Console → Remote Config
2. Add parameter: `youtube_api_keys`
3. Value: Comma-separated API keys (e.g., `AIzaSy...key1,AIzaSy...key2`)
4. Publish changes

### API Key Rotation System
The app supports multiple YouTube API keys with automatic rotation:

- **Multiple Keys** - Unlimited API keys via Firebase Remote Config
- **Auto-Detection** - Detects quota exceeded errors (HTTP 403)
- **Seamless Rotation** - Automatically switches to the next available key
- **Auto-Refresh** - When all keys exhausted, tries to fetch new keys from Firebase
- **Status Tracking** - Tracks which keys are exhausted
- **Auto-Reset** - Resets exhausted keys when all are used (quota resets at midnight PT)

**Rotation Flow:**
```
key1 ──(quota exceeded)──► key2 ──(quota exceeded)──► key3
                                                        │
key3 ──(quota exceeded)──► Refresh from Firebase ───────┘
                                │
                                └──► New keys available? Use them!
                                     No new keys? Show error
```

### User Experience Enhancements
- **Auto-open Full Player** - When a song is selected, the full-screen player opens automatically
- **Loading State Feedback** - Album art shows loading indicator while song is buffering
- **Slider Safety** - Progress slider values are clamped to prevent assertion errors

## App Branding

### Logo
- Custom "The Loop" logo with infinity loop design
- Purple/cyan gradient on black background
- Used in app bar, about dialog, and launcher icon

### Color Scheme
- **Background**: #0D1117 (dark)
- **Surface**: #161B22
- **Accent**: #8B5CF6 (purple)
- **Primary Gradient**: Purple to Cyan

### Launcher Icon
- Generated using `flutter_launcher_icons`
- Adaptive icon for Android with black background
- Standard icon for iOS

## Setup Instructions

### Development Setup
1. Clone the repository
2. Run `flutter pub get`
3. Setup Firebase:
   - Create a Firebase project at https://console.firebase.google.com
   - Add Android app with package name `com.theloop.the_loop`
   - Download `google-services.json` to `android/app/`
   - Go to Remote Config and add `youtube_api_keys` parameter
4. Run `flutter run`

### Adding API Keys (Firebase Remote Config)
1. Go to Firebase Console → Remote Config
2. Edit `youtube_api_keys` parameter
3. Set value as comma-separated keys:
   ```
   AIzaSyXXX...key1,AIzaSyYYY...key2,AIzaSyZZZ...key3
   ```
4. Click **Publish changes**
5. App gets new keys within 1 hour (or on next launch)

### Production Build
See `BUILD.md` for complete production build instructions.

## Production Configuration

### Security Features
- API keys loaded dynamically from Firebase Remote Config
- ProGuard/R8 code shrinking and obfuscation enabled
- Network security config for media streaming
- Debug logging disabled in release builds (uses `kDebugMode` checks)
- Release signing configuration ready

### Android Configuration
- Firebase integration with `google-services.json`
- Signing configuration in `android/app/build.gradle.kts`
- ProGuard rules in `android/app/proguard-rules.pro`
- Network security config in `android/app/src/main/res/xml/`
- Minimum SDK 23 (required for Firebase)

### iOS Configuration
- App Transport Security configured for media streaming
- Portrait-only orientation for phones
- Background audio mode enabled

### Firebase Project Info
- **Project Name**: The Loop
- **Project ID**: the-loop-9db9d
- **Android Package**: com.theloop.the_loop

## Recent Updates

### Firebase Remote Config Integration (Latest)
- Dynamic API key management via Firebase Remote Config
- Add/remove API keys without app rebuild
- Automatic key refresh when all keys exhausted
- Keys cached locally with 1-hour refresh interval

### Production Ready
- Secured API keys via Firebase (not hardcoded)
- Added Android release signing configuration
- Added ProGuard rules for code optimization
- Configured network security for media streaming
- Debug logging only in debug builds
- Created comprehensive build documentation

### API Key Rotation
- Support for unlimited YouTube API keys
- Automatic rotation when quota is exceeded
- Seamless user experience - no interruption during key switch
- Auto-refresh from Firebase when all keys exhausted

### Full Player Auto-Open
- Player opens automatically when selecting a song
- Loading indicator displayed on album art during buffering
- Fixed slider assertion error when position exceeds duration

## Version
**1.0.0**

---
Built with Flutter by Nikhil K
