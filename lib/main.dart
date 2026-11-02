
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('TRACKIQ: Starting application');

  try {
    debugPrint('TRACKIQ: Firebase apps before init: ${Firebase.apps.length}');

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('TRACKIQ: Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('TRACKIQ: Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  debugPrint('TRACKIQ: Launching app');
  runApp(const TrackIQApp());
}

class TrackIQApp extends StatelessWidget {
  const TrackIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackIQ',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
