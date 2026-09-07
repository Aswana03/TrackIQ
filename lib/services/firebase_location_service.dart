import 'package:firebase_database/firebase_database.dart';

import '../models/tracker_location.dart';

class FirebaseLocationService {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref('trackers/trackiq');

  Future<void> updateLocation(TrackerLocation location) async {
    await _database.set({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speed': location.speed,
      'timestamp': location.timestamp.toIso8601String(),
      'gpsActive': location.gpsActive,
      'battery': location.battery,
      'isOnline': location.isOnline,
      'signalStrength': location.signalStrength,
    });
  }

  Stream<TrackerLocation?> locationStream() {
    return _database.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        return null;
      }

      return TrackerLocation(
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        speed: (data['speed'] as num).toDouble(),
        timestamp: DateTime.parse(data['timestamp'] as String),
        gpsActive: data['gpsActive'] as bool,
        battery: (data['battery'] as num).toDouble(),
        isOnline: data['isOnline'] as bool,
        signalStrength: data['signalStrength'] as String,
      );
    });
  }
}