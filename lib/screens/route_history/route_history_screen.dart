
import 'dart:async';
import 'dart:math' as math;

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

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  final TrackerRepository _trackerRepository = TrackerRepository();

  GoogleMapController? _mapController;

  StreamSubscription<List<TrackerLocation>>? _historySubscription;

  List<TrackerLocation> _history = [];

  String? _selectedDate;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenToHistory();
  }

  // Listen to Firebase history.
  void _listenToHistory() {
    _historySubscription = _trackerRepository.historyStream.listen(
      (history) {
        if (!mounted) return;

        history.sort(
          (a, b) => a.timestamp.compareTo(b.timestamp),
        );

        setState(() {
          _history = history;

          final grouped = _groupHistoryByDate();

          if (grouped.isEmpty) {
            _selectedDate = null;
          } else if (_selectedDate == null ||
              !grouped.containsKey(_selectedDate)) {
            _selectedDate = grouped.keys.last;
          }

          _updateRoute(_selectedHistory);
          _loading = false;
        });

        if (_selectedHistory.isNotEmpty) {
          _moveCameraToRoute(_selectedHistory);
        }
      },
    );
  }

  // Group GPS locations by local calendar date.
  Map<String, List<TrackerLocation>> _groupHistoryByDate() {
    final Map<String, List<TrackerLocation>> grouped = {};

    for (final location in _history) {
      final local = location.timestamp.toLocal();

      final key =
          '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(location);
    }

    return grouped;
  }

  List<TrackerLocation> get _selectedHistory {
    if (_selectedDate == null) return [];

    return _groupHistoryByDate()[_selectedDate] ?? [];
  }

  // Calculate distance using the Haversine formula.
  double _distanceBetween(
    TrackerLocation first,
    TrackerLocation second,
  ) {
    const earthRadius = 6371.0;

    final lat1 = first.latitude * math.pi / 180;
    final lat2 = second.latitude * math.pi / 180;

    final deltaLat =
        (second.latitude - first.latitude) * math.pi / 180;

    final deltaLon =
        (second.longitude - first.longitude) * math.pi / 180;

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);

    final c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(1 - a),
    );

    return earthRadius * c;
  }

  // Daily statistics.
  double get _totalDistance {
    final history = _selectedHistory;

    if (history.length < 2) return 0;

    double distance = 0;

    for (int i = 1; i < history.length; i++) {
      distance += _distanceBetween(
        history[i - 1],
        history[i],
      );
    }

    return distance;
  }

  double get _averageSpeed {
    final history = _selectedHistory;

    if (history.isEmpty) return 0;

    final total = history.fold<double>(
      0,
      (sum, location) => sum + location.speed,
    );

    return total / history.length;
  }

  double get _maximumSpeed {
    final history = _selectedHistory;

    if (history.isEmpty) return 0;

    return history
        .map((location) => location.speed)
        .reduce((a, b) => a > b ? a : b);
  }

  Duration get _journeyDuration {
    final history = _selectedHistory;

    if (history.length < 2) return Duration.zero;

    return history.last.timestamp.difference(
      history.first.timestamp,
    );
  }

  // Overall statistics.
  double get _overallDistance {
    final grouped = _groupHistoryByDate();

    double total = 0;

    for (final locations in grouped.values) {
      for (int i = 1; i < locations.length; i++) {
        total += _distanceBetween(
          locations[i - 1],
          locations[i],
        );
      }
    }

    return total;
  }

  int get _totalGpsPoints => _history.length;

  int get _totalDaysTracked => _groupHistoryByDate().length;

  double get _overallMaximumSpeed {
    if (_history.isEmpty) return 0;

    return _history
        .map((location) => location.speed)
        .reduce((a, b) => a > b ? a : b);
  }

  List<String> get _recentTrackingDates {
    final dates = _groupHistoryByDate().keys.toList();

    dates.sort((a, b) => b.compareTo(a));

    return dates.take(3).toList();
  }

  // Format duration.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  // Format date.
  String _formatDate(String dateKey) {
    final date = DateTime.parse(dateKey);

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Select a date.
  void _selectDate(String? date) {
    if (date == null) return;

    setState(() {
      _selectedDate = date;
      _updateRoute(_selectedHistory);
    });

    _moveCameraToRoute(_selectedHistory);
  }

  // Update map route and markers.
  void _updateRoute(List<TrackerLocation> history) {
    if (history.isEmpty) {
      _polylines = {};
      _markers = {};
      return;
    }

    final points = history.map((location) {
      return LatLng(
        location.latitude,
        location.longitude,
      );
    }).toList();

    _polylines = {
      Polyline(
        polylineId: const PolylineId('history_route'),
        points: points,
        width: 5,
        color: AppColors.primary,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };

    _markers = {
      Marker(
        markerId: const MarkerId('route_start'),
        position: points.first,
        infoWindow: const InfoWindow(title: 'Start'),
      ),
      Marker(
        markerId: const MarkerId('route_end'),
        position: points.last,
        infoWindow: const InfoWindow(title: 'End'),
      ),
    };
  }

  // Move camera to selected route.
  void _moveCameraToRoute(List<TrackerLocation> history) {
    if (_mapController == null || history.isEmpty) return;

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

  // Overall Journey Summary.
  Widget _buildJourneySummary() {
    final grouped = _groupHistoryByDate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journey Summary',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.route,
                  title: 'Total Distance',
                  value: '${_overallDistance.toStringAsFixed(2)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  icon: Icons.calendar_month,
                  title: 'Days Tracked',
                  value: '$_totalDaysTracked',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.location_on,
                  title: 'GPS Points',
                  value: '$_totalGpsPoints',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  icon: Icons.speed,
                  title: 'Maximum Speed',
                  value:
                      '${_overallMaximumSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Recent Activity',
            style: AppTextStyles.body,
          ),

          const SizedBox(height: 8),

          if (_recentTrackingDates.isEmpty)
            const Text(
              'No recent activity.',
              style: AppTextStyles.small,
            ),

          ..._recentTrackingDates.map(
            (date) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(date),
                      style: AppTextStyles.small,
                    ),
                  ),
                  Text(
                    '${grouped[date]!.length} points',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final grouped = _groupHistoryByDate();
    final selectedHistory = _selectedHistory;

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
                    // DATE SELECTOR
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: AppColors.surface,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),

                          const Text(
                            'Select Date:',
                            style: AppTextStyles.body,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedDate,
                                dropdownColor: AppColors.surface,
                                items: grouped.keys.map((date) {
                                  return DropdownMenuItem<String>(
                                    value: date,
                                    child: Text(
                                      _formatDate(date),
                                      style: AppTextStyles.body,
                                    ),
                                  );
                                }).toList(),
                                onChanged: _selectDate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MAP
                    Expanded(
                      flex: 3,
                      child: selectedHistory.isEmpty
                          ? const Center(
                              child: Text('No GPS points for this date.'),
                            )
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  selectedHistory.last.latitude,
                                  selectedHistory.last.longitude,
                                ),
                                zoom: 15,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              zoomControlsEnabled: true,
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _moveCameraToRoute(selectedHistory);
                              },
                            ),
                    ),

                    // SCROLLABLE STATISTICS PANEL
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: selectedHistory.isEmpty
                            ? const Center(
                                child: Text('No route information.'),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // OVERALL SUMMARY
                                    _buildJourneySummary(),

                                    // SELECTED DATE STATISTICS
                                    const Text(
                                      'Selected Day Statistics',
                                      style: AppTextStyles.title,
                                    ),

                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.route,
                                            title: 'Distance',
                                            value:
                                                '${_totalDistance.toStringAsFixed(2)} km',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.speed,
                                            title: 'Average Speed',
                                            value:
                                                '${_averageSpeed.toStringAsFixed(1)} km/h',
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.trending_up,
                                            title: 'Maximum Speed',
                                            value:
                                                '${_maximumSpeed.toStringAsFixed(1)} km/h',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.timer,
                                            title: 'Duration',
                                            value: _formatDuration(
                                              _journeyDuration,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    Text(
                                      'Date: ${_formatDate(_selectedDate!)}',
                                      style: AppTextStyles.small,
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      'GPS Points: ${selectedHistory.length}',
                                      style: AppTextStyles.small,
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      'Start: ${_formatTime(selectedHistory.first.timestamp)}',
                                      style: AppTextStyles.small,
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      'Latest: ${_formatTime(selectedHistory.last.timestamp)}',
                                      style: AppTextStyles.small,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

// Reusable statistics card.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: AppTextStyles.small,
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
