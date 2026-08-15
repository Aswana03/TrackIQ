import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActivated = false;

  void _activateSos() {
    setState(() {
      _sosActivated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SOS activated',
        ),
      ),
    );
  }

  void _cancelSos() {
    setState(() {
      _sosActivated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'SOS / Emergency',
          style: AppTextStyles.title,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 10),

            // Warning message
            const Text(
              'Emergency assistance',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Hold the button to activate an SOS alert.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 35),

            // SOS button
            GestureDetector(
              onLongPress: _sosActivated
                  ? null
                  : _activateSos,

              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),

                width: 190,
                height: 190,

                decoration: BoxDecoration(
                  color: _sosActivated
                      ? AppColors.alert.withValues(
                          alpha: 0.35,
                        )
                      : AppColors.alert,

                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.alert.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),

                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 48,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _sosActivated
                            ? 'ACTIVE'
                            : 'SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _sosActivated
                  ? 'SOS alert is active'
                  : 'Press and hold',
              style: TextStyle(
                color: _sosActivated
                    ? AppColors.alert
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            // Tracker status
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

                        SizedBox(height: 4),

                        Text(
                          'ESP32 + Neo-6M',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [

                      Icon(
                        Icons.circle,
                        color: AppColors.success,
                        size: 10,
                      ),

                      SizedBox(width: 6),

                      Text(
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

            // Emergency contacts
            Container(
              width: double.infinity,
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

                  const Text(
                    'Emergency contacts',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 14),

                  _ContactRow(
                    name: 'Mother',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 10),

                  _ContactRow(
                    name: 'Guardian',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add emergency contact',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_sosActivated) ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelSos,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.alert,
                    side: const BorderSide(
                      color: AppColors.alert,
                    ),
                    minimumSize:
                        const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Cancel SOS',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final IconData icon;

  const _ContactRow({
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(10),
          ),

          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            name,
            style: AppTextStyles.body,
          ),
        ),

        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}