import 'package:flutter_test/flutter_test.dart';
import 'package:the_loop/main.dart';
import 'package:the_loop/providers/music_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Create a music provider for testing
    final musicProvider = MusicProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(TheLoopApp(musicProvider: musicProvider));

    // Allow time for splash screen
    await tester.pump(const Duration(seconds: 1));

    // Verify that splash screen or main app is showing
    // The app shows "The Loop" in the splash screen
    expect(find.textContaining('Loop'), findsWidgets);
  });
}
