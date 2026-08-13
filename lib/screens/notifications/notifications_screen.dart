import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: AppTextStyles.title,
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Clear'),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          _NotificationCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            title: 'Tracker 01 left home zone',
            description:
                'The tracker has moved outside the configured geofence.',
            time: '2 min ago',
          ),

          _NotificationCard(
            icon: Icons.battery_alert_rounded,
            iconColor: AppColors.alert,
            title: 'Battery low on Tracker 02',
            description:
                'Battery level has dropped below the warning threshold.',
            time: '18 min ago',
          ),

          _NotificationCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            title: 'Entered home zone',
            description:
                'Tracker 01 has returned to the home zone.',
            time: '1 hour ago',
          ),

          _NotificationCard(
            icon: Icons.gps_fixed_rounded,
            iconColor: AppColors.primary,
            title: 'GPS signal restored',
            description:
                'Tracker 01 is receiving a strong GPS signal.',
            time: '2 hours ago',
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: AppTextStyles.small,
                ),

                const SizedBox(height: 7),

                Text(
                  time,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}