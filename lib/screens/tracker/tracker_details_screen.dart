import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../route_history/route_history_screen.dart';

class TrackerDetailsScreen extends StatefulWidget {
  const TrackerDetailsScreen({super.key});

  @override
  State<TrackerDetailsScreen> createState() =>
      _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState
    extends State<TrackerDetailsScreen> {
  GoogleMapController? _mapController;

  final TrackerRepository _trackerRepository =
      TrackerRepository();

  TrackerLocation? _trackerData;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final List<LatLng> _routePoints = [];

  StreamSubscription<TrackerLocation?>?
      _locationSubscription;

  Timer? _onlineStatusTimer;

  // ------------------------------------------------------------
  // REAL ONLINE / OFFLINE DETECTION
  // ------------------------------------------------------------

 bool get _isTrackerOnline {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final lastUpdate = trackerData.timestamp.toUtc();

    final difference = now.difference(lastUpdate);

    return difference.inSeconds <= 15;
  }

  @override
  void initState() {
    super.initState();

    _listenToFirebaseLocation();

    // Check online/offline status every second.
    //
    // This is important because when the ESP32 is powered OFF,
    // Firebase does not automatically send a new event.
    // The timer allows the UI to notice that the last update
    // has become older than 15 seconds.
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ------------------------------------------------------------
  // FIREBASE LOCATION LISTENER
  // ------------------------------------------------------------

  void _listenToFirebaseLocation() {
    _locationSubscription =
        _trackerRepository.locationStream.listen(
      (location) {
        if (!mounted || location == null) {
          return;
        }

        final newPosition = LatLng(
          location.latitude,
          location.longitude,
        );

        setState(() {
          _trackerData = location;

          // Add new Firebase location to route.
          _routePoints.add(newPosition);

          // Update tracker marker.
          _markers = {
            Marker(
              markerId:
                  const MarkerId('tracker_01'),
              position: newPosition,
              infoWindow: InfoWindow(
                title: 'Tracker 01',
                snippet:
                    '${location.speed.toStringAsFixed(0)} km/h',
              ),
            ),
          };

          // Update route polyline.
          _polylines = {
            Polyline(
              polylineId:
                  const PolylineId('tracker_route'),
              points:
                  List<LatLng>.from(_routePoints),
              width: 5,
              color: AppColors.primary,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          };
        });

        // Follow tracker with camera.
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // LAST UPDATED TEXT
  // ------------------------------------------------------------

  String get _lastUpdatedText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return 'Waiting for tracker data...';
    }

    final difference =
        DateTime.now().difference(
      trackerData.timestamp,
    );

    if (difference.inSeconds < 5) {
      return 'Last updated just now';
    }

    if (difference.inMinutes < 1) {
      return 'Last updated '
          '${difference.inSeconds} seconds ago';
    }

    return 'Last updated '
        '${difference.inMinutes} minutes ago';
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _onlineStatusTimer?.cancel();
    _mapController?.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final trackerData = _trackerData;

    // Wait until Firebase sends the first location.
    if (trackerData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Tracker Details',
            style: AppTextStyles.title,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final trackerPosition = LatLng(
      trackerData.latitude,
      trackerData.longitude,
    );

    // IMPORTANT:
    // Do NOT use trackerData.isOnline here.
    //
    // The ESP32 currently sends isOnline = true,
    // and Firebase keeps the last value even after
    // the ESP32 is powered OFF.
    //
    // Instead, calculate the status from the timestamp.
    final bool trackerOnline = _isTrackerOnline;

    final bool gpsActive =
        trackerData.gpsActive;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Tracker Details',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // --------------------------------------------------
            // TRACKER HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),

              child: Column(
                children: [

                  Container(
                    width: 70,
                    height: 70,

                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: const Icon(
                      Icons.devices_other_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Tracker 01',
                    style: AppTextStyles.heading,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'ESP32 + Neo-6M',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Container(
                        width: 8,
                        height: 8,

                        decoration:
                            BoxDecoration(
                          color: trackerOnline
                              ? AppColors.success
                              : AppColors.alert,
                          shape:
                              BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        trackerOnline
                            ? 'Online'
                            : 'Offline',

                        style: trackerOnline
                            ? AppTextStyles
                                .statusOnline
                            : TextStyle(
                                color:
                                    AppColors.alert,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // DEVICE STATUS
            // --------------------------------------------------

            const Text(
              'Device status',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatusCard(
                    icon: Icons
                        .signal_cellular_alt_rounded,
                    title: 'Signal',
                    value:
                        trackerData.signalStrength,
                    valueColor:
                        AppColors.success,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatusCard(
                    icon: Icons
                        .battery_6_bar_rounded,
                    title: 'Battery',
                    value:
                        '${trackerData.battery.toStringAsFixed(0)}%',
                    valueColor:
                        trackerData.battery > 20
                            ? AppColors.success
                            : AppColors.alert,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatusCard(
                    icon: Icons.speed_rounded,
                    title: 'Speed',
                    value:
                        '${trackerData.speed.toStringAsFixed(0)} km/h',
                    valueColor:
                        AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatusCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'GPS',
                    value: gpsActive
                        ? 'Active'
                        : 'Inactive',
                    valueColor: gpsActive
                        ? AppColors.success
                        : AppColors.alert,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // ASSET LOCATION
            // --------------------------------------------------

            const Text(
              'Asset location',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 280,

              clipBehavior: Clip.antiAlias,

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),

              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(
                  target: trackerPosition,
                  zoom: 15,
                ),

                markers: _markers,

                polylines: _polylines,

                myLocationButtonEnabled:
                    false,

                zoomControlsEnabled: true,

                mapToolbarEnabled: false,

                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // LOCATION INFORMATION
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Inside home zone',
                          style:
                              AppTextStyles.body,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _lastUpdatedText,
                          style:
                              AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // DEVICE INFORMATION
            // --------------------------------------------------

            const Text(
              'Device information',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            const _InfoRow(
              label: 'Device type',
              value: 'ESP32 Tracker',
            ),

            const _InfoRow(
              label: 'GPS module',
              value: 'Neo-6M',
            ),

            _InfoRow(
              label: 'Latitude',
              value:
                  trackerData.latitude
                      .toStringAsFixed(6),
            ),

            _InfoRow(
              label: 'Longitude',
              value:
                  trackerData.longitude
                      .toStringAsFixed(6),
            ),

            _InfoRow(
              label: 'Status',
              value: trackerOnline
                  ? 'Connected'
                  : 'Offline',
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // ROUTE HISTORY
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RouteHistoryScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.history_rounded,
                ),

                label: const Text(
                  'View route history',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppColors.primary,

                  side: const BorderSide(
                    color: AppColors.primary,
                  ),

                  minimumSize:
                      const Size(
                    double.infinity,
                    52,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DEVICE STATUS CARD
// ============================================================

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: AppTextStyles.small,
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DEVICE INFORMATION ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        children: [

          Expanded(
            child: Text(
              label,
              style:
                  AppTextStyles.small,
            ),
          ),

          Text(
            value,
            style:
                AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}