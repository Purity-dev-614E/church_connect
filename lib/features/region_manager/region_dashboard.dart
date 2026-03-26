import 'package:flutter/material.dart';
import 'dart:core';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/models/regional_analytics_model.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/data/services/analytics_services/regional_manager_analytics_service.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/region_manager/group_details_screen.dart';
import 'package:group_management_church_app/features/region_manager/region_user_management_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_group_administration_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_events_tab.dart';
import 'package:group_management_church_app/features/region_manager/screens/analytics_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/more_options_screen.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/features/super_admin/dashboard_cleaned.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import '../../data/models/event_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/region_provider.dart';
import '../../data/services/event_services.dart';
import 'package:flutter/foundation.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import '../../data/services/group_activity_service.dart';
import '../../data/providers/analytics_providers/regional_manager_analytics_provider.dart';

class RegionDashboard extends StatefulWidget {
  final String regionId;
  final bool actingAsSuperAdmin;
  final int initialTabIndex;

  const RegionDashboard({
    super.key,
    required this.regionId,
    this.actingAsSuperAdmin = false,
    this.initialTabIndex = 0,
  });

  @override
  State<RegionDashboard> createState() => _RegionDashboardState();
}

class _RegionDashboardState extends State<RegionDashboard> {
  int _selectedIndex = 0;

  // Data from providers
  late RegionAnalyticsService _analyticsServices;
  late EventServices _eventServices;
  List<UserModel> _regionUsers = [];
  List<GroupModel> _regionGroups = [];
  List<EventModel> _upcomingEvents = [];
  DashboardSummary? _dashboardSummary;
  RegionModel? _region;
  bool _isLoading = true;
  String? _errorMessage;

  // Removed members data
  List<RemovedMemberModel> _removedMembers = [];
  bool _isLoadingRemovedMembers = false;

  // Settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  final String _selectedDateRange = 'Last 6 Months';
  final List<String> _availableDateRanges = [
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
  ];

  // Export options
  final List<String> _exportFormats = ['CSV', 'PDF', 'Excel'];
  String _selectedExportFormat = 'CSV';

  // Chart data
  List<FlSpot> _attendanceSpots = [];
  List<String> _attendanceLabels = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    try {
      _analyticsServices = RegionAnalyticsService(
        baseUrl: 'https://safari-backend-fgl3.onrender.com/api',
      );
      _eventServices = EventServices();

      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() {
        _checkAuthAndLoadData();
      });
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _errorMessage = 'Failed to initialize dashboard services';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      final authServices = AuthServices();
      final isLoggedIn = await authServices.isLoggedIn();

      if (!isLoggedIn) {
        throw Exception('You must be logged in to access this dashboard');
      }

      // Get current user's role
      final userId = await authServices.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final userData = await UserServices().fetchCurrentUser(userId);

      if (userData == null) {
        throw Exception('User data not found');
      }

