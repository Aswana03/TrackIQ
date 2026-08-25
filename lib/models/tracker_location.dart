class TrackerLocation {
  final double latitude;
  final double longitude;
  final double speed;
  final DateTime timestamp;
  final bool gpsActive;
  final double battery;
  final bool isOnline;
  final String signalStrength;

  const TrackerLocation({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
    required this.gpsActive,
    required this.battery,
    required this.isOnline,
    required this.signalStrength,
  });
}