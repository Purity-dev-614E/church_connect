import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/features/admin/Admin_dashboard.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/features/super_admin/dashboard.dart';
import 'package:group_management_church_app/features/user/dashboard.dart';
import 'package:group_management_church_app/features/user/no_group_screen.dart';
import 'package:provider/provider.dart';

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
    switch (user.role) {
      case 'super_admin':
        return const SuperAdminDashboard();
      case 'admin':
        // For admin, we'll check if they have any groups they administer
        return FutureBuilder<List<GroupModel>>(
          future: Provider.of<GroupProvider>(context, listen: false)
              .getGroupsByAdmin(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const AdminDashboard(
                groupId: 'default', 
                groupName: 'Default Group'
              );
            }
            
            final adminGroups = snapshot.data!;
            if (adminGroups.isEmpty) {
              return const AdminDashboard(
                groupId: 'default', 
                groupName: 'Default Group'
              );
            }
            
            // Use the first group the admin manages
            return AdminDashboard(
              groupId: adminGroups.first.id, 
              groupName: adminGroups.first.name
            );
          },
        );
        
      case 'user':
        // Only regular users need to be assigned to a group
        // For regular users, check if they belong to any group
        return FutureBuilder<List<GroupModel>>(
          future: Provider.of<GroupProvider>(context, listen: false)
              .getUserGroups(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              print('Error loading user groups: ${snapshot.error}');
              // If there's an error, we'll still try to show the dashboard with a default group
              return const UserDashboard(groupId: 'default');
            }
            
            final userGroups = snapshot.data ?? [];
            
            // If user doesn't belong to any group, show the no group screen
            if (userGroups.isEmpty) {
              return const NoGroupScreen();
            }
            
            // Use the first group the user belongs to
            return UserDashboard(groupId: userGroups.first.id);
          },
        );
        
      default:
        // For any other role, just go to user dashboard with default group
        return const UserDashboard(groupId: 'default');
    }
  }
}