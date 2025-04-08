import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/super_admin/group_administration_tab.dart';
import 'package:group_management_church_app/features/super_admin/user_management_tab.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/dashboard_analytics_provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/event_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/services/event_services.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Data from providers
  late DashboardAnalyticsProvider _analyticsProvider;
  List<UserModel> _recentUsers = [];
  List<GroupModel> _recentGroups = [];
  Map<String, dynamic> _dashboardSummary = {};
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Get the provider outside of build
    _analyticsProvider = Provider.of<DashboardAnalyticsProvider>(context, listen: false);

    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch data separately to handle errors more gracefully
      try {
        await _analyticsProvider.fetchRecentMembers();
        if (mounted) {
          setState(() {
            _recentUsers = _analyticsProvider.recentMembers;
          });
        }
      } catch (e) {
        print('Error fetching recent members: $e');
      }

      try {
        await _analyticsProvider.fetchRecentGroups();
        if (mounted) {
          setState(() {
            _recentGroups = _analyticsProvider.recentGroups;
          });
        }
      } catch (e) {
        print('Error fetching recent groups: $e');
      }

      try {
        await _analyticsProvider.fetchDashboardSummary();
        if (mounted) {
          setState(() {
            _dashboardSummary = _analyticsProvider.dashboardSummary;
          });
        }
      } catch (e) {
        print('Error fetching dashboard summary: $e');
      }

      try {
        await _analyticsProvider.fetchAttendanceTrends();
        if (mounted) {
          setState(() {
            _attendanceTrends = _analyticsProvider.attendanceTrends;
          });
        }
      } catch (e) {
        print('Error fetching attendance trends: $e');
      }

      try {
        await _analyticsProvider.fetchGroupGrowthTrends();
        if (mounted) {
          setState(() {
            _groupGrowthTrends = _analyticsProvider.groupGrowthTrends;
          });
        }
      } catch (e) {
        print('Error fetching group growth trends: $e');
      }

      // Set final loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _analyticsProvider.errorMessage;
        });
      }
    } catch (e) {
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
        type: BottomNavigationBarType.fixed, // Required for more than 3 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader('Recent Users', Icons.people, () {
              _onItemTapped(1); // Navigate to Users tab
            }),
            const SizedBox(height: 16),
            _buildRecentUsersList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Recent Groups', Icons.groups, () {
              _onItemTapped(2); // Navigate to Groups tab
            }),
            const SizedBox(height: 16),
            _buildRecentGroupsList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Quick Analytics', Icons.analytics, () {
              _onItemTapped(3); // Navigate to Analytics tab
            }),
            const SizedBox(height: 16),
            _buildQuickAnalyticsChart(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    // Get user name from UserProvider if available
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.currentUser?.fullName ?? 'Super Admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor,
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  'Add User',
                  Icons.person_add,
                  () => _onItemTapped(1),
                ),
                _buildQuickActionButton(
                  'Add Group',
                  Icons.group_add,
                  () => _onItemTapped(2),
                ),
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

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap) {
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
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
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
    // Get data from providers directly if dashboard summary is empty
    String totalUsers = '0';
    String totalGroups = '0';
    String activeEvents = '0';
    String formattedAttendance = '0.0%';

    try {
      // Try to get values from dashboard summary first
      totalUsers = _dashboardSummary['total_users']?.toString() ?? '0';
      totalGroups = _dashboardSummary['total_groups']?.toString() ?? '0';
      activeEvents = _dashboardSummary['active_events']?.toString() ?? '0';

      // Format attendance rate with percentage
      final attendanceRate = _dashboardSummary['overall_attendance_rate'] ?? 0.0;
      formattedAttendance = '${attendanceRate.toStringAsFixed(1)}%';

      // If all values are '0', try to get them from providers
      if (totalUsers == '0' && totalGroups == '0' && activeEvents == '0') {
        // Get total users from UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.getAllUsers().then((users) {
          if (users.isNotEmpty && mounted) {
            setState(() {
              totalUsers = users.length.toString();
            });
          }
        });

        // Get total groups from GroupProvider
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        if (groupProvider.groups.isNotEmpty) {
          totalGroups = groupProvider.groups.length.toString();
        } else {
          // If groups list is empty, try to fetch groups
          groupProvider.fetchGroups().then((_) {
            if (mounted && groupProvider.groups.isNotEmpty) {
              setState(() {
                totalGroups = groupProvider.groups.length.toString();
              });
            }
          });
        }

        // Get active events from EventProvider
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        if (eventProvider.upcomingEvents.isNotEmpty) {
          activeEvents = eventProvider.upcomingEvents.length.toString();
        }
      }
    } catch (e) {
      print('Error building statistics grid: $e');
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Users', totalUsers, Icons.people, AppColors.primaryColor),
        _buildStatCard('Total Groups', totalGroups, Icons.groups, AppColors.secondaryColor),
        _buildStatCard('Active Events', activeEvents, Icons.event, AppColors.accentColor),
        _buildStatCard('Avg. Attendance', formattedAttendance, Icons.trending_up, AppColors.buttonColor),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('View All'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    if (_recentUsers.isEmpty) {
      return const Center(
        child: Text('No recent users found'),
      );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
      return const Center(
        child: Text('No recent groups found'),
      );
    }

    return Container(
      height: 150, // Increased height to accommodate content
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentGroups.length > 5 ? 5 : _recentGroups.length,
        itemBuilder: (context, index) {
          final group = _recentGroups[index];
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                future: Provider.of<GroupProvider>(context, listen: false).getGroupMembers(group.id),
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

  Widget _buildQuickAnalyticsChart() {
    // Sample data for the chart
    final List<FlSpot> spots = [
      const FlSpot(0, 75),
      const FlSpot(1, 82),
      const FlSpot(2, 88),
      const FlSpot(3, 85),
      const FlSpot(4, 92),
      const FlSpot(5, 90),
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 6 months attendance rate',
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          final index = value.toInt();
                          if (index >= 0 && index < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[index],
                                style: TextStyles.bodyText.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textColor.withOpacity(0.7),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 == 0) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyles.bodyText.copyWith(
                                fontSize: 12,
                                color: AppColors.textColor.withOpacity(0.7),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.textColor.withOpacity(0.2)),
                  ),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // USER MANAGEMENT TAB
  Widget _buildUserManagementTab() {
    return UserManagementTab();
  }

  // GROUP ADMINISTRATION TAB
  Widget _buildGroupAdministrationTab() {
    return const GroupAdministrationTab();
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System-wide Analytics',
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Date range selector
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: AppColors.primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Range',
                          style: TextStyles.bodyText.copyWith(
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last 6 Months',
                          style: TextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Change date range
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Analytics cards would go here
          // This is a placeholder for the analytics tab content
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Dashboard',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The analytics dashboard is under development. Check back soon for detailed insights about your church groups and members.',
                    style: TextStyles.bodyText,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Refresh analytics data
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SETTINGS TAB
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Settings',
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Settings sections would go here
          // This is a placeholder for the settings tab content
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings Dashboard',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The settings dashboard is under development. Check back soon to configure your church app settings.',
                    style: TextStyles.bodyText,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Save settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved successfully')),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
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