import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/features/admin/admin_dashboard_wrapper.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/features/region_manager/region_dashboard.dart';
import 'package:group_management_church_app/features/user/dashboard.dart';
import 'package:group_management_church_app/features/user/no_group_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import '../../features/admin/Admin_dashboard.dart';
import '../../features/super_admin/dashboard_cleaned.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthServices _authServices = AuthServices();
  final UserServices _userServices = UserServices();
  bool _isLoading = true;
  String? _error;
  UserModel? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }
  
  Future<void> _checkAuthAndNavigate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Check if user is logged in
      final bool isLoggedIn = await _authServices.isLoggedIn();
      
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
        });
        return; // Will show login screen
      }
      
      // Get user ID
      final String? userId = await _authServices.getUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'User ID not found';
        });
        return;
      }
      
      // Load user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser(userId);
      
      // Check if user has completed profile setup
      final UserModel? user = userProvider.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load user data';
        });
        return;
      }

      log('User Name: ${user.fullName}');
      
      // Check if profile is incomplete (name is empty)
      if (user.fullName.isEmpty || user.fullName == '') {
        // Navigate to profile setup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(
                userId: userId,
                email: user.email,
              ),
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isLoading = false;
        _currentUser = user;
      });
      
    } catch (e) {
      log('Error in _checkAuthAndNavigate: $e');
      setState(() {
        _isLoading = false;
        _error = 'An error occurred: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking auth status
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show error if any
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAuthAndNavigate,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Check authentication status from provider
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.status != AuthStatus.authenticated) {
      return const LoginScreen();
    }
    
    // If we have a current user, show the appropriate dashboard
    if (_currentUser != null) {
      return _RoleBasedNavigator(user: _currentUser!);
    }
    
    // Default to login screen if no user is found
    return const LoginScreen();
  }
}

class _RoleBasedNavigator extends StatelessWidget {
  final UserModel user;

  const _RoleBasedNavigator({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    log('User role: ${user.role}');
    
    switch (user.role.toLowerCase()) {
      case 'super_admin':
        log('Navigating to SuperAdminDashboard');
        return const SuperAdminDashboard();
      
      case 'regional manager':
        log('Navigating to RegionDashboard');
        
        // Check if user has a region assigned
        if (user.regionId.isEmpty) {
          log('Region manager has no region assigned');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'No Region Assigned',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have been assigned as a Region Manager but no region has been assigned to you yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return RegionDashboard(regionId: user.regionId);

      case 'admin':
        log('Navigating to AdminDashboard');
        return const AdminDashboardWrapper(
          groupId: 'default',
          groupName: 'Default Group',
        );

      case 'user':
        log('Navigating to UserDashboard');
        return const UserDashboard(groupId: 'default');

      default:
        log('Unknown role: ${user.role}, navigating to default UserDashboard');
        return const UserDashboard(groupId: 'default');
    }
  }
}
