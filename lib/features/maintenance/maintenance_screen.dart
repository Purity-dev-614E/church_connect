import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/app_flags.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.construction,
                      size: 56,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Under Maintenance',
                    textAlign: TextAlign.center,
                    style: TextStyles.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onBg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFlags.maintenanceMessage,
                    textAlign: TextAlign.center,
                    style: TextStyles.bodyText.copyWith(
                      color: onBg.withOpacity(0.75),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // During maintenance we keep users on this screen,
                        // but a restart on web or hot reload on mobile can re-check the flag.
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'If you need urgent access, please contact your administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyles.bodyText.copyWith(
                      color: onBg.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

