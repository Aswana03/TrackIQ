
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final DatabaseReference _alertsRef =
      FirebaseDatabase.instance.ref(
    'trackers/trackiq/securityAlerts',
  );

  Future<void> _updateAlertStatus(
    String alertId,
    String status,
  ) async {
    try {
      await _alertsRef.child(alertId).update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'acknowledged'
                ? 'Security alert acknowledged.'
                : 'Security incident resolved.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update alert: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Security Alerts',
          style: AppTextStyles.title,
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _alertsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load security alerts.'),
            );
          }

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final alerts = <_SecurityAlert>[];

          final data = snapshot.data?.snapshot.value;

          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                alerts.add(
                  _SecurityAlert.fromMap(
                    key.toString(),
                    Map<dynamic, dynamic>.from(value),
                  ),
                );
              }
            });
          }

          alerts.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );

          final activeCount = alerts
              .where((a) => a.status != 'resolved')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Industrial Security Centre',
                  style: AppTextStyles.heading,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Monitor unauthorized movement and '
                  'security incidents involving your machines.',
                  style: AppTextStyles.subtitle,
                ),

                const SizedBox(height: 24),

                _buildSummary(activeCount, alerts.length),

                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Security Incidents',
                      style: AppTextStyles.title,
                    ),
                    Text(
                      '${alerts.length} total',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (alerts.isEmpty)
                  _buildEmptyState()
                else
                  ...alerts.map(
                    (alert) => _buildAlertCard(alert),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(int activeCount, int totalCount) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Active Incidents',
            count: activeCount.toString(),
            icon: Icons.warning_amber_rounded,
            color: AppColors.alert,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: 'Total Incidents',
            count: totalCount.toString(),
            icon: Icons.security_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 14),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_SecurityAlert alert) {
    final isResolved = alert.status == 'resolved';
    final isAcknowledged = alert.status == 'acknowledged';

    final statusColor = isResolved
        ? AppColors.success
        : isAcknowledged
            ? AppColors.primary
            : AppColors.alert;

    final statusText = isResolved
        ? 'Resolved'
        : isAcknowledged
            ? 'Acknowledged'
            : 'Unacknowledged';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  alert.machineId,
                  style: AppTextStyles.title,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: AppColors.alert,
                size: 25,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: AppColors.alert,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            alert.description,
            style: AppTextStyles.subtitle,
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.location_on_outlined,
            alert.latitude != null &&
                    alert.longitude != null
                ? '${alert.latitude}, ${alert.longitude}'
                : 'Location unavailable',
          ),

          const SizedBox(height: 10),

          _infoRow(
            Icons.access_time_rounded,
            _formatDate(alert.timestamp),
          ),

          const SizedBox(height: 16),

          if (!isResolved)
            Row(
              children: [
                if (!isAcknowledged)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _updateAlertStatus(
                          alert.id,
                          'acknowledged',
                        );
                      },
                      child: const Text('Acknowledge'),
                    ),
                  ),

                if (!isAcknowledged)
                  const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateAlertStatus(
                        alert.id,
                        'resolved',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Resolve'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 38,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 55,
            color: AppColors.success,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Security Incidents',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your machine has no recorded security alerts.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }
}

class _SecurityAlert {
  final String id;
  final String machineId;
  final String title;
  final String description;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  const _SecurityAlert({
    required this.id,
    required this.machineId,
    required this.title,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory _SecurityAlert.fromMap(
    String id,
    Map<dynamic, dynamic> data,
  ) {
    return _SecurityAlert(
      id: id,
      machineId:
          data['machineId']?.toString() ?? 'Machine 01',
      title:
          data['title']?.toString() ??
          'Unauthorized Movement',
      description:
          data['description']?.toString() ??
          'Machine movement detected outside its assigned region.',
      status:
          data['status']?.toString() ?? 'unacknowledged',
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      timestamp: _toDateTime(
        data['timestamp'] ?? data['createdAt'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
        isUtc: true,
      );
    }

    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.now().toUtc();
  }
}
