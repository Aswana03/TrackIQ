import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Tracker selector
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
                          style: AppTextStyles.title,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'This week',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Overview',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            // First row
            Row(
              children: [

                Expanded(
                  child: _MetricCard(
                    icon: Icons.route_rounded,
                    title: 'Distance',
                    value: '124.6 km',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _MetricCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Trips',
                    value: '18',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Second row
            Row(
              children: [

                Expanded(
                  child: _MetricCard(
                    icon: Icons.timer_outlined,
                    title: 'Tracking time',
                    value: '5h 42m',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _MetricCard(
                    icon: Icons.speed_rounded,
                    title: 'Avg speed',
                    value: '31 km/h',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

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
                children: [

                  _ActivityBar(
                    day: 'Mon',
                    value: '18.4 km',
                    progress: 0.65,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Tue',
                    value: '12.1 km',
                    progress: 0.45,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Wed',
                    value: '22.8 km',
                    progress: 0.82,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Thu',
                    value: '9.7 km',
                    progress: 0.35,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Fri',
                    value: '21.3 km',
                    progress: 0.76,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Sat',
                    value: '25.6 km',
                    progress: 0.92,
                  ),

                  const SizedBox(height: 16),

                  _ActivityBar(
                    day: 'Sun',
                    value: '14.7 km',
                    progress: 0.52,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                    label: 'Longest trip',
                    value: '25.6 km',
                  ),

                  _SummaryRow(
                    label: 'Fastest average',
                    value: '36 km/h',
                  ),

                  _SummaryRow(
                    label: 'Total trips',
                    value: '18',
                  ),

                  _SummaryRow(
                    label: 'Active tracking',
                    value: '5h 42m',
                  ),

                  _SummaryRow(
                    label: 'Geofence events',
                    value: '6',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Analytics will become more accurate as real GPS and trip data is collected.',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
    );
  }
}


/// Metric card
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


/// Weekly activity bar
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
          width: 55,
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


/// Summary row
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