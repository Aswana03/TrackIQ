import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
// import 'services/tracker_sync_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // final trackerSyncService = TrackerSyncService();
  // trackerSyncService.start();

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