import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/features/super_admin/dashboard_cleaned.dart';
import 'package:group_management_church_app/features/region_manager/region_dashboard.dart';
import 'package:group_management_church_app/features/super_admin/screens/analytics_screen.dart';
import 'package:group_management_church_app/features/region_manager/screens/analytics_screen.dart';
import 'package:group_management_church_app/widgets/removed_members_list.dart';
import 'package:group_management_church_app/widgets/region_removed_members_list.dart';

class MoreOptionsScreen extends StatelessWidget {
  final String userRole;
  final String? regionId;
  final bool actingAsSuperAdmin;

  const MoreOptionsScreen({
    super.key,
    required this.userRole,
    this.regionId,
    this.actingAsSuperAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More Options'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (userRole == 'super_admin') ...[
            _buildSuperAdminOptions(context),
          ] else if (userRole == 'regional_manager') ...[
            _buildRegionalManagerOptions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSuperAdminOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionCard(
          context,
          'Dashboard',
          Icons.dashboard,
          'Main dashboard overview',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SuperAdminDashboard(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Regions',
          Icons.map,
          'Manage regions and regional managers',
          () {
            // Navigate to Super Admin Dashboard and switch to Regions tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminDashboard(),
              ),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Removed Members',
          Icons.person_remove,
          'View and manage removed members',
          () {
            // Navigate to Super Admin Dashboard and switch to Removed Members tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminDashboard(),
              ),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Analytics',
          Icons.analytics,
          'View detailed analytics and reports',
          () {
            // Navigate to Super Admin Dashboard and switch to Analytics tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminDashboard(),
              ),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Settings',
          Icons.settings,
          'App settings and preferences',
          () {
            // Navigate to Super Admin Dashboard and switch to Settings tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminDashboard(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegionalManagerOptions(BuildContext context) {
    return Column(
      children: [
        _buildOptionCard(
          context,
          'Dashboard',
          Icons.dashboard,
          'Main dashboard overview',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionDashboard(
                regionId: regionId!,
                actingAsSuperAdmin: actingAsSuperAdmin,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Removed Members',
          Icons.person_remove,
          'View and manage removed members',
          () {
            // Navigate to Region Dashboard and switch to Removed Members tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => RegionDashboard(
                  regionId: regionId!,
                  actingAsSuperAdmin: actingAsSuperAdmin,
                ),
              ),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Analytics',
          Icons.analytics,
          'View detailed analytics and reports',
          () {
            // Navigate to Region Dashboard and switch to Analytics tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => RegionDashboard(
                  regionId: regionId!,
                  actingAsSuperAdmin: actingAsSuperAdmin,
                ),
              ),
              (route) => false,
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          context,
          'Settings',
          Icons.settings,
          'App settings and preferences',
          () {
            // Navigate to Region Dashboard and switch to Settings tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => RegionDashboard(
                  regionId: regionId!,
                  actingAsSuperAdmin: actingAsSuperAdmin,
                ),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyles.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
