
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final TrackerRepository _trackerRepository =
      TrackerRepository();

  StreamSubscription<TrackerLocation?>? _locationSubscription;

  Timer? _statusTimer;

  GoogleMapController? _mapController;

  TrackerLocation? _trackerData;

  bool _hasCenteredOnTracker = false;

  Set<Marker> _markers = {};

  final DatabaseReference _geofenceRef =
      FirebaseDatabase.instance.ref('trackers/trackiq/geofence');

  LatLng? _geofenceCenter;
  double _geofenceRadius = 10;
  bool _isSelectingGeofence = false;
  bool? _wasInsideGeofence;

  Set<Circle> get _geofenceCircles {
    final center = _geofenceCenter;
    if (center == null) return {};

    return {
      Circle(
        circleId: const CircleId('tracker_geofence'),
        center: center,
        radius: _geofenceRadius,
        fillColor: AppColors.primary.withValues(alpha: 0.12),
        strokeColor: AppColors.primary,
        strokeWidth: 2,
      ),
    };
  }

  static const LatLng _defaultLocation =
      LatLng(10.7867, 76.6548);

  @override
  void initState() {
    super.initState();

    _loadGeofence();
    _listenToTracker();

    // Refresh online/offline status every second.
    _statusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ----------------------------------------------------------
  // LIVE TRACKER LOCATION
  // ----------------------------------------------------------

  void _listenToTracker() {
    _locationSubscription =
        _trackerRepository.locationStream.listen(
      (location) {
        if (!mounted || location == null) {
          return;
        }

        // Ignore invalid GPS coordinates.
        if (location.latitude < -90 ||
            location.latitude > 90 ||
            location.longitude < -180 ||
            location.longitude > 180) {
          return;
        }

        // Check the geofence only when the GPS reports a valid fix.
        if (location.gpsActive && _geofenceCenter != null) {
          _checkGeofence(location);
        }

        // Update the tracker marker.
        setState(() {
          _trackerData = location;

          _markers = {
            Marker(
              markerId: const MarkerId('tracker_01'),
              position: LatLng(
                location.latitude,
                location.longitude,
              ),
              infoWindow: InfoWindow(
                title: 'Tracker 01',
                snippet:
                    '${location.speed.toStringAsFixed(0)} km/h',
              ),
            ),
          };
        });

        // Follow the latest tracker position.
        _updateMapPosition(location);
      },
    );
  }

  // ----------------------------------------------------------
  // MOVE MAP TO TRACKER
  // ----------------------------------------------------------

  Future<void> _updateMapPosition(
    TrackerLocation location,
  ) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final position = LatLng(
      location.latitude,
      location.longitude,
    );

    if (!_hasCenteredOnTracker) {
      _hasCenteredOnTracker = true;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 17,
          ),
        ),
      );

      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  // ----------------------------------------------------------
  // RECENTER BUTTON
  // ----------------------------------------------------------

  Future<void> _recenterMap() async {
    final controller = _mapController;
    final trackerData = _trackerData;

    if (controller == null || trackerData == null) {
      return;
    }

    final position = LatLng(
      trackerData.latitude,
      trackerData.longitude,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 17,
        ),
      ),
    );
  }


  // ----------------------------------------------------------
  // GEOFENCE
  // ----------------------------------------------------------

  Future<void> _loadGeofence() async {
    try {
      final snapshot = await _geofenceRef.get();
      if (!mounted || !snapshot.exists || snapshot.value == null) return;

      final value = Map<String, dynamic>.from(
        snapshot.value as Map,
      );

      final latitude = (value['latitude'] as num?)?.toDouble();
      final longitude = (value['longitude'] as num?)?.toDouble();
      final radius = (value['radius'] as num?)?.toDouble();

      if (latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return;
      }

      setState(() {
        _geofenceCenter = LatLng(latitude, longitude);
        _geofenceRadius = (radius ?? 10).clamp(10, 5000).toDouble();
      });

      final tracker = _trackerData;
      if (tracker != null && tracker.gpsActive) {
        _checkGeofence(tracker);
      }
    } catch (error) {
      debugPrint('Could not load geofence: $error');
    }
  }

  Future<void> _saveGeofence() async {
    final center = _geofenceCenter;
    if (center == null) return;

    try {
      await _geofenceRef.set({
        'latitude': center.latitude,
        'longitude': center.longitude,
        'radius': _geofenceRadius,
        'updatedAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safe zone saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save safe zone: $error')),
      );
    }
  }

  void _checkGeofence(TrackerLocation location) {
    final center = _geofenceCenter;
    if (center == null) return;

    final distance = _distanceInMeters(
      location.latitude,
      location.longitude,
      center.latitude,
      center.longitude,
    );

    final isInside = distance <= _geofenceRadius;
    final previousState = _wasInsideGeofence;
    _wasInsideGeofence = isInside;

    // Establish the initial state without showing a false entry/exit alert.
    if (previousState == null || previousState == isInside || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = isInside
          ? 'Tracker 01 has re-entered the safe zone.'
          : 'Alert: Tracker 01 has left the safe zone!';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isInside ? AppColors.success : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
    });
  }

  double _distanceInMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;
    final lat1 = latitude1 * math.pi / 180;
    final lat2 = latitude2 * math.pi / 180;
    final deltaLat = (latitude2 - latitude1) * math.pi / 180;
    final deltaLon = (longitude2 - longitude1) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _showGeofenceSettings() async {
    double selectedRadius = _geofenceRadius;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safe Zone Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _geofenceCenter == null
                          ? 'Choose a centre point on the map.'
                          : 'Centre: ${_geofenceCenter!.latitude.toStringAsFixed(5)}, '
                              '${_geofenceCenter!.longitude.toStringAsFixed(5)}',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() => _isSelectingGeofence = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tap the map to choose the safe zone centre.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Choose centre on map'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Radius: ${selectedRadius.round()} m',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: selectedRadius,
                      min: 10,
                      max: 5000,
                      divisions: 499,
                      label: '${selectedRadius.round()} m',
                      onChanged: (value) {
                        setSheetState(() => selectedRadius = value);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancel'),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            setState(() {
                              _geofenceRadius = selectedRadius;
                            });
                            Navigator.pop(sheetContext);
                            if (_geofenceCenter == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Choose a centre point before saving.'),
                                  ),
                                );
                              }
                              return;
                            }
                            await _saveGeofence();
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save safe zone'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectGeofenceCenter(LatLng position) async {
    setState(() {
      _geofenceCenter = position;
      _isSelectingGeofence = false;
      _wasInsideGeofence = null;
    });

    await _saveGeofence();
  }

  Set<Marker> get _mapMarkers {
    final center = _geofenceCenter;
    return {
      ..._markers,
      if (center != null)
        Marker(
          markerId: const MarkerId('geofence_center'),
          position: center,
          infoWindow: const InfoWindow(
            title: 'Safe Zone Centre',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
    };
  }

  // ----------------------------------------------------------
  // ONLINE / OFFLINE
  // ----------------------------------------------------------

  bool get _trackerOnline {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return false;
    }

    final now = DateTime.now().toUtc();

    final lastUpdate = trackerData.timestamp.toUtc();

    final age = now.difference(lastUpdate);

    if (age.isNegative) {
      return false;
    }

    return age <= const Duration(seconds: 15);
  }

  // ----------------------------------------------------------
  // SPEED
  // ----------------------------------------------------------

  String get _speedText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return '-- km/h';
    }

    return '${trackerData.speed.toStringAsFixed(0)} km/h';
  }

  // ----------------------------------------------------------
  // GPS STATUS
  // ----------------------------------------------------------

  String get _gpsText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return 'GPS signal: Waiting';
    }

    return trackerData.gpsActive
        ? 'GPS signal: Strong'
        : 'GPS signal: No Fix';
  }

  // ----------------------------------------------------------
  // COORDINATES
  // ----------------------------------------------------------

  String get _locationText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return 'Waiting for GPS location...';
    }

    return '${trackerData.latitude.toStringAsFixed(6)}, '
        '${trackerData.longitude.toStringAsFixed(6)}';
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusTimer?.cancel();

    _mapController?.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool trackerOnline = _trackerOnline;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Live Map',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Geofence settings',
            onPressed: _showGeofenceSettings,
            icon: const Icon(Icons.radar_rounded),
          ),
          IconButton(
            onPressed: _recenterMap,
            icon: const Icon(
              Icons.my_location_rounded,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),

            onMapCreated: (controller) {
              _mapController = controller;

              final trackerData = _trackerData;

              if (trackerData != null) {
                _updateMapPosition(trackerData);
              }
            },

            // Current tracker marker and circular geofence.
            markers: _mapMarkers,
            circles: _geofenceCircles,
            onTap: (position) {
              if (_isSelectingGeofence) {
                _selectGeofenceCenter(position);
              }
            },

            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),

          // COORDINATES
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: trackerOnline
                        ? AppColors.success
                        : AppColors.textMuted,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _locationText,
                      style: AppTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSelectingGeofence)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap anywhere on the map to set the safe zone centre.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          if (_geofenceCenter != null && !_isSelectingGeofence)
            Positioned(
              top: 76,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  'Safe zone: ${_geofenceRadius.round()} m',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // TRACKER INFORMATION CARD
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),

              child: Row(
                children: [
                  // GPS ICON
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TRACKER DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tracker 01',
                          style: AppTextStyles.title,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _gpsText,
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),

                  // SPEED + ONLINE STATUS
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        _speedText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: trackerOnline
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            trackerOnline
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: trackerOnline
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
