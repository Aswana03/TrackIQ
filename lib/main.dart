import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/trackiq_foreground_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for communication between the UI and foreground task.
  FlutterForegroundTask.initCommunicationPort();

  // Configure the foreground service before runApp().
  TrackIQForegroundService.initialize();

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
