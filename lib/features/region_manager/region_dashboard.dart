import 'dart:io';
import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/region_manager/region_analytics_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_user_management_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_group_administration_tab.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/event_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/providers/region_provider.dart';
import '../../data/services/event_services.dart';
import '../../data/services/analytics_services.dart';
import '../../data/providers/auth_provider.dart';

class RegionDashboard extends StatefulWidget {
  final String regionId;
  
  const RegionDashboard({
    Key? key,
    required this.regionId,
  }) : super(key: key);

  @override
  State<RegionDashboard> createState() => _RegionDashboardState();
}

class _RegionDashboardState extends State<RegionDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Data from providers
  late AnalyticsServices _analyticsServices;
  late EventServices _eventServices;
  List<UserModel> _regionUsers = [];
  List<GroupModel> _regionGroups = [];
  List<EventModel> _upcomingEvents = [];
  Map<String, dynamic> _dashboardSummary = {};
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  Map<String, dynamic> _memberParticipationStats = {};
  RegionModel? _region;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Settings state
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedDateRange = 'Last 6 Months';
  List<String> _availableDateRanges = ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year'];
  
  // Export options
  List<String> _exportFormats = ['CSV', 'PDF', 'Excel'];
  String _selectedExportFormat = 'CSV';
  
  // Chart data
  List<FlSpot> _attendanceSpots = [];
  List<String> _attendanceLabels = [];

  @override
  void initState() {
    super.initState();
    _analyticsServices = AnalyticsServices();
    _eventServices = EventServices();

    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() {
      _initializeData();
      _requestPermissions();
    });
  }
  
  Future<void> _requestPermissions() async {
    // Request storage permissions for exporting data
    await Permission.storage.request();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load region data
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      _region = await regionProvider.getRegionById(widget.regionId);
      
      if (_region == null) {
        throw Exception('Region not found');
      }

      // Fetch data separately to handle errors more gracefully
      try {
        await _loadRegionUsers();
      } catch (e) {
        print('Error fetching region users: $e');
      }

      try {
        await _loadRegionGroups();
      } catch (e) {
        print('Error fetching region groups: $e');
      }

      try {
        await _loadRegionEvents();
      } catch (e) {
        print('Error fetching region events: $e');
      }

      try {
        await _loadRegionAnalytics();
      } catch (e) {
        print('Error fetching region analytics: $e');
      }

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
          _errorMessage = 'Failed to load dashboard data: $e';
        });
      }
    }
  }
  
  Future<void> _loadRegionUsers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final users = await userProvider.getUsersByRegion(widget.regionId);
    
    if (mounted) {
      setState(() {
        _regionUsers = users;
      });
    }
  }
  
  Future<void> _loadRegionGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final groups = await groupProvider.getGroupsByRegion(widget.regionId);
    
    if (mounted) {
      setState(() {
        _regionGroups = groups;
      });
    }
  }
  
  Future<void> _loadRegionEvents() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final events = await eventProvider.getEventsByRegion(widget.regionId);
    
    if (mounted) {
      setState(() {
        _upcomingEvents = events;
      });
    }
  }
  
  Future<void> _loadRegionAnalytics() async {
    try {
      // Load region dashboard summary
      final summary = await _analyticsServices.getRegionDashboardSummary(widget.regionId);
      
      if (mounted) {
        setState(() {
          _dashboardSummary = summary;
        });
      }
      
      // Load region attendance trends
      final attendanceTrends = await _analyticsServices.getRegionAttendanceTrends(widget.regionId);
      
      if (mounted) {
        setState(() {
          _attendanceTrends = attendanceTrends;
          _processAttendanceChartData();
        });
      }
      
      // Load region growth trends
      final growthTrends = await _analyticsServices.getRegionGrowth(widget.regionId);
      
      if (mounted) {
        setState(() {
          _groupGrowthTrends = growthTrends;
        });
      }
    } catch (e) {
      print('Error loading region analytics: $e');
      throw e;
    }
  }
  
  void _processAttendanceChartData() {
    _attendanceSpots = [];
    _attendanceLabels = [];
    
    try {
      if (_attendanceTrends.containsKey('trend_data')) {
        final trendData = _attendanceTrends['trend_data'] as List;
        
        for (int i = 0; i < trendData.length; i++) {
          final item = trendData[i];
          final rate = item['attendance_rate'] as double? ?? 0.0;
          _attendanceSpots.add(FlSpot(i.toDouble(), rate));
          _attendanceLabels.add(item['month'] as String? ?? '');
        }
      } else {
        // Fallback to sample data if no trend data is available
        _attendanceSpots = [
          const FlSpot(0, 75),
          const FlSpot(1, 82),
          const FlSpot(2, 88),
          const FlSpot(3, 85),
          const FlSpot(4, 92),
          const FlSpot(5, 90),
        ];
        _attendanceLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      }
    } catch (e) {
      print('Error processing attendance chart data: $e');
      // Fallback to sample data
      _attendanceSpots = [
        const FlSpot(0, 75),
        const FlSpot(1, 82),
        const FlSpot(2, 88),
        const FlSpot(3, 85),
        const FlSpot(4, 92),
        const FlSpot(5, 90),
      ];
      _attendanceLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
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
  
  Future<void> _exportAnalyticsData(String format) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Convert format to lowercase for API
      final formatLower = format.toLowerCase();
      
      // Determine what data to export based on current tab
      String dataType = 'region_summary';
      if (_selectedIndex == 1) {
        dataType = 'region_users';
      } else if (_selectedIndex == 2) {
        dataType = 'region_groups';
      } else if (_selectedIndex == 3) {
        dataType = 'region_attendance';
      }
      
      // Call the export API
      final exportData = await _analyticsServices.exportRegionReport(widget.regionId);
      
      // Get the app's temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'region_report_$timestamp.$formatLower';
      final filePath = '${directory.path}/$fileName';
      
      // Write the data to a file
      final file = File(filePath);
      await file.writeAsString(exportData.toString());
      
      // Share the file
      await Share.shareFiles([filePath], text: 'Region Report');
      
      setState(() {
        _isLoading = false;
      });
      
      _showSuccess('Report exported successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to export report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _region?.name ?? 'Region Dashboard',
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
          RegionUserManagementTab(regionId: widget.regionId),
          RegionGroupAdministrationTab(regionId: widget.regionId),
          RegionAnalyticsTab(regionId: widget.regionId),
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
            _buildSectionHeader('Region Users', Icons.people, () {
              _onItemTapped(1); // Navigate to Users tab
            }),
            const SizedBox(height: 16),
            _buildRecentUsersList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Region Groups', Icons.groups, () {
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
    final userName = userProvider.currentUser?.fullName ?? 'Region Manager';

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
              AppColors.secondaryColor,
              AppColors.primaryColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
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
    // Get data from dashboard summary
    String totalUsers = _dashboardSummary['total_users']?.toString() ?? _regionUsers.length.toString();
    String totalGroups = _dashboardSummary['total_groups']?.toString() ?? _regionGroups.length.toString();
    String activeEvents = _dashboardSummary['active_events']?.toString() ?? _upcomingEvents.length.toString();
    
    // Format attendance rate with percentage
    final attendanceRate = _dashboardSummary['overall_attendance_rate'] ?? 0.0;
    String formattedAttendance = '${attendanceRate.toStringAsFixed(1)}%';

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
        _buildStatCard('Attendance', formattedAttendance, Icons.trending_up, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: AppColors.textColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users in this region yet',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _onItemTapped(1),
                  child: const Text('Add Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show only the first 5 users
    final displayUsers = _regionUsers.length > 5 ? _regionUsers.sublist(0, 5) : _regionUsers;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                fontSize: 12,
                color: AppColors.textColor.withOpacity(0.7),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: AppColors.textColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No groups in this region yet',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _onItemTapped(2),
                  child: const Text('Add Groups'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show only the first 5 groups
    final displayGroups = _regionGroups.length > 5 ? _regionGroups.sublist(0, 5) : _regionGroups;

    return Card(
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
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
              child: const Icon(
                Icons.groups,
                color: AppColors.secondaryColor,
              ),
            ),
            title: Text(
              group.name,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Members: ${group.members?.length ?? 0}',
              style: TextStyles.bodyText.copyWith(
                fontSize: 12,
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to group details
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickAnalyticsChart() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Trends',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Region attendance over the last 6 months',
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyles.bodyText.copyWith(
                              color: AppColors.textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _attendanceLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _attendanceLabels[value.toInt()],
                                style: TextStyles.bodyText.copyWith(
                                  color: AppColors.textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _attendanceSpots,
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 4,
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

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Region Analytics',
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detailed analytics for ${_region?.name ?? 'your region'}',
            style: TextStyles.bodyText,
          ),
          const SizedBox(height: 24),
          
          // Date range selector
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
                    'Date Range',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDateRange,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: _availableDateRanges.map((range) {
                            return DropdownMenuItem(
                              value: range,
                              child: Text(range),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDateRange = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Apply date range filter
                        },
                        child: const Text('Apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Attendance analytics
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
                    'Attendance Analytics',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}%',
                                  style: TextStyles.bodyText.copyWith(
                                    color: AppColors.textColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < _attendanceLabels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _attendanceLabels[value.toInt()],
                                      style: TextStyles.bodyText.copyWith(
                                        color: AppColors.textColor.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _attendanceSpots,
                            isCurved: true,
                            color: AppColors.primaryColor,
                            barWidth: 4,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportAnalyticsData('PDF'),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Growth analytics
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
                    'Growth Analytics',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Region growth over time',
                    style: TextStyles.bodyText.copyWith(
                      color: AppColors.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Growth chart would go here
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportAnalyticsData('PDF'),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
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
            'Settings',
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
          
          // Export settings
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
                    'Export Settings',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedExportFormat,
                    decoration: InputDecoration(
                      labelText: 'Default Export Format',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _exportFormats.map((format) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedExportFormat = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _exportAnalyticsData(_selectedExportFormat),
                      child: const Text('Export Region Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
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