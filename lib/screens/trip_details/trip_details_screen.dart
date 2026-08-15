import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TripDetailsScreen extends StatelessWidget {
  final String startLocation;
  final String endLocation;
  final String startTime;
  final String endTime;
  final String distance;
  final String duration;
  final String averageSpeed;

  const TripDetailsScreen({
    super.key,
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
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Trip Details',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Route summary
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

                  const Icon(
                    Icons.route_rounded,
                    color: AppColors.primary,
                    size: 42,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '$startLocation → $endLocation',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$startTime - $endTime',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Trip summary',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatCard(
                    icon: Icons.route_rounded,
                    title: 'Distance',
                    value: distance,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    title: 'Duration',
                    value: duration,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatCard(
                    icon: Icons.speed_rounded,
                    title: 'Average speed',
                    value: averageSpeed,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: _StatCard(
                    icon: Icons.battery_6_bar_rounded,
                    title: 'Battery used',
                    value: '4%',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Journey',
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

                  _JourneyRow(
                    icon:
                        Icons.radio_button_checked,
                    iconColor:
                        AppColors.primary,
                    title: 'Started',
                    location: startLocation,
                    time: startTime,
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.only(
                      left: 10,
                    ),
                    child: Container(
                      width: 2,
                      height: 36,
                      color: AppColors.border,
                    ),
                  ),

                  _JourneyRow(
                    icon:
                        Icons.location_on_rounded,
                    iconColor:
                        AppColors.alert,
                    title: 'Arrived',
                    location: endLocation,
                    time: endTime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Route',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            // Map placeholder
            Container(
              width: double.infinity,
              height: 190,

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),

              child: const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                    size: 48,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'Route map',
                    style: AppTextStyles.title,
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Map integration will be added later',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Map will be opened here later.
                },

                icon: const Icon(
                  Icons.map_outlined,
                ),

                label: const Text(
                  'View route',
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


/// Statistic card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
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
            size: 22,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: AppTextStyles.small,
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


/// Journey timeline row
class _JourneyRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String location;
  final String time;

  const _JourneyRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.location,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Icon(
          icon,
          color: iconColor,
          size: 22,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: AppTextStyles.small,
              ),

              const SizedBox(height: 3),

              Text(
                location,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),

        Text(
          time,
          style: AppTextStyles.small,
        ),
      ],
    );
  }
}