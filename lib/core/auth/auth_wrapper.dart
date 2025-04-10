import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/features/admin/admin_dashboard_wrapper.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/features/user/dashboard.dart';
import 'package:group_management_church_app/features/user/no_group_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import '../../features/admin/Admin_dashboard.dart';
import '../../features/super_admin/dashboard_cleaned.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthServices _authServices = AuthServices();
  final UserServices _userServices = UserServices();
  bool _isLoading = true;
  String? _error;
  
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
      
      // Check if profile is incomplete (name is empty)
      if (user.fullName.isEmpty) {
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
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
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
    
    // User is authenticated, check role and navigate accordingly
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }
    
    // Navigate based on role (role is already normalized to lowercase in UserModel)
    print('Navigating based on user role: ${user.role}');
    
    // Use a StatelessWidget to avoid state updates during build
    return _RoleBasedNavigator(user: user);
  }
}

// Separate widget to handle role-based navigation


class _RoleBasedNavigator extends StatelessWidget {
  final UserModel user;

  const _RoleBasedNavigator({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log('User role: ${user.role}');
    
    // Use FutureBuilder to handle the async operations
    return FutureBuilder<String>(
      future: _getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final String userId = snapshot.data ?? '';
        log('User ID: $userId');
        
        switch (user.role) {
          case 'super_admin':
            log('Navigating to SuperAdminDashboard');
            return const SuperAdminDashboard();
    
          case 'admin':
            // Use user.id instead of userId from SharedPreferences for admin
            // This ensures we're using the ID from the UserModel which should be valid
            log('Fetching groups for admin with ID: $userId');
            
            // Check if user.id is empty
            if (userId.isEmpty) {
              log('Admin ID is empty, using default group');
              return const AdminDashboard(
                groupId: 'default',
                groupName: 'Default Group',
              );
            }
            
            return FutureBuilder<List<GroupModel>>(
              future: Provider.of<GroupProvider>(context, listen: false)
                  .getGroupsByAdmin(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  log('Admin group fetch in progress...');
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
    
                if (snapshot.hasError) {
                  log('Error fetching admin groups: ${snapshot.error}');
                  return const AdminDashboardWrapper(
                    groupId: 'default',
                    groupName: 'Default Group',
                  );
                }
    
                final adminGroups = snapshot.data ?? [];
                log('Admin groups fetched: ${adminGroups.length} groups found');
    
                if (adminGroups.isEmpty) {
                  log('No groups found for admin');
                  return const AdminDashboardWrapper(
                    groupId: 'default',
                    groupName: 'Default Group',
                  );
                }
    
                log('Navigating to AdminDashboard with group ID: ${adminGroups.first.id}');
                return AdminDashboardWrapper(
                  groupId: adminGroups.first.id,
                  groupName: adminGroups.first.name,
                );
              },
            );
    
          case 'user':
            // Use user.id from UserModel instead of userId from SharedPreferences
            // This ensures we're using the ID from the UserModel which should be valid
            log('Fetching groups for user with ID: $userId');
            
            // Check if user.id is empty
            if (userId.isEmpty) {
              log('User ID is empty, cannot fetch groups');
              return const NoGroupScreen();
            }
            
            return FutureBuilder<List<GroupModel>>(
              future: Provider.of<GroupProvider>(context, listen: false)
                  .fetchUserMemberships(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  log('User group fetch in progress...');
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
    
                if (snapshot.hasError) {
                  log('Error fetching user groups: ${snapshot.error}');
                  // Show NoGroupScreen instead of default dashboard when there's an error
                  return const NoGroupScreen();
                }
    
                final userGroups = snapshot.data ?? [];
                log('User groups fetched: ${userGroups.length} group(s) found');
    
                if (userGroups.isEmpty) {
                  log('No groups found for user');
                  return const NoGroupScreen();
                }
    
                log('Navigating to UserDashboard with group ID: ${userGroups.first.id}');
                return UserDashboard(groupId: userGroups.first.id);
              },
            );
    
          default:
            log('Unknown role: ${user.role}, navigating to default UserDashboard');
            return const UserDashboard(groupId: 'default');
        }
      },
    );
  }
  
  // Helper method to get user ID asynchronously
  Future<String> _getUserId() async {
    // Use the same key as AuthServices
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }
}
