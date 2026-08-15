import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../trip_details/trip_details_screen.dart';

class RouteHistoryScreen extends StatelessWidget {
  const RouteHistoryScreen({super.key});

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

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Tracker information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
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
                        style: AppTextStyles.title,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ESP32 + Neo-6M',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.circle,
                  color: AppColors.success,
                  size: 10,
                ),

                SizedBox(width: 6),

                Text(
                  'Online',
                  style: AppTextStyles.statusOnline,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Today',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 12),

          _TripCard(
            startLocation: 'Home',
            endLocation: 'NSS College of Engineering',
            startTime: '08:30 AM',
            endTime: '09:02 AM',
            distance: '12.4 km',
            duration: '32 min',
            averageSpeed: '28 km/h',
          ),

          const SizedBox(height: 12),

          _TripCard(
            startLocation: 'NSS College of Engineering',
            endLocation: 'Home',
            startTime: '04:45 PM',
            endTime: '05:26 PM',
            distance: '13.1 km',
            duration: '41 min',
            averageSpeed: '27 km/h',
          ),

          const SizedBox(height: 24),

          const Text(
            'Yesterday',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 12),

          _TripCard(
            startLocation: 'Home',
            endLocation: 'Palakkad',
            startTime: '09:10 AM',
            endTime: '09:38 AM',
            distance: '9.8 km',
            duration: '28 min',
            averageSpeed: '25 km/h',
          ),

          const SizedBox(height: 12),

          _TripCard(
            startLocation: 'Palakkad',
            endLocation: 'Home',
            startTime: '06:10 PM',
            endTime: '06:48 PM',
            distance: '10.2 km',
            duration: '38 min',
            averageSpeed: '24 km/h',
          ),

          const SizedBox(height: 24),

          const Text(
            'Route history is stored automatically when tracking is active.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}


/// Individual trip card
class _TripCard extends StatelessWidget {
  final String startLocation;
  final String endLocation;
  final String startTime;
  final String endTime;
  final String distance;
  final String duration;
  final String averageSpeed;

  const _TripCard({
    required this.startLocation,
    required this.endLocation,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailsScreen(
              startLocation: startLocation,
              endLocation: endLocation,
              startTime: startTime,
              endTime: endTime,
              distance: distance,
              duration: duration,
              averageSpeed: averageSpeed,
            ),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),

        child: Column(
          children: [

            // Route locations
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Column(
                  children: [

                    const Icon(
                      Icons.radio_button_checked,
                      color: AppColors.primary,
                      size: 18,
                    ),

                    Container(
                      width: 2,
                      height: 28,
                      color: AppColors.border,
                    ),

                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.alert,
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        startLocation,
                        style: AppTextStyles.body,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        startTime,
                        style: AppTextStyles.small,
                      ),

                      const SizedBox(height: 14),

                      Text(
                        endLocation,
                        style: AppTextStyles.body,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        endTime,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(
              height: 1,
              color: AppColors.border,
            ),

            const SizedBox(height: 14),

            // Trip statistics
            Row(
              children: [

                Expanded(
                  child: _StatItem(
                    icon: Icons.route_rounded,
                    label: 'Distance',
                    value: distance,
                  ),
                ),

                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: duration,
                  ),
                ),

                Expanded(
                  child: _StatItem(
                    icon: Icons.speed_rounded,
                    label: 'Avg speed',
                    value: averageSpeed,
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


/// Trip statistic item
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),

        const SizedBox(height: 6),

        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: AppTextStyles.small,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}