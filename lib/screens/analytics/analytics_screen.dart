import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TrackerRepository _trackerRepository = TrackerRepository();

  StreamSubscription<List<TrackerLocation>>? _historySubscription;

  List<TrackerLocation> _history = [];

  @override
  void initState() {
    super.initState();

    _listenToHistory();
  }

  void _listenToHistory() {
    _historySubscription =
        _trackerRepository.historyStream.listen((history) {
      if (!mounted) return;

      setState(() {
        _history = history;
      });
    });
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE HELPERS
  // ------------------------------------------------------------

  DateTime _startOfWeek(DateTime date) {
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final daysFromMonday = dateOnly.weekday - DateTime.monday;

    return dateOnly.subtract(
      Duration(days: daysFromMonday),
    );
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(
      const Duration(days: 7),
    );
  }

  // ------------------------------------------------------------
  // CURRENT WEEK HISTORY
  // ------------------------------------------------------------

  List<TrackerLocation> get _thisWeekHistory {
    final now = DateTime.now();

    final start = _startOfWeek(now);
    final end = _endOfWeek(now);

    return _history.where((location) {
      final time = location.timestamp.toLocal();

      return !time.isBefore(start) && time.isBefore(end);
    }).toList();
  }

  // ------------------------------------------------------------
  // DISTANCE CALCULATION
  // ------------------------------------------------------------

  double _calculateDistance(
    List<TrackerLocation> locations,
  ) {
    if (locations.length < 2) {
      return 0;
    }

    double totalDistance = 0;

    for (int i = 1; i < locations.length; i++) {
      final previous = locations[i - 1];
      final current = locations[i];

      totalDistance += _distanceBetween(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );
    }

    return totalDistance;
  }

  // Haversine formula.
  // Returns distance in kilometres.
  double _distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(1 - a),
    );

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  // ------------------------------------------------------------
  // STATISTICS
  // ------------------------------------------------------------

  double get _totalDistance {
    return _calculateDistance(_thisWeekHistory);
  }

  double get _averageSpeed {
    final locations = _thisWeekHistory;

    if (locations.isEmpty) {
      return 0;
    }

    final totalSpeed = locations.fold<double>(
      0,
      (sum, location) => sum + location.speed,
    );

    return totalSpeed / locations.length;
  }

  double get _maximumSpeed {
    if (_thisWeekHistory.isEmpty) {
      return 0;
    }

    return _thisWeekHistory
        .map((location) => location.speed)
        .reduce(math.max);
  }

  Duration get _trackingDuration {
    final locations = _thisWeekHistory;

    if (locations.length < 2) {
      return Duration.zero;
    }

    final start = locations.first.timestamp;
    final end = locations.last.timestamp;

    final difference = end.difference(start);

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  DateTime? get _startTime {
    if (_thisWeekHistory.isEmpty) {
      return null;
    }

    return _thisWeekHistory.first.timestamp.toLocal();
  }

  DateTime? get _endTime {
    if (_thisWeekHistory.isEmpty) {
      return null;
    }

    return _thisWeekHistory.last.timestamp.toLocal();
  }

  // ------------------------------------------------------------
  // DAILY DISTANCE
  // ------------------------------------------------------------

  double _distanceForDay(
    DateTime day,
  ) {
    final locations = _thisWeekHistory.where((location) {
      final time = location.timestamp.toLocal();

      return time.year == day.year &&
          time.month == day.month &&
          time.day == day.day;
    }).toList();

    return _calculateDistance(locations);
  }

  double get _maximumDailyDistance {
    final weekStart = _startOfWeek(DateTime.now());

    double maximum = 0;

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(
        Duration(days: i),
      );

      final distance = _distanceForDay(day);

      if (distance > maximum) {
        maximum = distance;
      }
    }

    return maximum;
  }

  // ------------------------------------------------------------
  // FORMATTERS
  // ------------------------------------------------------------

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return '0 min';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes} min';
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '--';
    }

    final hour = time.hour;
    final minute = time.minute;

    final hour12 = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;

    final period = hour >= 12 ? 'PM' : 'AM';

    return '${hour12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDistance(double distance) {
    return '${distance.toStringAsFixed(2)} km';
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final weekHistory = _thisWeekHistory;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: AppTextStyles.title,
        ),
      ),

      body: weekHistory.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  // ------------------------------------------------
                  // TRACKER
                  // ------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Row(
                      children: [

                        Icon(
                          Icons.devices_other_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                'Tracker 01',
                                style:
                                    AppTextStyles.title,
                              ),

                              SizedBox(height: 3),

                              Text(
                                'This week',
                                style:
                                    AppTextStyles.small,
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // OVERVIEW
                  // ------------------------------------------------

                  const Text(
                    'Overview',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      Expanded(
                        child: _MetricCard(
                          icon: Icons.route_rounded,
                          title: 'Distance',
                          value:
                              _formatDistance(
                            _totalDistance,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _MetricCard(
                          icon:
                              Icons.location_on_rounded,
                          title: 'GPS points',
                          value:
                              '${weekHistory.length}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      Expanded(
                        child: _MetricCard(
                          icon:
                              Icons.timer_outlined,
                          title: 'Tracking time',
                          value:
                              _formatDuration(
                            _trackingDuration,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _MetricCard(
                          icon: Icons.speed_rounded,
                          title: 'Avg speed',
                          value:
                              '${_averageSpeed.toStringAsFixed(1)} km/h',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      Expanded(
                        child: _MetricCard(
                          icon:
                              Icons.speed_rounded,
                          title: 'Max speed',
                          value:
                              '${_maximumSpeed.toStringAsFixed(1)} km/h',
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _MetricCard(
                          icon:
                              Icons.calendar_today_rounded,
                          title: 'Recorded days',
                          value:
                              '${_recordedDays}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // TRIP STATISTICS
                  // ------------------------------------------------

                  const Text(
                    'Trip Statistics',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [

                        _SummaryRow(
                          label: 'Distance travelled',
                          value:
                              _formatDistance(
                            _totalDistance,
                          ),
                        ),

                        _SummaryRow(
                          label: 'Trip duration',
                          value:
                              _formatDuration(
                            _trackingDuration,
                          ),
                        ),

                        _SummaryRow(
                          label: 'Average speed',
                          value:
                              '${_averageSpeed.toStringAsFixed(1)} km/h',
                        ),

                        _SummaryRow(
                          label: 'Maximum speed',
                          value:
                              '${_maximumSpeed.toStringAsFixed(1)} km/h',
                        ),

                        _SummaryRow(
                          label: 'Start time',
                          value:
                              _formatTime(_startTime),
                        ),

                        _SummaryRow(
                          label: 'End time',
                          value:
                              _formatTime(_endTime),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // WEEKLY ACTIVITY
                  // ------------------------------------------------

                  const Text(
                    'Weekly activity',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: _buildWeeklyBars(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // TRACKING SUMMARY
                  // ------------------------------------------------

                  const Text(
                    'Tracking summary',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [

                        _SummaryRow(
                          label: 'Longest day',
                          value:
                              _formatDistance(
                            _maximumDailyDistance,
                          ),
                        ),

                        _SummaryRow(
                          label: 'Maximum speed',
                          value:
                              '${_maximumSpeed.toStringAsFixed(1)} km/h',
                        ),

                        _SummaryRow(
                          label: 'GPS points',
                          value:
                              '${weekHistory.length}',
                        ),

                        _SummaryRow(
                          label: 'Active tracking',
                          value:
                              _formatDuration(
                            _trackingDuration,
                          ),
                        ),

                        _SummaryRow(
                          label: 'Geofence events',
                          value: 'Not available',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Statistics are calculated from the GPS history received from Tracker 01.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // RECORDED DAYS
  // ------------------------------------------------------------

  int get _recordedDays {
    final days = <String>{};

    for (final location in _thisWeekHistory) {
      final time = location.timestamp.toLocal();

      days.add(
        '${time.year}-${time.month}-${time.day}',
      );
    }

    return days.length;
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            const Text(
              'No GPS history yet',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'Trip statistics will appear here once Tracker 01 starts sending GPS data.',
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WEEKLY BARS
  // ------------------------------------------------------------

  List<Widget> _buildWeeklyBars() {
    final weekStart = _startOfWeek(
      DateTime.now(),
    );

    final days = <Widget>[];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(
        Duration(days: i),
      );

      final distance = _distanceForDay(day);

      final progress = _maximumDailyDistance == 0
          ? 0.0
          : (distance / _maximumDailyDistance)
              .clamp(0.0, 1.0);

      days.add(
        _ActivityBar(
          day: _dayName(day.weekday),
          value:
              _formatDistance(distance),
          progress: progress,
        ),
      );

      if (i != 6) {
        days.add(
          const SizedBox(height: 16),
        );
      }
    }

    return days;
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}

// ============================================================
// METRIC CARD
// ============================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WEEKLY ACTIVITY BAR
// ============================================================

class _ActivityBar extends StatelessWidget {
  final String day;
  final String value;
  final double progress;

  const _ActivityBar({
    required this.day,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        SizedBox(
          width: 35,
          child: Text(
            day,
            style: AppTextStyles.small,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
                  AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 65,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.small,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SUMMARY ROW
// ============================================================

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [

          Expanded(
            child: Text(
              label,
              style: AppTextStyles.small,
            ),
          ),

          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}