import 'dart:async';

import '../models/tracker_location.dart';

class SimulatedLocationService {
  static const List<_SimulatedPoint>route = [
    _SimulatedPoint(
      latitude: 10.7867,
      longitude: 76.6548,
      speed: 28,
    ),
    _SimulatedPoint(
      latitude: 10.7875,
      longitude: 76.6555,
      speed: 31,
    ),
    _SimulatedPoint(
      latitude: 10.7883,
      longitude: 76.6563,
      speed: 35,
    ),
    _SimulatedPoint(
      latitude: 10.7891,
      longitude: 76.6570,
      speed: 38,
    ),
    _SimulatedPoint(
      latitude: 10.7900,
      longitude: 76.6578,
      speed: 34,
    ),
    _SimulatedPoint(
      latitude: 10.7908,
      longitude: 76.6586,
      speed: 30,
    ),
    _SimulatedPoint(
      latitude: 10.7916,
      longitude: 76.6594,
      speed: 26,
    ),
  ];

  int _currentIndex = 0;

  TrackerLocation get currentLocation {
    final point = route[_currentIndex];

    return TrackerLocation(
      latitude: point.latitude,
      longitude: point.longitude,
      speed: point.speed,
      timestamp: DateTime.now(),
      gpsActive: true,
      battery: 86,
      isOnline: true,
      signalStrength: 'Strong',
    );
  }

  void moveToNextPoint() {
    if (_currentIndex < route.length - 1) {
      _currentIndex++;
    } else {
      _currentIndex = 0;
    }
  }

  void reset() {
    _currentIndex = 0;
  }

  Stream<TrackerLocation> locationStream({
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      yield currentLocation;

      await Future.delayed(interval);

      moveToNextPoint();
    }
  }
}

class _SimulatedPoint {
  final double latitude;
  final double longitude;
  final double speed;

  const _SimulatedPoint({
    required this.latitude,
    required this.longitude,
    required this.speed,
  });
}