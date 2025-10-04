import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/super_admin/group_administration_tab.dart';
import 'package:group_management_church_app/features/super_admin/region_management_tab.dart';
import 'package:group_management_church_app/features/super_admin/screens/analytics_screen.dart';
import 'package:group_management_church_app/features/super_admin/user_management_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_details_screen.dart';
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
import '../../data/providers/region_provider.dart';
import '../../data/services/event_services.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:flutter/foundation.dart';

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
            _dashboardSummary = _analyticsProvider.dashboardSummary!.toMap();
            print('Dashboard summary loaded successfully');
            _isLoading = false;  // Clear loading state after data is loaded
          } else {
            _errorMessage = 'Dashboard data is not available';
            print('Dashboard summary is null');
            _isLoading = false;  // Clear loading state even if data is not available
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
          _buildRegionManagerTab(),
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
            icon: Icon(Icons.map),
            label: 'Regions',
          ),
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

  // REGION MANAGER TAB
  Widget _buildRegionManagerTab() {
    return RegionManagementTab();
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
          ],
        ),
      ),
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
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _showError(String message) {
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
}
