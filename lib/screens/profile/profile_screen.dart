import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool pushAlerts = true;
  bool darkMode = true;
  bool useKilometers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Profile',
          style: AppTextStyles.title,
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [

                // Avatar
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'AS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Aswana N',
                  style: AppTextStyles.heading,
                ),

                const SizedBox(height: 5),

                const Text(
                  'aswana@mail.com',
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Preferences',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          // Push alerts
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push alerts',
            subtitle: 'Receive tracking and geofence alerts',
            trailing: Switch(
              value: pushAlerts,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  pushAlerts = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // Dark mode
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            subtitle: 'Use the TrackIQ dark interface',
            trailing: Switch(
              value: darkMode,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  darkMode = value;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // Units
          _SettingsTile(
            icon: Icons.straighten_outlined,
            title: 'Units',
            subtitle: useKilometers
                ? 'Distance displayed in kilometres'
                : 'Distance displayed in miles',
            trailing: Switch(
              value: useKilometers,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  useKilometers = value;
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Account',
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Change password',
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Log out',
            color: AppColors.alert,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'TrackIQ v1.0',
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }
}

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
              crossAxisAlignment: CrossAxisAlignment.start,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.color,
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
              color: color ?? AppColors.primary,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}