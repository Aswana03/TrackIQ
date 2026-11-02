
import 'package:firebase_database/firebase_database.dart';

import '../models/tracker_location.dart';

class FirebaseLocationService {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref('trackers/trackiq');

  // Update current location from the Flutter app, if needed.
  Future<void> updateLocation(TrackerLocation location) async {
    await _database.update({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'speed': location.speed,
      'timestamp': location.timestamp.toUtc().toIso8601String(),
      'gpsActive': location.gpsActive,
      'battery': location.battery,
      'isOnline': location.isOnline,
      'signalStrength': location.signalStrength,
    });
  }

  // Current live location
  Stream<TrackerLocation?> locationStream() {
    return _database.onValue.map((event) {
      final data = event.snapshot.value;

      if (data is! Map) return null;

      try {
        final timestamp = DateTime.parse(
          data['timestamp'].toString(),
        ).toUtc();

        return TrackerLocation(
          latitude: _asDouble(data['latitude']),
          longitude: _asDouble(data['longitude']),
          speed: _asDouble(data['speed']),
          timestamp: timestamp,
          gpsActive: data['gpsActive'] == true,
          battery: _asDouble(data['battery']),
          isOnline: data['isOnline'] == true,
          signalStrength:
              data['signalStrength']?.toString() ?? 'Unknown',
        );
      } catch (e) {
        print('Error parsing live tracker data: $e');
        return null;
      }
    });
  }

  // Historical tracker locations
  Stream<List<TrackerLocation>> historyStream() {
    final historyRef = _database.child('history');

    return historyRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data is! Map) return <TrackerLocation>[];

      final history = <TrackerLocation>[];

      for (final entry in data.entries) {
        final item = entry.value;

        if (item is! Map) continue;

        try {
          history.add(
            TrackerLocation(
              latitude: _asDouble(item['latitude']),
              longitude: _asDouble(item['longitude']),
              speed: _asDouble(item['speed']),
              timestamp: DateTime.parse(
                item['timestamp'].toString(),
              ).toUtc(),
              gpsActive: item['gpsActive'] == true,
              battery: _asDouble(item['battery']),
              isOnline: item['isOnline'] == true,
              signalStrength:
                  item['signalStrength']?.toString() ?? 'Unknown',
            ),
          );
        } catch (e) {
          print('Skipping malformed history entry: $e');
        }
      }

      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    });
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
