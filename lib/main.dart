import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'providers/music_provider.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';
import 'services/remote_config_service.dart';
import 'services/api_keys.dart';

// Global key to access MusicProvider for audio handler setup
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
MusicProvider? _musicProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Create music provider
  _musicProvider = MusicProvider();

  runApp(TheLoopApp(musicProvider: _musicProvider!));
}

class TheLoopApp extends StatefulWidget {
  final MusicProvider musicProvider;

  const TheLoopApp({super.key, required this.musicProvider});

  @override
  State<TheLoopApp> createState() => _TheLoopAppState();
}

class _TheLoopAppState extends State<TheLoopApp> {
  bool _showSplash = true;
  bool _isInitialized = false;
  bool _splashAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to not block the UI thread
    Future.microtask(() => _initializeApp());
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      AppLogger.success('Firebase initialized', tag: 'Init');

      // Initialize Remote Config and load API keys
      final remoteConfig = RemoteConfigService();
      await remoteConfig.init();
      ApiKeys.loadFromRemoteConfig();
      AppLogger.success('API keys loaded from Firebase', tag: 'Init');
    } catch (e) {
      AppLogger.error('Firebase initialization error', tag: 'Init', error: e);
    }

    // Initialize audio service in isolate-friendly way
    try {
      await initAudioService();
      AppLogger.success('Audio service initialized', tag: 'Init');
    } catch (e) {
      AppLogger.error(
        'Audio service initialization error',
        tag: 'Init',
        error: e,
      );
      // Initialize fallback player
      initSimplePlayer();
    }

    // Initialize the music provider (this will set up audio handler or fallback)
    await widget.musicProvider.init();

    // Load songs in background - don't wait
    widget.musicProvider.loadAllSongsBackground();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    // If splash animation is already complete, navigate immediately
    _checkAndNavigate();
  }

  void _onSplashAnimationComplete() {
    _splashAnimationComplete = true;
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    // Only navigate when both initialization is complete AND splash animation is done
    if (_isInitialized && _splashAnimationComplete && _showSplash) {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.musicProvider,
      child: MaterialApp(
        title: 'The Loop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: _showSplash
            ? SplashScreen(onComplete: _onSplashAnimationComplete)
            : const HomePage(),
      ),
    );
  }
}
