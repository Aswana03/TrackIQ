import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Live Map',
          style: AppTextStyles.title,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.my_location_rounded,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [

          // Map placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF101827),

            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Tracker 01',
                    style: AppTextStyles.title,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Waiting for GPS location...',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ),
          ),

          // Tracker information card
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                children: [

                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
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
                          'Tracker 01',
                          style: AppTextStyles.title,
                        ),

                        SizedBox(height: 4),

                        Text(
                          'GPS signal: Strong',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),

                  const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [

                      Text(
                        '32 km/h',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Online',
                        style: AppTextStyles.statusOnline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}