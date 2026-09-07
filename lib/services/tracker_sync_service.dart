import 'dart:async';

import 'firebase_location_service.dart';
import 'simulated_location_service.dart';

class TrackerSyncService {
  final SimulatedLocationService _simulatedLocationService =
      SimulatedLocationService();

  final FirebaseLocationService _firebaseLocationService =
      FirebaseLocationService();

  StreamSubscription? _subscription;

  void start() {
    _subscription ??= _simulatedLocationService
        .locationStream()
        .listen((location) async {
      try {
        await _firebaseLocationService.updateLocation(location);
      } catch (e) {
        print('Firebase update failed: $e');
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}