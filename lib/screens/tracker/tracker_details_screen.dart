import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../route_history/route_history_screen.dart';

class TrackerDetailsScreen extends StatefulWidget {
  const TrackerDetailsScreen({super.key});

  @override
  State<TrackerDetailsScreen> createState() =>
      _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState
    extends State<TrackerDetailsScreen> {

  GoogleMapController? _mapController;

  // Temporary test location.
  // Later this will come from the ESP32 + Neo-6M.
  static const LatLng trackerLocation = LatLng(
    10.7867,
    76.6548,
  );

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('tracker_01'),
      position: trackerLocation,
      infoWindow: InfoWindow(
        title: 'Tracker 01',
        snippet: 'ESP32 + Neo-6M',
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Tracker Details',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ─────────────────────────────
            // Tracker header
            // ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                children: [

                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.devices_other_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Tracker 01',
                    style: AppTextStyles.heading,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'ESP32 + Neo-6M',
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [

                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Text(
                        'Online',
                        style:
                            AppTextStyles.statusOnline,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────
            // Device status
            // ─────────────────────────────
            const Text(
              'Device status',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatusCard(
                    icon:
                        Icons.signal_cellular_alt_rounded,
                    title: 'Signal',
                    value: 'Strong',
                    valueColor:
                        AppColors.success,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatusCard(
                    icon:
                        Icons.battery_6_bar_rounded,
                    title: 'Battery',
                    value: '86%',
                    valueColor:
                        AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _StatusCard(
                    icon: Icons.speed_rounded,
                    title: 'Speed',
                    value: '32 km/h',
                    valueColor:
                        AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatusCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'GPS',
                    value: 'Active',
                    valueColor:
                        AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────
            // Map
            // ─────────────────────────────
            const Text(
              'Asset location',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 280,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: GoogleMap(
                initialCameraPosition:
                    const CameraPosition(
                  target: trackerLocation,
                  zoom: 15,
                ),

                markers: _markers,

                myLocationButtonEnabled: false,

                zoomControlsEnabled: true,

                mapToolbarEnabled: false,

                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),

            const SizedBox(height: 12),

            // Location information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [

                  Icon(
                    Icons.location_on_rounded,
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
                          'Inside home zone',
                          style:
                              AppTextStyles.body,
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Last updated 2 minutes ago',
                          style:
                              AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────
            // Device information
            // ─────────────────────────────
            const Text(
              'Device information',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 12),

            const _InfoRow(
              label: 'Device type',
              value: 'ESP32 Tracker',
            ),

            const _InfoRow(
              label: 'GPS module',
              value: 'Neo-6M',
            ),

            const _InfoRow(
              label: 'Status',
              value: 'Connected',
            ),

            const _InfoRow(
              label: 'Last seen',
              value: '2 minutes ago',
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────
            // Route history
            // ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RouteHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.history_rounded,
                ),
                label: const Text(
                  'View route history',
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


/// Device status card
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const _StatusCard({
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


/// Device information row
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
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
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}