import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool geofenceAlerts = true;
  bool lowBatteryAlerts = true;
  bool sosAlerts = true;

  String trackingInterval = '10 seconds';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Settings',
          style: AppTextStyles.title,
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // --------------------------------------------------
          // TRACKER
          // --------------------------------------------------

          const Text(
            'Tracker',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          // Tracking interval
          _SettingsTile(
            icon: Icons.timer_outlined,
            title: 'Tracking interval',
            subtitle:
                'How frequently the tracker updates its location',
            trailing: DropdownButton<String>(
              value: trackingInterval,
              underline: const SizedBox(),
              dropdownColor: AppColors.surface,

              items: const [
                DropdownMenuItem(
                  value: '5 seconds',
                  child: Text('5 sec'),
                ),
                DropdownMenuItem(
                  value: '10 seconds',
                  child: Text('10 sec'),
                ),
                DropdownMenuItem(
                  value: '30 seconds',
                  child: Text('30 sec'),
                ),
                DropdownMenuItem(
                  value: '1 minute',
                  child: Text('1 min'),
                ),
              ],

              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  trackingInterval = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // Geofence settings
          _ActionTile(
            icon: Icons.shield_outlined,
            title: 'Geofence settings',
            subtitle:
                'Configure your home zone and safe area',
            onTap: () {
              // Geofence settings will be connected later.
            },
          ),

          const SizedBox(height: 10),

          // Device settings
          _ActionTile(
            icon: Icons.devices_other_outlined,
            title: 'Device settings',
            subtitle:
                'Manage your connected tracker',
            onTap: () {
              // Device settings will be connected later.
            },
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // NOTIFICATIONS
          // --------------------------------------------------

          const Text(
            'Notifications',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          // Geofence alerts
          _SwitchTile(
            icon: Icons.location_off_outlined,
            title: 'Geofence alerts',
            subtitle:
                'Alert when the tracker leaves the safe zone',
            value: geofenceAlerts,
            onChanged: (value) {
              setState(() {
                geofenceAlerts = value;
              });
            },
          ),

          const SizedBox(height: 10),

          // Low battery alerts
          _SwitchTile(
            icon: Icons.battery_alert_outlined,
            title: 'Low battery alerts',
            subtitle:
                'Alert when tracker battery is low',
            value: lowBatteryAlerts,
            onChanged: (value) {
              setState(() {
                lowBatteryAlerts = value;
              });
            },
          ),

          const SizedBox(height: 10),

          // SOS alerts
          _SwitchTile(
            icon: Icons.warning_amber_rounded,
            title: 'SOS alerts',
            subtitle:
                'Send notifications when SOS is activated',
            value: sosAlerts,
            onChanged: (value) {
              setState(() {
                sosAlerts = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // SECURITY
          // --------------------------------------------------

          const Text(
            'Security',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Change password',
            subtitle:
                'Update your TrackIQ account password',
            onTap: () {
              // Password screen will be connected later.
            },
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // SUPPORT
          // --------------------------------------------------

          const Text(
            'Support',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle:
                'Get help with TrackIQ',
            onTap: () {
              // Help screen will be connected later.
            },
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'About TrackIQ',
            subtitle:
                'Version 1.0',
            onTap: () {
              // About screen will be connected later.
            },
          ),

          const SizedBox(height: 30),

          // App version
          const Center(
            child: Text(
              'TrackIQ v1.0',
              style: AppTextStyles.small,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


// ==========================================================
// SWITCH SETTING TILE
// ==========================================================

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


// ==========================================================
// ACTION TILE
// ==========================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: AppColors.primary,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: AppTextStyles.body,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
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
      ),
    );
  }
}


// ==========================================================
// DROPDOWN SETTING TILE
// ==========================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: AppColors.primary,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),

          trailing,
        ],
      ),
    );
  }
}