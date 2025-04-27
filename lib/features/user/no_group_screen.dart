import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:provider/provider.dart';

class NoGroupScreen extends StatelessWidget {
  const NoGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_off,
                size: 80,
                color: AppColors.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'You haven\'t been assigned to a group yet',
                style: TextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please contact your administrator to be assigned to a group.',
                style: TextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Refresh the page to check if user has been assigned to a group
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const NoGroupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}