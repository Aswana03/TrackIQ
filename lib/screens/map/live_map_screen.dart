import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() =>
      _LiveMapScreenState();
}

class _LiveMapScreenState
    extends State<LiveMapScreen> {
  final TrackerRepository _trackerRepository =
      TrackerRepository();

  StreamSubscription<TrackerLocation?>?
      _locationSubscription;

  StreamSubscription<List<TrackerLocation>>?
      _historySubscription;

  Timer? _statusTimer;

  GoogleMapController? _mapController;

  TrackerLocation? _trackerData;

  bool _hasCenteredOnTracker = false;

  Set<Marker> _markers = {};

  Set<Polyline> _polylines = {};

  static const LatLng _defaultLocation =
      LatLng(10.7867, 76.6548);

  @override
  void initState() {
    super.initState();

    _listenToTracker();
    _listenToRoute();

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

        setState(() {
          _trackerData = location;

          _markers = {
            Marker(
              markerId:
                  const MarkerId('tracker_01'),
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

        _updateMapPosition(location);
      },
    );
  }

  // ----------------------------------------------------------
  // ROUTE HISTORY
  // ----------------------------------------------------------

  void _listenToRoute() {
    _historySubscription =
        _trackerRepository.historyStream.listen(
      (history) {
        if (!mounted) {
          return;
        }

        if (history.length < 2) {
          setState(() {
            _polylines = {};
          });
          return;
        }

        final routePoints = history
            .map(
              (location) => LatLng(
                location.latitude,
                location.longitude,
              ),
            )
            .toList();

        setState(() {
          _polylines = {
            Polyline(
              polylineId:
                  const PolylineId('tracker_route'),

              points: routePoints,

              width: 5,

              color: AppColors.primary,

              startCap: Cap.roundCap,

              endCap: Cap.roundCap,

              jointType: JointType.round,
            ),
          };
        });
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

    if (controller == null ||
        trackerData == null) {
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
  // ONLINE / OFFLINE
  // ----------------------------------------------------------

  bool get _trackerOnline {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return false;
    }

    final now = DateTime.now().toUtc();

    final lastUpdate =
        trackerData.timestamp.toUtc();

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
    _historySubscription?.cancel();
    _statusTimer?.cancel();

    _mapController?.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool trackerOnline =
        _trackerOnline;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Live Map',
          style: AppTextStyles.title,
        ),

        actions: [
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

          // ==================================================
          // GOOGLE MAP
          // ==================================================

          GoogleMap(
            initialCameraPosition:
                const CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),

            onMapCreated: (controller) {
              _mapController = controller;

              final trackerData =
                  _trackerData;

              if (trackerData != null) {
                _updateMapPosition(
                  trackerData,
                );
              }
            },

            markers: _markers,

            polylines: _polylines,

            myLocationEnabled: false,

            myLocationButtonEnabled: false,

            zoomControlsEnabled: false,

            mapToolbarEnabled: false,

            compassEnabled: true,

            buildingsEnabled: true,

            trafficEnabled: false,
          ),

          // ==================================================
          // COORDINATES
          // ==================================================

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(12),
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
                      style:
                          AppTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // TRACKER INFORMATION CARD
          // ==================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding:
                  const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
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
                    decoration:
                        BoxDecoration(
                      color: AppColors.primary
                          .withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color:
                          AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TRACKER DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        const Text(
                          'Tracker 01',
                          style:
                              AppTextStyles.title,
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          _gpsText,
                          style:
                              AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),

                  // SPEED + ONLINE
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,

                    children: [

                      Text(
                        _speedText,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors
                                  .textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Row(
                        children: [

                          Container(
                            width: 7,
                            height: 7,
                            decoration:
                                BoxDecoration(
                              color: trackerOnline
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .textMuted,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            trackerOnline
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color:
                                  trackerOnline
                                      ? AppColors
                                          .success
                                      : AppColors
                                          .textMuted,
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