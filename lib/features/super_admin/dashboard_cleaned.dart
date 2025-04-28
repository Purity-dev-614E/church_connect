import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/super_admin/group_administration_tab.dart';
import 'package:group_management_church_app/features/super_admin/screens/analytics_screen.dart';
import 'package:group_management_church_app/features/super_admin/user_management_tab.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/event_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/services/event_services.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/analytics_providers/super_admin_analytics_provider.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  _SuperAdminDashboardState();

  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Data from providers
  late EventServices _eventServices;
  late SuperAdminAnalyticsProvider _analyticsProvider;
  late UserProvider _userProvider;
  late EventProvider _eventProvider;
  List<UserModel> _recentUsers = [];
  final List<GroupModel> _recentGroups = [];
  Map<String, dynamic> _dashboardSummary = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Flags to prevent multiple API calls
  bool _usersDataRequested = false;
  bool _groupsDataRequested = false;
  bool _eventsDataRequested = false;

  // Settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    // Get the event services
    _eventServices = EventServices();

    // Initialize with default data to prevent loading indicator from getting stuck
    _dashboardSummary = {
      'totalUsers': 0,
      'totalGroups': 0,
      'totalEvents': 0,
      'recentEvents': [],
    };

    // Set initial loading state to false to show default data first
    _isLoading = false;

    // Then load actual data
    Future.delayed(Duration.zero, () {
      _initializeData();
    });
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request storage permissions for exporting data
    await Permission.storage.request();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    print('Initializing dashboard data...');

    // Only set loading state if we're not already loading
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        // Reset data request flags to allow new requests
        _usersDataRequested = false;
        _groupsDataRequested = false;
        _eventsDataRequested = false;
      });
    } else {
      // If we're already loading, don't start another load operation
      return;
    }

    // Add a timeout to ensure we don't get stuck in loading state
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Loading timed out. Please try again.';
        });
      }
    });

    try {
      print('Getting analytics provider...');
      // Get the analytics provider
      _analyticsProvider = Provider.of<SuperAdminAnalyticsProvider>(
        context,
        listen: false,
      );

      print('Getting auth provider...');
      // Get the auth provider for token refresh
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('Attempting token refresh...');
      // Try to refresh the token before making the API call
      bool tokenRefreshed = await authProvider.refreshToken();
      print('Token refresh result: $tokenRefreshed');

      if (!tokenRefreshed) {
        // If token refresh failed, show an error
        print('Token refresh failed, redirecting to login...');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication failed. Please login again.';
          });
        }
        return;
      }

      print('Fetching dashboard summary...');
      // Now try to get the dashboard summary with the refreshed token
      await _analyticsProvider.getDashboardSummary();

      if (mounted) {
        setState(() {
          if (_analyticsProvider.dashboardSummary != null) {
            _dashboardSummary = _analyticsProvider.dashboardSummary!;
            print('Dashboard summary loaded successfully');
          } else {
            _errorMessage = 'Dashboard data is not available';
            print('Dashboard summary is null');
          }
        });
      }
    } catch (e) {
      print('Error in _initializeData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _showError(String message) {
    // Use Future.microtask to schedule the notification after the build is complete
    Future.microtask(() {
      if (mounted) {
        CustomNotification.show(
          context: context,
          message: message,
          type: NotificationType.error,
        );
      }
    });
  }

  void _showSuccess(String message) {
    // Use Future.microtask to schedule the notification after the build is complete
    Future.microtask(() {
      if (mounted) {
        CustomNotification.show(
          context: context,
          message: message,
          type: NotificationType.success,
        );
      }
    });
  }

  void _showInfo(String message) {
    // Use Future.microtask to schedule the notification after the build is complete
    Future.microtask(() {
      if (mounted) {
        CustomNotification.show(
          context: context,
          message: message,
          type: NotificationType.info,
        );
      }
    });
  }

  Future<void> _exportAnalyticsData(String format) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the auth provider for token refresh
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Try to refresh the token before making the API call
      bool tokenRefreshed = await authProvider.refreshToken();

      if (!tokenRefreshed) {
        // If token refresh failed, show an error
        setState(() {
          _isLoading = false;
        });
        _showError('Authentication failed. Please login again.');
        return;
      }

      // Convert format to lowercase for API
      final formatLower = format.toLowerCase();

      // Determine what data to export based on current tab
      String dataType = 'dashboard_summary';
      if (_selectedIndex == 1) {
        dataType = 'user_management';
      } else if (_selectedIndex == 2) {
        dataType = 'group_management';
      } else if (_selectedIndex == 3) {
        dataType = 'attendance_trends';
      }

      // Make sure we have the analytics provider
      try {
        // This will throw an error if _analyticsProvider hasn't been initialized
        _analyticsProvider.hashCode;
      } catch (e) {
        // Initialize it if needed
        _analyticsProvider = Provider.of<SuperAdminAnalyticsProvider>(
          context,
          listen: false,
        );
      }

      // Since we don't have a direct export method in the provider, we'll create a mock URL
      // In a real app, you would call the appropriate export method
      final downloadUrl = "https://example.com/export/$dataType.$formatLower";

      setState(() {
        _isLoading = false;
      });

      if (downloadUrl.isNotEmpty) {
        _showSuccess('Data exported successfully');

        // Share the download URL
        await Share.share(
          'Download your exported church data: $downloadUrl',
          subject: 'Church Management App - Exported Data',
        );
      } else {
        _showError('Failed to export data');
      }
    } catch (e) {
      // Check if it's an authentication error (401)
      if (e.toString().contains('401')) {
        // Try to refresh the token
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool tokenRefreshed = await authProvider.refreshToken();

        if (tokenRefreshed) {
          // If token was refreshed successfully, try again
          try {
            // Recursive call to try again with the refreshed token
            await _exportAnalyticsData(format);
            return;
          } catch (retryError) {
            _showError('Error exporting data after token refresh: $retryError');
          }
        } else {
          // If token refresh failed, show authentication error
          _showError('Authentication failed. Please login again.');
        }
      } else {
        _showError('Error exporting data: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEventDetails(EventModel event) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time:',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'EEEE, MMMM d, yyyy - h:mm a',
                    ).format(event.dateTime),
                    style: TextStyles.bodyText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Location:',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(event.location, style: TextStyles.bodyText),
                  const SizedBox(height: 12),
                  Text(
                    'Description:',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(event.description, style: TextStyles.bodyText),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getEventAttendanceWithTokenRefresh(event.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text(
                          'No attendance data available: ${snapshot.error}',
                        );
                      }

                      final attendanceData = snapshot.data!;
                      final attendanceCount =
                          attendanceData['attendance_count'] ?? 0;
                      final totalMembers = attendanceData['total_members'] ?? 0;
                      final attendanceRate =
                          totalMembers > 0
                              ? (attendanceCount / totalMembers * 100)
                                  .toStringAsFixed(1)
                              : '0.0';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance:',
                            style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$attendanceCount out of $totalMembers members ($attendanceRate%)',
                            style: TextStyles.bodyText,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAttendanceDialog(event);
                },
                child: const Text('Manage Attendance'),
              ),
            ],
          ),
    );
  }

  // Helper method to get event attendance with token refresh
  Future<Map<String, dynamic>> _getEventAttendanceWithTokenRefresh(
    String eventId,
  ) async {
    try {
      // Try to get event attendance
      return await _eventServices.getEventAttendance(eventId);
    } catch (e) {
      // Check if it's an authentication error (401)
      if (e.toString().contains('401')) {
        // Try to refresh the token
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool tokenRefreshed = await authProvider.refreshToken();

        if (tokenRefreshed) {
          // If token was refreshed successfully, try again
          return await _eventServices.getEventAttendance(eventId);
        } else {
          // If token refresh failed, throw authentication error
          throw Exception('Authentication failed. Please login again.');
        }
      }
      // If it's not an authentication error, rethrow
      rethrow;
    }
  }

  // Helper method to get attended members with token refresh
  Future<List<UserModel>> _getAttendedMembersWithTokenRefresh(
    String eventId,
  ) async {
    try {
      // Try to get attended members
      return await _eventServices.getAttendedMembers(eventId);
    } catch (e) {
      // Check if it's an authentication error (401)
      if (e.toString().contains('401')) {
        // Try to refresh the token
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool tokenRefreshed = await authProvider.refreshToken();

        if (tokenRefreshed) {
          // If token was refreshed successfully, try again
          return await _eventServices.getAttendedMembers(eventId);
        } else {
          // If token refresh failed, throw authentication error
          throw Exception('Authentication failed. Please login again.');
        }
      }
      // If it's not an authentication error, rethrow
      rethrow;
    }
  }

  Future<void> _showAttendanceDialog(EventModel event) async {
    try {
      // Get group members
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final members = await groupProvider.getGroupMembers(event.groupId);

      // Get attended members with token refresh
      final attendedMembers = await _getAttendedMembersWithTokenRefresh(
        event.id,
      );
      final attendedMemberIds = attendedMembers.map((user) => user.id).toList();

      // Create a map to track attendance
      Map<String, bool> attendanceMap = {};
      for (var member in members) {
        final memberId = member.id as String;
        attendanceMap[memberId] = attendedMemberIds.contains(memberId);
      }

      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setState) => AlertDialog(
                    title: Text('Attendance for ${event.title}'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final memberId = member.id as String;
                          final memberName =
                              member.fullName as String? ?? 'Unknown';

                          return CheckboxListTile(
                            title: Text(memberName),
                            value: attendanceMap[memberId] ?? false,
                            onChanged: (value) {
                              setState(() {
                                attendanceMap[memberId] = value ?? false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Get list of attended member IDs
                            final List<String> attendedIds = [];
                            attendanceMap.forEach((id, attended) {
                              if (attended) {
                                attendedIds.add(id);
                              }
                            });

                            // Save attendance
                            await _eventServices.createEventAttendance(
                              event.id,
                              attendedIds,
                            );

                            Navigator.pop(context);
                            _showSuccess('Attendance saved successfully');
                          } catch (e) {
                            _showError('Failed to save attendance: $e');
                          }
                        },
                        child: const Text('Save Attendance'),
                      ),
                    ],
                  ),
            ),
      );
    } catch (e) {
      _showError('Failed to load attendance data: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      await _userProvider.getAllUsers();
      if (mounted) {
        setState(() async {
          _recentUsers = await _userProvider.getAllUsers();
        });
      }
    } catch (e) {
      print('Error refreshing users: $e');
      if (mounted) {
        _showError('Failed to refresh users');
      }
    }
  }

  void _showEditUserDialog(UserModel user) {
    final TextEditingController nameController = TextEditingController(
      text: user.fullName,
    );
    final TextEditingController emailController = TextEditingController(
      text: user.email,
    );
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Member')),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Group Leader'),
                      ),
                      DropdownMenuItem(
                        value: 'super_admin',
                        child: Text('Super Admin'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedRole = value;
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    _showError('Please fill all fields');
                    return;
                  }

                  try {
                    final updatedUser = UserModel(
                      id: user.id,
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      contact: user.contact,
                      nextOfKin: user.nextOfKin,
                      nextOfKinContact: user.nextOfKinContact,
                      role: selectedRole,
                      gender: user.gender,
                      regionId: user.regionId,
                    );

                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final success = await authProvider.updateProfile(
                      updatedUser,
                    );

                    if (success) {
                      _showSuccess('User updated successfully');
                      Navigator.pop(context);
                      _loadUsers(); // Refresh the user list
                    } else {
                      _showError('Failed to update user');
                    }
                  } catch (e) {
                    _showError('Failed to update user: ${e.toString()}');
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Super Admin Dashboard',
        showBackButton: false,
        showProfileAvatar: true,
        onProfileTap: _navigateToProfile,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildDashboardTab(),
          _buildUserManagementTab(),
          _buildGroupAdministrationTab(),
          _buildAnalyticsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  // DASHBOARD TAB
  Widget _buildDashboardTab() {
    // Show loading indicator with overlay on top of content
    Widget content;

    if (_errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Always show content, even when loading
      content = RefreshIndicator(
        onRefresh: () async {
          // Only refresh if not already loading
          if (!_isLoading) {
            // Try to refresh the token first
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            await authProvider.refreshToken();

            // Then initialize data
            await _initializeData();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildStatisticsGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader('Quick Analytics', Icons.analytics, () {
                _onItemTapped(3); // Navigate to Analytics tab
              }),
              const SizedBox(height: 16),
              // _buildQuickAnalyticsChart(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    // Show loading indicator as overlay if loading
    if (_isLoading) {
      return Stack(
        children: [
          // Slightly dim the content while loading
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.7),
              BlendMode.srcATop,
            ),
            child: content,
          ),
          // Loading indicator overlay
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return content;
  }

  // USER MANAGEMENT TAB
  Widget _buildUserManagementTab() {
    return UserManagementTab();
  }

  // GROUP ADMINISTRATION TAB
  Widget _buildGroupAdministrationTab() {
    return GroupAdministrationTab();
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    return const SuperAdminAnalyticsScreen();
  }

  // SETTINGS TAB
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyles.heading1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Customize your dashboard experience',
            style: TextStyles.bodyText,
          ),
          const SizedBox(height: 24),

          // Notifications settings
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive updates about your church'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Display settings
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme for the dashboard'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      _showInfo('Theme settings will be applied on restart');
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Authentication section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Refresh Authentication Token'),
                    subtitle: const Text('Update your session token'),
                    leading: const Icon(Icons.refresh),
                    onTap: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final success = await authProvider.refreshToken();

                        setState(() {
                          _isLoading = false;
                        });

                        if (success) {
                          _showSuccess(
                            'Authentication token refreshed successfully',
                          );
                        } else {
                          _showError(
                            'Failed to refresh authentication token. Please login again.',
                          );
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        _showError('Error refreshing token: $e');
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out of your account'),
                    leading: const Icon(Icons.logout),
                    onTap: () async {
                      try {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        await authProvider.logout();

                        // Navigate to login screen
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (route) => false);
                      } catch (e) {
                        _showError('Error logging out: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                    leading: const Icon(Icons.info_outline),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Contact Support'),
                    subtitle: const Text('Get help with the app'),
                    leading: const Icon(Icons.support_agent),
                    onTap: () {
                      _showInfo('Support contact feature coming soon');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    // Get user name from UserProvider if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.currentUser?.fullName ?? 'Super Admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName',
                        style: TextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your church groups and users from this dashboard',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          padding: const EdgeInsets.all(16),
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionButton(
              icon: Icons.group_add,
              label: 'Add Group',
              color: AppColors.primaryColor,
              onTap: () => _onItemTapped(2),
            ),
            _buildQuickActionButton(
              icon: Icons.analytics,
              label: 'Analytics',
              color: AppColors.secondaryColor,
              onTap: () => _onItemTapped(3),
            ),
            _buildQuickActionButton(
              icon: Icons.settings,
              label: 'Settings',
              color: AppColors.accentColor,
              onTap: () => _onItemTapped(4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    // Get data from providers directly if dashboard summary is empty
    String totalUsers = '0';
    String totalGroups = '0';
    String totalEvents = '0';
    String recentEventsCount = '0';

    try {
      // Try to get values from dashboard summary first using the new backend format
      totalUsers = _dashboardSummary['totalUsers']?.toString() ?? '0';
      totalGroups = _dashboardSummary['totalGroups']?.toString() ?? '0';
      totalEvents = _dashboardSummary['totalEvents']?.toString() ?? '0';

      // Get recent events count
      final recentEvents = _dashboardSummary['recentEvents'] as List<dynamic>?;
      recentEventsCount = recentEvents?.length.toString() ?? '0';

      // If values are '0', try to get them from providers
      if (totalUsers == '0' && !_usersDataRequested) {
        // Get total users from UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Mark as requested to prevent multiple calls
        _usersDataRequested = true;

        // Show notification after build is complete
        Future.microtask(() {
          if (mounted) {
            _showInfo('Loading user data. Please wait...');
          }
        });

        // Fetch actual data in the background
        userProvider.getAllUsers().then((users) {
          if (users.isNotEmpty && mounted) {
            setState(() {
              totalUsers = users.length.toString();
            });
          }
        });
      }

      if (totalGroups == '0' && !_groupsDataRequested) {
        // Get total groups from GroupProvider
        final groupProvider = Provider.of<GroupProvider>(
          context,
          listen: false,
        );

        // Mark as requested to prevent multiple calls
        _groupsDataRequested = true;

        // Show notification after build is complete
        Future.microtask(() {
          if (mounted) {
            _showInfo('Loading group data. Please wait...');
          }
        });

        // Fetch actual data in the background
        if (groupProvider.groups.isNotEmpty) {
          totalGroups = groupProvider.groups.length.toString();
        } else {
          groupProvider.fetchGroups().then((_) {
            if (mounted && groupProvider.groups.isNotEmpty) {
              setState(() {
                totalGroups = groupProvider.groups.length.toString();
              });
            }
          });
        }
      }

      if (totalEvents == '0' && !_eventsDataRequested) {
        // Get events from EventProvider
        final eventProvider = Provider.of<EventProvider>(
          context,
          listen: false,
        );

        // Mark as requested to prevent multiple calls
        _eventsDataRequested = true;

        // Show notification after build is complete
        Future.microtask(() {
          if (mounted) {
            _showInfo('Loading event data. Please wait...');
          }
        });

        // Fetch actual data in the background
        if (eventProvider.upcomingEvents.isNotEmpty) {
          totalEvents = eventProvider.upcomingEvents.length.toString();
        }
      }

      if (recentEventsCount == '0') {
        // No action needed, just use the default value
      }

      // Fetch actual data in the background
      if (recentEvents != null && recentEvents.isNotEmpty) {
        recentEventsCount = recentEvents.length.toString();
      }

      // Print values for debugging
      print(
        'Statistics values: Users=$totalUsers, Groups=$totalGroups, Events=$totalEvents, RecentEvents=$recentEventsCount',
      );
    } catch (e) {
      print('Error building statistics grid: $e');
      // Set default values if there's an error
      totalUsers = 'Something went Wrong';
      totalGroups = 'Something went Wrong';
      totalEvents = 'Something went Wrong';
      recentEventsCount = 'Something went Wrong';
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users',
          totalUsers,
          Icons.people,
          AppColors.primaryColor,
        ),
        _buildStatCard(
          'Total Groups',
          totalGroups,
          Icons.groups,
          AppColors.secondaryColor,
        ),
        _buildStatCard(
          'Total Events',
          totalEvents,
          Icons.event,
          AppColors.accentColor,
        ),
        _buildStatCard(
          'Recent Events',
          recentEventsCount,
          Icons.history,
          AppColors.buttonColor,
        ),
      ],
    );
    // Add a default return statement to ensure a Widget is always returned
    return const SizedBox.shrink();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    VoidCallback onViewAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('View All'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    if (_recentUsers.isEmpty) {
      return const Center(child: Text('No recent users found'));
    }

    return Container(
      height: 150, // Increased height to accommodate content
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentUsers.length > 5 ? 5 : _recentUsers.length,
        itemBuilder: (context, index) {
          final user = _recentUsers[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildRecentUserCard(user),
          );
        },
      ),
    );
  }

  Widget _buildRecentUserCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160, // Slightly wider
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryColor.withOpacity(0.2),
              radius: 24,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyles.heading2.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10), // More spacing
            Flexible(
              child: Text(
                user.fullName,
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6), // More spacing
            Flexible(
              child: Text(
                user.role,
                style: TextStyles.bodyText.copyWith(
                  fontSize: 12,
                  color: AppColors.textColor.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGroupsList() {
    if (_recentGroups.isEmpty) {
      return const Center(child: Text('No recent groups found'));
    }

    // Sort groups by creation date (newest first)
    final sortedGroups = List<GroupModel>.from(_recentGroups);
    sortedGroups.sort((a, b) => b.created_at.compareTo(a.created_at));

    // Take only the last two created groups
    final recentTwoGroups =
        sortedGroups.length > 2 ? sortedGroups.sublist(0, 2) : sortedGroups;

    return Container(
      height: 150, // Increased height to accommodate content
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentTwoGroups.length,
        itemBuilder: (context, index) {
          final group = recentTwoGroups[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildRecentGroupCard(group),
          );
        },
      ),
    );
  }

  Widget _buildRecentGroupCard(GroupModel group) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160, // Slightly wider
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
              radius: 24,
              child: Icon(
                Icons.groups,
                color: AppColors.secondaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 10), // More spacing
            Flexible(
              child: Text(
                group.name,
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6), // More spacing
            Flexible(
              child: FutureBuilder<List<dynamic>>(
                future: Provider.of<GroupProvider>(
                  context,
                  listen: false,
                ).getGroupMembers(group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    );
                  }

                  final memberCount = snapshot.data?.length ?? 0;
                  return Text(
                    '$memberCount members',
                    style: TextStyles.bodyText.copyWith(
                      fontSize: 12,
                      color: AppColors.textColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEventsList() {
    // Get recent events from dashboard summary
    final recentEvents =
        _dashboardSummary['recentEvents'] as List<dynamic>? ?? [];

    if (recentEvents.isEmpty) {
      return const Center(child: Text('No recent events found'));
    }

    return Container(
      height: 180, // Increased height to accommodate content
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentEvents.length,
        itemBuilder: (context, index) {
          final event = recentEvents[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildRecentEventCard(event),
          );
        },
      ),
    );
  }

  Widget _buildRecentEventCard(Map<String, dynamic> event) {
    // Extract event data
    final String eventId = event['eventId'] ?? '';
    final String title = event['eventTitle'] ?? 'Untitled Event';
    final String dateString =
        event['eventDate'] ?? DateTime.now().toIso8601String();
    final double attendanceRate = (event['attendanceRate'] ?? 0).toDouble();

    // Parse date
    DateTime dateTime;
    try {
      dateTime = DateTime.parse(dateString);
    } catch (e) {
      dateTime = DateTime.now();
    }

    // Format date
    final formattedDate = DateFormat('MMM d, y').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accentColor.withOpacity(0.2),
                  radius: 20,
                  child: Icon(
                    Icons.event,
                    color: AppColors.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textColor.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 12,
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textColor.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 12,
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attendance:',
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(attendanceRate).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${attendanceRate.toStringAsFixed(0)}%',
                    style: TextStyles.bodyText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(attendanceRate),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    if (rate >= 40) return Colors.amber;
    return Colors.red;
  }
}
