import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() =>
      _RouteHistoryScreenState();
}

class _RouteHistoryScreenState
    extends State<RouteHistoryScreen> {
  final TrackerRepository _trackerRepository =
      TrackerRepository();

  GoogleMapController? _mapController;

  StreamSubscription<List<TrackerLocation>>?
      _historySubscription;

  List<TrackerLocation> _history = [];

  Set<Polyline> _polylines = {};

  Set<Marker> _markers = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _listenToHistory();
  }

  void _listenToHistory() {
    _historySubscription =
        _trackerRepository.historyStream.listen(
      (history) {
        if (!mounted) return;

        setState(() {
          _history = history;
          _loading = false;

          _updateRoute(history);
        });

        if (history.isNotEmpty) {
          _moveCameraToRoute(history);
        }
      },
    );
  }

  void _updateRoute(
    List<TrackerLocation> history,
  ) {
    if (history.isEmpty) {
      _polylines = {};
      _markers = {};
      return;
    }

    final points = history
        .map(
          (location) => LatLng(
            location.latitude,
            location.longitude,
          ),
        )
        .toList();

    _polylines = {
      Polyline(
        polylineId:
            const PolylineId('history_route'),
        points: points,
        width: 5,
        color: AppColors.primary,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };

    final first = points.first;
    final last = points.last;

    _markers = {
      Marker(
        markerId:
            const MarkerId('route_start'),
        position: first,
        infoWindow: const InfoWindow(
          title: 'Start',
        ),
      ),
      Marker(
        markerId:
            const MarkerId('route_current'),
        position: last,
        infoWindow: const InfoWindow(
          title: 'Latest Location',
        ),
      ),
    };
  }

  void _moveCameraToRoute(
    List<TrackerLocation> history,
  ) {
    if (_mapController == null ||
        history.isEmpty) {
      return;
    }

    final last = history.last;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          last.latitude,
          last.longitude,
        ),
        15,
      ),
    );
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _mapController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Route History',
          style: AppTextStyles.title,
        ),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'No route history available.',
                    style: AppTextStyles.body,
                  ),
                )
              : Column(
                  children: [

                    // ==============================
                    // MAP
                    // ==============================

                    Expanded(
                      flex: 3,
                      child: GoogleMap(
                        initialCameraPosition:
                            CameraPosition(
                          target: LatLng(
                            _history.last.latitude,
                            _history.last.longitude,
                          ),
                          zoom: 15,
                        ),

                        markers: _markers,

                        polylines: _polylines,

                        zoomControlsEnabled: true,

                        myLocationButtonEnabled:
                            false,

                        mapToolbarEnabled: false,

                        onMapCreated:
                            (controller) {
                          _mapController =
                              controller;

                          _moveCameraToRoute(
                            _history,
                          );
                        },
                      ),
                    ),

                    // ==============================
                    // HISTORY INFORMATION
                    // ==============================

                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(16),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.surface,
                          borderRadius:
                              const BorderRadius
                                  .vertical(
                            top: Radius.circular(
                              20,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            const Text(
                              'Route information',
                              style:
                                  AppTextStyles.title,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            Row(
                              children: [

                                Expanded(
                                  child:
                                      _InfoCard(
                                    title:
                                        'GPS Points',
                                    value:
                                        '${_history.length}',
                                  ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      _InfoCard(
                                    title:
                                        'Latest Speed',
                                    value:
                                        '${_history.last.speed.toStringAsFixed(0)} km/h',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              'Start: ${_formatTime(_history.first.timestamp)}',
                              style:
                                  AppTextStyles.small,
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              'Latest: ${_formatTime(_history.last.timestamp)}',
                              style:
                                  AppTextStyles.small,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              'Latest position: '
                              '${_history.last.latitude.toStringAsFixed(6)}, '
                              '${_history.last.longitude.toStringAsFixed(6)}',
                              style:
                                  AppTextStyles.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    final second =
        local.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

// =====================================================
// Information Card
// =====================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: AppTextStyles.small,
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}