import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  bool geofenceEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Geofence',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Home Zone card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                children: [

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.home_outlined,
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
                              'Home zone',
                              style: AppTextStyles.title,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Primary geofence',
                              style: AppTextStyles.small,
                            ),
                          ],
                        ),
                      ),

                      Switch(
                        value: geofenceEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            geofenceEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Tracker 01 is inside the zone',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Zone details',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            _DetailRow(
              icon: Icons.radio_button_checked,
              title: 'Radius',
              value: '200 m',
            ),

            _DetailRow(
              icon: Icons.location_on_outlined,
              title: 'Centre',
              value: 'GPS coordinates',
            ),

            _DetailRow(
              icon: Icons.notifications_outlined,
              title: 'Entry alerts',
              value: 'Enabled',
            ),

            _DetailRow(
              icon: Icons.notifications_active_outlined,
              title: 'Exit alerts',
              value: 'Enabled',
            ),

            const SizedBox(height: 24),

            const Text(
              'Tracker status',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
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
                          style: AppTextStyles.body,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Inside home zone',
                          style: AppTextStyles.statusOnline,
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.edit_location_alt_outlined,
                ),
                label: const Text(
                  'Edit geofence',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  minimumSize: const Size(
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body,
            ),
          ),

          Text(
            value,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}
