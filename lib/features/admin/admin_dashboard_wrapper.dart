import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/widgets/debug_fab.dart';
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
  final String groupId;
  final String groupName;

  const AdminDashboardWrapper({
    super.key,
    required this.groupId,
    required this.groupName,
  });

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
      // If we have a valid group ID (not 'default'), use it directly
      if (widget.groupId != 'default') {
        setState(() {
          _effectiveGroupId = widget.groupId;
          _effectiveGroupName = widget.groupName;
          _isLoading = false;
        });
        return;
      }

      // Otherwise, fetch the first group for this admin
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not found');
      }

      log('Fetching groups for admin with ID: ${user.id}');
      final adminGroups = await groupProvider.getGroupsByAdmin(user.id);

      if (adminGroups.isEmpty) {
        log('No groups found for admin, using default');
        setState(() {
          _effectiveGroupId = 'default';
          _effectiveGroupName = 'Default Group';
          _isLoading = false;
        });
        return;
      }

      // Use the first group
      final firstGroup = adminGroups.first;
      log('Using first group: ${firstGroup.name} (${firstGroup.id})');
      
      setState(() {
        _effectiveGroupId = firstGroup.id;
        _effectiveGroupName = firstGroup.name;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching admin groups: $e');
      setState(() {
        _error = e.toString();
        _effectiveGroupId = widget.groupId;
        _effectiveGroupName = widget.groupName;
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

    // Check if the required providers are already available in the widget tree
    try {
      Provider.of<AdminAnalyticsProvider>(context, listen: false);
      Provider.of<AttendanceProvider>(context, listen: false);
      
      // If we get here, the providers are available, so we can directly return the dashboard
      return AdminDashboard(
        groupId: _effectiveGroupId,
        groupName: _effectiveGroupName,
      );
    } catch (e) {
      // If providers are not available, wrap the dashboard with the required providers
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