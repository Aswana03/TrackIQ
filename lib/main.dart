import 'package:flutter/material.dart';

import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
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