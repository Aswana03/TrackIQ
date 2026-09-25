import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../geofence/geofence_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sos/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrackerRepository _trackerRepository =
      TrackerRepository();

  StreamSubscription<TrackerLocation?>?
      _locationSubscription;

  Timer? _statusTimer;

  TrackerLocation? _trackerData;

  @override
  void initState() {
    super.initState();

    _listenToTracker();

    // Refresh every second so Online -> Offline
    // happens automatically when the ESP32 stops sending.
    _statusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _listenToTracker() {
    _locationSubscription =
        _trackerRepository.locationStream.listen(
      (location) {
        if (!mounted || location == null) {
          return;
        }

        setState(() {
          _trackerData = location;
        });
      },
    );
  }

  bool get _trackerOnline {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final lastUpdate =
        trackerData.timestamp.toUtc();

    final age = now.difference(lastUpdate);

    // Protect against an incorrect/future timestamp.
    if (age.isNegative) {
      return false;
    }

    return age <= const Duration(seconds: 15);
  }

  String get _speedText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return '-- km/h';
    }

    return '${trackerData.speed.toStringAsFixed(0)} km/h';
  }

  String get _batteryText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return '--%';
    }

    return '${trackerData.battery.toStringAsFixed(0)}%';
  }

  String get _gpsText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return 'Waiting';
    }

    return trackerData.gpsActive
        ? 'Strong'
        : 'No Fix';
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool trackerOnline = _trackerOnline;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'TrackIQ',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Greeting
            const Text(
              'Hi, Aswana',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 4),

            Text(
              trackerOnline
                  ? 'Your tracker is active'
                  : 'Your tracker is offline',
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(height: 20),

            // Tracker status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
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
                              'ESP32 + Neo-6M',
                              style:
                                  AppTextStyles.small,
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(
                              color: trackerOnline
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            trackerOnline
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color: trackerOnline
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Real speed
                  Text(
                    _speedText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Current speed',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location / Geofence status
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const GeofenceScreen(),
                  ),
                );
              },

              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: const Row(
                  children: [

                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.success,
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inside home zone',
                            style:
                                AppTextStyles.title,
                          ),

                          SizedBox(height: 3),

                          Text(
                            'Geofence status',
                            style:
                                AppTextStyles.small,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SOS
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SosScreen(),
                  ),
                );
              },

              child: Container(
                width: double.infinity,
                height: 130,

                decoration: BoxDecoration(
                  color: AppColors.alert,
                  borderRadius:
                      BorderRadius.circular(18),
                ),

                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick information
            Row(
              children: [

                Expanded(
                  child: _InfoCard(
                    icon:
                        Icons.battery_6_bar_rounded,
                    title: 'Battery',
                    value: _batteryText,
                    valueColor:
                        AppColors.success,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _InfoCard(
                    icon:
                        Icons.gps_fixed_rounded,
                    title: 'GPS',
                    value: _gpsText,
                    valueColor: _trackerData
                                ?.gpsActive ==
                            true
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick information card used for Battery and GPS.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _InfoCard({
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

          const SizedBox(height: 4),

          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}