import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/tracker_location.dart';
import '../../repositories/tracker_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../tracker/tracker_details_screen.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends State<DeviceManagementScreen> {
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

    // Rebuild every second so Online -> Offline
    // happens automatically even when Firebase
    // does not send a new event.
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

    // If the ESP32 timestamp is somehow in the future,
    // don't treat the tracker as online.
    if (age.isNegative) {
      return false;
    }

    return age <= const Duration(seconds: 15);
  }

  String get _lastSeenText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return 'ESP32 · waiting for data';
    }

    final now = DateTime.now().toUtc();
    final lastUpdate =
        trackerData.timestamp.toUtc();

    final age = now.difference(lastUpdate);

    if (age.isNegative) {
      return 'ESP32 · time error';
    }

    if (age.inSeconds < 5) {
      return 'ESP32 · last seen just now';
    }

    if (age.inSeconds < 60) {
      return 'ESP32 · last seen ${age.inSeconds}s ago';
    }

    if (age.inMinutes < 60) {
      return 'ESP32 · last seen ${age.inMinutes}m ago';
    }

    return 'ESP32 · last seen ${age.inHours}h ago';
  }

  String get _batteryText {
    final trackerData = _trackerData;

    if (trackerData == null) {
      return '--%';
    }

    return '${trackerData.battery.toStringAsFixed(0)}%';
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
          'Devices',
          style: AppTextStyles.title,
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Section title
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My devices',
                style: AppTextStyles.title,
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tracker 01
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TrackerDetailsScreen(),
                ),
              );
            },
            child: _DeviceCard(
              name: 'Tracker 01',
              description: _lastSeenText,
              isOnline: trackerOnline,
              battery: _batteryText,
            ),
          ),

          const SizedBox(height: 12),

          // Tracker 02
          const _DeviceCard(
            name: 'Tracker 02',
            description: 'ESP32 · last seen 1h ago',
            isOnline: false,
            battery: '42%',
          ),

          const SizedBox(height: 20),

          // Pair device
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary,
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pair new device',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Event log',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 12),

          _EventItem(
            time: '09:42',
            text: 'Tracker 01 connected',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),

          _EventItem(
            time: '09:15',
            text: 'Weak GPS signal on Tracker 02',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),

          _EventItem(
            time: '08:50',
            text: 'Tracker 01 exited home zone',
            icon: Icons.location_off_outlined,
            color: AppColors.alert,
          ),

          _EventItem(
            time: '08:02',
            text: 'Tracker 01 entered home zone',
            icon: Icons.location_on_outlined,
            color: AppColors.success,
          ),

          _EventItem(
            time: '07:30',
            text: 'Firmware updated to v1.3',
            icon: Icons.system_update_alt_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isOnline;
  final String battery;

  const _DeviceCard({
    required this.name,
    required this.description,
    required this.isOnline,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  name,
                  style: AppTextStyles.title,
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [

              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Text(
                    isOnline
                        ? 'Online'
                        : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOnline
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                battery,
                style: AppTextStyles.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventItem extends StatelessWidget {
  final String time;
  final String text;
  final IconData icon;
  final Color color;

  const _EventItem({
    required this.time,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [

          SizedBox(
            width: 48,
            child: Text(
              time,
              style: AppTextStyles.small,
            ),
          ),

          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}