      // Load region data
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );
      _region = await regionProvider.getRegionById(widget.regionId);

      if (_region == null) {
        throw Exception('Region not found');
      }

      // Only load essential dashboard data initially
      await _loadDashboardSummary();

      // Set final loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Track which tabs have been loaded
  final Set<int> _loadedTabs = <int>{};

  Future<void> _loadDashboardSummary() async {
    // Load summary data for dashboard overview including correct analytics data
    await Future.wait([
      _loadRegionGroups(onlySummary: true),
      _loadRegionEvents(onlySummary: true),
      _loadRegionAnalytics(), // Load correct dashboard summary data on app start
    ]);
  }

  Future<void> _loadRegionUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getUsersByRegion(widget.regionId);

      if (mounted) {
        setState(() {
          _regionUsers = users;
        });
      }
    } catch (e) {
      print('Error loading region users: $e');
      // Continue without users data
    }
  }

  Future<void> _loadRegionGroups({bool onlySummary = false}) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groups = await groupProvider.getGroupsByRegion(widget.regionId);

      if (mounted) {
        setState(() {
          _regionGroups = groups;
        });
      }
    } catch (e) {
      print('Error loading region groups: $e');
      // Continue without groups data
    }
  }

  Future<void> _loadRegionEvents({bool onlySummary = false}) async {
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      // Use fetchAllEvents to include both regular and leadership events
      await eventProvider.fetchAllEvents();
      final events =
          eventProvider.events
              .where(
                (event) =>
                    // Include regular events from this region OR leadership events targeting this region
                    (event.groupId != null && event.groupId!.isNotEmpty) ||
                    (event.isLeadershipEvent &&
                        event.regionalId == widget.regionId),
              )
              .toList();

      if (mounted) {
        setState(() {
          _upcomingEvents = events;
        });
      }
    } catch (e) {
      print('Error loading region events: $e');
      // Continue without events data
    }
  }

  Future<void> _loadRegionAnalytics() async {
    print('=== Starting _loadRegionAnalytics ===');
    try {
      // Load region dashboard summary
      final summary = await _analyticsServices.getDashboardSummaryForRegion(
        widget.regionId,
      );

      print('Dashboard API call completed. Summary: $summary');

      if (mounted) {
        setState(() {
          _dashboardSummary = summary;
        });
      }
    } catch (e) {
      print('Error loading region analytics: $e');
      // Continue without analytics data
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // More tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MoreOptionsScreen(
                userRole: 'regional_manager',
                regionId: widget.regionId,
                actingAsSuperAdmin: widget.actingAsSuperAdmin,
              ),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _showError(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  void _showSuccess(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.success,
    );
  }

  void _showInfo(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _region?.name ?? 'Region Dashboard',
        showBackButton:
            widget
                .actingAsSuperAdmin, // allow back when coming from Super Admin
        showProfileAvatar: !widget.actingAsSuperAdmin,
        onProfileTap: _navigateToProfile,
        actions:
            widget.actingAsSuperAdmin
                ? [
                  IconButton(
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                    ),
                    tooltip: 'Back to Super Admin',
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminDashboard(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ]
                : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          RegionUserManagementTab(regionId: widget.regionId),
          RegionGroupAdministrationTab(regionId: widget.regionId),
          RegionEventsTab(regionId: widget.regionId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Required for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
              onPressed: _checkAuthAndLoadData,
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
    }

    return RefreshIndicator(
      onRefresh: _checkAuthAndLoadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _buildSectionHeader('Region Groups', Icons.groups, () {
              _onItemTapped(2); // Navigate to Groups tab
            }),
            const SizedBox(height: 16),
            _buildRecentGroupsList(),
            const SizedBox(height: 24),
            // }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    // Get user name from UserProvider if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName =
        widget.actingAsSuperAdmin
            ? 'Super Admin'
            : (userProvider.currentUser?.fullName ?? 'Region Manager');

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
            colors: [AppColors.secondaryColor, AppColors.primaryColor],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 48),
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
                      if (widget.actingAsSuperAdmin)
                        Text(
                          'You are viewing ${_region?.name ?? 'this region'} as Super Admin',
                          style: TextStyles.bodyText.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )
                      else
                        Text(
                          'Manage ${_region?.name ?? 'your region'} from this dashboard',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  'Settings',
                  Icons.settings,
                  () => _onItemTapped(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyles.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    // Get data from dashboard summary, with fallbacks only if summary is null or has null values
    final userCount = _dashboardSummary?.userCount;
    final groupCount = _dashboardSummary?.groupCount;
    final eventCount = _dashboardSummary?.eventCount;

    // Use backend data if available and valid, otherwise use local data as fallback
    String totalUsers =
        (userCount != null && userCount > 0)
            ? userCount.toString()
            : _regionUsers.length.toString();
    String totalGroups =
        (groupCount != null && groupCount > 0)
            ? groupCount.toString()
            : _regionGroups.length.toString();
    String activeEvents =
        (eventCount != null && eventCount > 0)
            ? eventCount.toString()
            : _upcomingEvents.length.toString();

    // Format attendance rate with percentage
    final attendanceRate = _dashboardSummary?.attendanceCount ?? 0;
    String formattedAttendance =
        '${(attendanceRate / 100).toStringAsFixed(1)}%';

    // Use calculated values if available, otherwise use defaults and trigger calculation
    String activeGroups = _calculatedActiveGroups ?? '0';
    String inactiveGroups = _calculatedInactiveGroups ?? '0';

    // Trigger calculation on first build if not already calculated
    if (_calculatedActiveGroups == null &&
        _calculatedInactiveGroups == null &&
        !_isCalculatingActivity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateGroupActivityStats();
      });
    }

    return GridView.count(
      crossAxisCount: 3,
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
          'Active Events',
          activeEvents,
          Icons.event,
          AppColors.accentColor,
        ),
        _buildStatCard(
          'Attendance',
          formattedAttendance,
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Active Groups',
          activeGroups,
          Icons.group_work,
          Colors.blue,
        ),
        _buildStatCard(
          'Inactive Groups',
          inactiveGroups,
          Icons.group_off,
          Colors.red,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
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
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Store calculated values
  String? _calculatedActiveGroups;
  String? _calculatedInactiveGroups;
  bool _isCalculatingActivity = false;

  Future<void> _calculateGroupActivityStats() async {
    if (_isCalculatingActivity) return;

    _isCalculatingActivity = true;

    try {
      // Use the same approach as super admin - check each group individually
      if (_regionGroups.isNotEmpty) {
        final groupActivityService = GroupActivityService();
        int activeCount = 0;
        int inactiveCount = 0;

        // Check activity status for all groups in this region
        for (final group in _regionGroups) {
          try {
            final isInactive = await groupActivityService.isGroupInactive(
              group.id,
            );
            if (isInactive) {
              inactiveCount++;
            } else {
              activeCount++;
            }
          } catch (e) {
            // Default to inactive if there's an error
            inactiveCount++;
          }
        }

        if (mounted) {
          setState(() {
            _calculatedActiveGroups = activeCount.toString();
            _calculatedInactiveGroups = inactiveCount.toString();
          });
        }
      } else {
        // No groups available for this region
        if (mounted) {
          setState(() {
            _calculatedActiveGroups = '0';
            _calculatedInactiveGroups = '0';
          });
        }
      }
    } catch (e) {
      // Error occurred - show zeros instead of placeholder values
      if (mounted) {
        setState(() {
          _calculatedActiveGroups = '0';
          _calculatedInactiveGroups = '0';
        });
      }
      print('Error calculating group activity for region: $e');
    } finally {
      _isCalculatingActivity = false;
    }
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
        TextButton(
          onPressed: onViewAll,
          child: Row(
            children: [
              Text(
                'View All',
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    if (_regionUsers.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users in this region yet',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _onItemTapped(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Add Users'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show only the first 5 users
    final displayUsers =
        _regionUsers.length > 5 ? _regionUsers.sublist(0, 5) : _regionUsers;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayUsers.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final user = displayUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryColor.withOpacity(0.2),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to user details
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentGroupsList() {
    if (_regionGroups.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No groups in this region yet',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayGroups =
        _regionGroups.length > 5 ? _regionGroups.sublist(0, 5) : _regionGroups;

    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayGroups.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final group = displayGroups[index];
              return Container(
                key: ValueKey('region_group_${group.id}'),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
                    child: Icon(Icons.groups, color: AppColors.secondaryColor),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => GroupDetailsScreen(
                              groupId: group.id,
                              groupName: group.name,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();

        return AlertDialog(
          title: const Text('Create New Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupProvider = Provider.of<GroupProvider>(
                  context,
                  listen: false,
                );
                final success = await groupProvider.createGroup(
                  nameController.text,
                  descriptionController.text,
                  'adminId', // Replace with actual adminId
                  widget.regionId,
                );

                if (success) {
                  _showSuccess('Group created successfully');
                } else {
                  _showError('Failed to create group');
                }

                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadRemovedMembers() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRemovedMembers = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final removedMembers = await groupProvider.getRemovedMembersByRegion(
        widget.regionId,
      );

      if (!mounted) return;
      setState(() {
        _removedMembers = removedMembers;
        _isLoadingRemovedMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removedMembers = [];
        _isLoadingRemovedMembers = false;
      });
      _showError('Failed to load removed members: $e');
    }
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    return RegionManagerAnalyticsScreen(regionId: widget.regionId);
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
            'Customize your region dashboard experience',
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
                    subtitle: const Text('Receive updates about your region'),
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
                    title: const Text('Region'),
                    subtitle: Text(_region?.name ?? 'Unknown Region'),
                    leading: const Icon(Icons.location_on),
                  ),
                  const Divider(),
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
}
