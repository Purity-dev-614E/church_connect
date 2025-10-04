import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/admin_analytics_provider.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/features/admin/Admin_dashboard.dart';
import 'dart:developer';

/// A wrapper widget that ensures all required providers are available for the AdminDashboard
/// and fetches the first group if needed
class AdminDashboardWrapper extends StatefulWidget {
  const AdminDashboardWrapper({super.key});

  @override
  State<AdminDashboardWrapper> createState() => _AdminDashboardWrapperState();
}

class _AdminDashboardWrapperState extends State<AdminDashboardWrapper> {
  bool _isLoading = true;
  String _effectiveGroupId = '';
  String _effectiveGroupName = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeGroupData();
  }

  Future<void> _initializeGroupData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      if (user.regionId == null || user.regionId!.isEmpty) {
        throw Exception('No group assigned to this admin');
      }

      // Directly use user.regionId (which is groupId in your schema)
      setState(() {
        _effectiveGroupId = user.regionId!;
        _effectiveGroupName = user.regionName ?? 'Unknown Group';
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching admin group: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error loading group data: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeGroupData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Providers check
    try {
      Provider.of<AdminAnalyticsProvider>(context, listen: false);
      Provider.of<AttendanceProvider>(context, listen: false);

      return AdminDashboard(
        groupId: _effectiveGroupId,
        groupName: _effectiveGroupName,
      );
    } catch (_) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ],
        child: AdminDashboard(
          groupId: _effectiveGroupId,
          groupName: _effectiveGroupName,
        ),
      );
    }
  }
}
