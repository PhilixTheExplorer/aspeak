import 'package:aspeak/features/audio/audio_playback_screen.dart';
import 'package:aspeak/features/audio/audio_recorder_screen.dart';
import 'package:aspeak/features/auth/auth_screen.dart';
import 'package:aspeak/features/welcome/welcome_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:aspeak/screens/api_test_screen.dart';
import 'dart:io';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    //errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/audio_playback',
        name: 'audio_playback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AudioPlaybackScreen(
            processedAudioFile: extra['processedAudioFile'] as File,
            originalAudioFile: extra['originalAudioFile'] as File?,
          );
        },
      ),
      GoRoute(
        path: '/audio_recorder',
        name: 'audio_recorder',
        builder: (context, state) => const AudioRecorderScreen(),
      ),
      GoRoute(
        path: '/api_test',
        name: 'api_test',
        builder: (context, state) => const ApiTestScreen(),
      ),
    ],
  );
}