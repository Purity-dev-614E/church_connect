import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/super_admin/user_role_management.dart';
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
        } else {
          // If no group is selected, we can't fetch upcoming events
          // You might want to fetch events for all groups or a specific group
          // For now, we'll leave it as '0'
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

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onSeeAll) {
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
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Row(
            children: [
              Text(
                'See All',
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    if (_recentUsers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No recent users found'),
        ),
      );
    }
    
    return Column(
      children: _recentUsers.map((user) => _buildUserListItem(user)).toList(),
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : 'No Name',
          style: TextStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${user.role} ${user.email.isNotEmpty ? '• ${user.email}' : ''}',
          style: TextStyles.bodyText.copyWith(
            fontSize: 14,
            color: AppColors.textColor.withOpacity(0.7),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show user actions menu
          },
        ),
        onTap: () {
          // Navigate to user details
        },
      ),
    );
  }

  Widget _buildRecentGroupsList() {
    if (_recentGroups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No recent groups found'),
        ),
      );
    }
    
    return Column(
      children: _recentGroups.map((group) => _buildGroupListItem(group)).toList(),
    );
  }

  Widget _buildGroupListItem(GroupModel group) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondaryColor,
          child: const Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(
          group.name,
          style: TextStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Admin ID: ${group.group_admin}',
          style: TextStyles.bodyText.copyWith(
            fontSize: 14,
            color: AppColors.textColor.withOpacity(0.7),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show group actions menu
          },
        ),
        onTap: () {
          // Navigate to group details
        },
      ),
    );
  }

  Widget _buildQuickAnalyticsChart() {
    // Extract attendance data from provider
    List<Map<String, dynamic>> monthlyData = [];
    List<String> months = [];
    
    if (_attendanceTrends.containsKey('monthly_data')) {
      monthlyData = List<Map<String, dynamic>>.from(_attendanceTrends['monthly_data'] ?? []);
      
      // Extract month names
      months = monthlyData.map((data) => data['month'] as String? ?? '').toList();
    }
    
    // If no data is available, use placeholder data
    if (monthlyData.isEmpty) {
      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      monthlyData = List.generate(
        6,
        (index) => {
          'month': months[index],
          'attendance_rate': 65.0 + (index * 5.0),
        },
      );
    }
    
    return SizedBox(
      height: 200,
      child: Card(
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
                'Monthly Attendance',
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.round()}%',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < months.length) {
                              return Text(
                                months[index],
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 25 == 0) {
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
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      monthlyData.length,
                      (index) => _buildBarGroup(
                        index,
                        (monthlyData[index]['attendance_rate'] as num?)?.toDouble() ?? 0.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primaryColor,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  // USER MANAGEMENT TAB
  Widget _buildUserManagementTab() {
    return _UserManagementTab();
  }
  
  // Separate stateful widget for user management to prevent continuous rebuilds
  class _UserManagementTab extends StatefulWidget {
    @override
    State<_UserManagementTab> createState() => _UserManagementTabState();
  }
  
  class _UserManagementTabState extends State<_UserManagementTab> {
    bool _isLoading = false;
    String? _errorMessage;
    List<UserModel> _users = [];
    List<UserModel> _filteredUsers = [];
    
    // State for search and filtering
    final TextEditingController _searchController = TextEditingController();
    String _selectedRole = 'All';
    
    @override
    void initState() {
      super.initState();
      _loadUsers();
    }
    
    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }
    
    Future<void> _loadUsers() async {
      if (_isLoading) return; // Prevent multiple simultaneous loads
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final users = await userProvider.getAllUsers();
        
        if (mounted) {
          setState(() {
            _users = List<UserModel>.from(users);
            _filterUsers(); // Apply any existing filters
            _errorMessage = null;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
    
    void _filterUsers() {
      final query = _searchController.text.toLowerCase();
      
      setState(() {
        _filteredUsers = _users.where((user) {
          // Filter by search query
          final matchesQuery = query.isEmpty || 
              user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
              
          // Filter by role
          final matchesRole = _selectedRole == 'All' || 
              (_selectedRole == 'Members' && user.role.toLowerCase() == 'user') ||
              (_selectedRole == 'Group Leaders' && user.role.toLowerCase() == 'admin') ||
              (_selectedRole == 'Admins' && user.role.toLowerCase() == 'super_admin');
              
          return matchesQuery && matchesRole;
        }).toList();
      });
    }
    
    @override
    Widget build(BuildContext context) {
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
                'Error loading users',
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
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        );
      }
      
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      _filterUsers();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to user creation screen or show dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add user functionality will be implemented here')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserRoleManagementScreen()),
                    ).then((_) {
                      // Refresh the user list when returning from role management
                      _loadUsers();
                    });
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Manage User Roles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        _filterUsers();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to user creation screen or show dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add user functionality will be implemented here')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'All Users (${_users.length})',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRoleManagementScreen(),
                        ),
                      ).then((_) {
                        // Refresh the user list when returning from role management
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Manage User Roles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text('Filter by:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Members', child: Text('Members')),
                      DropdownMenuItem(value: 'Group Leaders', child: Text('Group Leaders')),
                      DropdownMenuItem(value: 'Admins', child: Text('Admins')),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                        _filterUsers();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<List<UserModel>>(
                valueListenable: filteredUsers,
                builder: (context, filteredList, child) {
                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text('No users found matching the criteria'),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildUserListItem(filteredList[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // GROUP ADMINISTRATION TAB
  Widget _buildGroupAdministrationTab() {
    return const _GroupAdministrationTab();
  }
}

// Separate stateful widget for group administration to prevent continuous rebuilds
class _GroupAdministrationTab extends StatefulWidget {
  const _GroupAdministrationTab({Key? key}) : super(key: key);
  
  @override
  _GroupAdministrationTabState createState() => _GroupAdministrationTabState();
}

class _GroupAdministrationTabState extends State<_GroupAdministrationTab> {
    bool _isLoading = false;
    String? _errorMessage;
    List<GroupModel> _groups = [];
    
    @override
    void initState() {
      super.initState();
      _loadGroups();
    }
    
    Future<void> _loadGroups() async {
      if (_isLoading) return; // Prevent multiple simultaneous loads
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        await groupProvider.fetchGroups();
        
        if (mounted) {
          setState(() {
            _groups = groupProvider.groups;
            _errorMessage = null;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
    
    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Management',
              style: TextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Manage all church groups from this dashboard. You can create, edit, and view details of each group.',
              style: TextStyles.bodyText,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                  ? _buildErrorView()
                  : _groups.isEmpty
                    ? _buildEmptyView()
                    : _buildGroupList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCreateGroupDialog(context).then((created) {
                    if (created) {
                      _loadGroups();
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    Widget _buildErrorView() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading groups',
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
              onPressed: _loadGroups,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    Widget _buildEmptyView() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: AppColors.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first group to get started',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showCreateGroupDialog(context).then((created) {
                  if (created) {
                    _loadGroups();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    Widget _buildGroupList() {
      return RefreshIndicator(
        onRefresh: _loadGroups,
        child: ListView.builder(
          itemCount: _groups.length,
          itemBuilder: (context, index) {
            final group = _groups[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  child: const Icon(Icons.groups, color: Colors.white),
                ),
                title: Text(
                  group.name,
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Group ID: ${group.id}',
                  style: TextStyles.bodyText,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditGroupDialog(context, group).then((updated) {
                          if (updated) {
                            _loadGroups();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        // Show group details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('View details for ${group.name}')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
  
  Future<bool> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false); // No group created
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final newGroup = GroupModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    group_admin: '',
                  );
                  
                  await groupProvider.createGroup(newGroup);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${nameController.text}" created successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  completer.complete(true); // Group created successfully
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                  completer.complete(false); // Failed to create group
                }
              } else {
                completer.complete(false); // Validation failed
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }

  Widget _buildGroupListItemDetailed(GroupModel group, int memberCount) {
    // We'll assume all groups are active for now
    final isActive = true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  radius: 24,
                  child: const Icon(Icons.groups, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyles.heading2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<UserModel?>(
                        future: group.group_admin.isNotEmpty 
                            ? Provider.of<UserProvider>(context, listen: false).loadUser(group.group_admin).then((_) => 
                                Provider.of<UserProvider>(context, listen: false).currentUser)
                            : Future.value(null),
                        builder: (context, snapshot) {
                          final adminName = snapshot.data?.fullName ?? 'No admin assigned';
                          return Text(
                            'Admin: $adminName',
                            style: TextStyles.bodyText.copyWith(
                              fontSize: 14,
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.successColor : AppColors.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGroupStat('Members', memberCount.toString(), Icons.people),
                FutureBuilder<List<EventModel>>(
                  future: Provider.of<EventProvider>(context, listen: false).getGroupEvents(group.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildGroupStat('Events', '...', Icons.event);
                    }
                    final eventCount = snapshot.data?.length ?? 0;
                    return _buildGroupStat('Events', eventCount.toString(), Icons.event);
                  },
                ),
                // For now, use a placeholder for attendance rate
                // In a real app, you would fetch this from an API
                _buildGroupStat(
                  'Attendance', 
                  '${(75 + (memberCount % 20)).toString()}%', 
                  Icons.trending_up
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // View group details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View details for ${group.name}')),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // Edit group
                    _showEditGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<bool> _showEditGroupDialog(BuildContext context, GroupModel group) async {
    final nameController = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false); // No changes made
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final updatedGroup = GroupModel(
                    id: group.id,
                    name: nameController.text.trim(),
                    group_admin: group.group_admin,
                  );
                  
                  await groupProvider.updateGroup(group.id, updatedGroup);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${nameController.text}" updated successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  completer.complete(true); // Group updated successfully
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                  completer.complete(false); // Failed to update group
                }
              } else {
                completer.complete(false); // Validation failed
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }

  Widget _buildGroupStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyles.bodyText.copyWith(
            fontSize: 12,
            color: AppColors.textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
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

          // Attendance chart
          _buildAnalyticsCard(
            'Attendance Trends',
            'Average attendance across all groups',
            _buildAttendanceChart(),
          ),
          const SizedBox(height: 24),

          // Growth chart
          _buildAnalyticsCard(
            'Growth Trends',
            'User and group growth over time',
            _buildGrowthChart(),
          ),
          const SizedBox(height: 24),

          // Group comparison
          _buildAnalyticsCard(
            'Group Comparison',
            'Compare performance across groups',
            _buildGroupComparisonChart(),
          ),
          const SizedBox(height: 24),

          // Event analytics
          _buildAnalyticsCard(
            'Event Analytics',
            'Event attendance and engagement',
            _buildEventAnalyticsChart(),
          ),
          const SizedBox(height: 32),

          // Export options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Export as PDF
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export as PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Export as CSV
                },
                icon: const Icon(Icons.table_chart),
                label: const Text('Export as CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String subtitle, Widget chart) {
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
              title,
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Extract attendance data from provider
    List<Map<String, dynamic>> monthlyData = [];
    List<String> months = [];
    
    if (_attendanceTrends.containsKey('monthly_data')) {
      monthlyData = List<Map<String, dynamic>>.from(_attendanceTrends['monthly_data'] ?? []);
      
      // Extract month names
      months = monthlyData.map((data) => data['month'] as String? ?? '').toList();
    }
    
    // If no data is available, use placeholder data
    if (monthlyData.isEmpty) {
      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      monthlyData = List.generate(
        6,
        (index) => {
          'month': months[index],
          'attendance_rate': 65.0 + (index * 5.0),
        },
      );
    }
    
    // Create spots for the line chart
    final spots = List.generate(
      monthlyData.length,
      (index) => FlSpot(
        index.toDouble(),
        (monthlyData[index]['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      ),
    );
    
    return LineChart(
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
        maxX: (monthlyData.length - 1).toDouble(),
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
    );
  }

  Widget _buildGrowthChart() {
    // Extract growth data from provider
    List<Map<String, dynamic>> trendData = [];
    List<String> periods = [];
    
    if (_groupGrowthTrends.containsKey('trend_data')) {
      trendData = List<Map<String, dynamic>>.from(_groupGrowthTrends['trend_data'] ?? []);
      
      // Extract period names
      periods = trendData.map((data) => data['period'] as String? ?? '').toList();
    }
    
    // If no data is available, use placeholder data
    if (trendData.isEmpty) {
      periods = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      trendData = List.generate(
        6,
        (index) => {
          'period': periods[index],
          'user_count': 80 + (index * 8),
          'group_count': 10 + index,
        },
      );
    }
    
    // Create spots for the user growth line chart
    final userSpots = List.generate(
      trendData.length,
      (index) => FlSpot(
        index.toDouble(),
        (trendData[index]['user_count'] as num?)?.toDouble() ?? 0.0,
      ),
    );
    
    // Create spots for the group growth line chart
    final groupSpots = List.generate(
      trendData.length,
      (index) => FlSpot(
        index.toDouble(),
        (trendData[index]['group_count'] as num?)?.toDouble() ?? 0.0,
      ),
    );
    
    // Calculate max Y value for scaling
    double maxUserCount = 0;
    for (final spot in userSpots) {
      if (spot.y > maxUserCount) maxUserCount = spot.y;
    }
    
    return LineChart(
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
                final index = value.toInt();
                if (index >= 0 && index < periods.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      periods[index],
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
                    value.toInt().toString(),
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
        maxX: (trendData.length - 1).toDouble(),
        minY: 0,
        maxY: maxUserCount * 1.2, // Add some padding
        lineBarsData: [
          // Users line
          LineChartBarData(
            spots: userSpots,
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
          // Groups line
          LineChartBarData(
            spots: groupSpots,
            isCurved: true,
            color: AppColors.secondaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupComparisonChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}%',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Youth', 'Choir', 'Bible', 'Men', 'Women'];
                if (value.toInt() >= 0 && value.toInt() < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
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
              getTitlesWidget: (value, meta) {
                if (value % 25 == 0) {
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
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, 85),
          _buildBarGroup(1, 72),
          _buildBarGroup(2, 78),
          _buildBarGroup(3, 65),
          _buildBarGroup(4, 80),
        ],
      ),
    );
  }

  Widget _buildEventAnalyticsChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()}%',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Sunday', 'Bible', 'Youth', 'Choir', 'Outreach'];
                if (value.toInt() >= 0 && value.toInt() < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
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
              getTitlesWidget: (value, meta) {
                if (value % 25 == 0) {
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
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, 90),
          _buildBarGroup(1, 75),
          _buildBarGroup(2, 85),
          _buildBarGroup(3, 70),
          _buildBarGroup(4, 65),
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

          // System Settings
          _buildSettingsSection(
            'System Settings',
            Icons.settings,
            [
              _buildSettingItem(
                'App Name',
                'Church Group Management',
                Icons.edit,
                () {},
              ),
              _buildSettingItem(
                'Church Name',
                'First Baptist Church',
                Icons.edit,
                () {},
              ),
              _buildSettingItem(
                'Contact Email',
                'admin@churchapp.com',
                Icons.edit,
                () {},
              ),
              _buildSettingItem(
                'Support Phone',
                '+1 234 567 8900',
                Icons.edit,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Settings
          _buildSettingsSection(
            'User Settings',
            Icons.people_outline,
            [
              _buildSettingToggle(
                'Allow User Registration',
                true,
                (value) {},
              ),
              _buildSettingToggle(
                'Require Admin Approval for New Users',
                true,
                (value) {},
              ),
              _buildSettingToggle(
                'Allow Users to Join Multiple Groups',
                false,
                (value) {},
              ),
              _buildSettingItem(
                'Default User Role',
                'Member',
                Icons.arrow_forward_ios,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Group Settings
          _buildSettingsSection(
            'Group Settings',
            Icons.groups_outlined,
            [
              _buildSettingToggle(
                'Allow Group Leaders to Create Events',
                true,
                (value) {},
              ),
              _buildSettingToggle(
                'Require Admin Approval for New Groups',
                true,
                (value) {},
              ),
              _buildSettingItem(
                'Maximum Members per Group',
                '50',
                Icons.edit,
                () {},
              ),
              _buildSettingItem(
                'Default Group Settings',
                'Configure',
                Icons.arrow_forward_ios,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notification Settings
          _buildSettingsSection(
            'Notification Settings',
            Icons.notifications_outlined,
            [
              _buildSettingToggle(
                'Email Notifications',
                true,
                (value) {},
              ),
              _buildSettingToggle(
                'Push Notifications',
                true,
                (value) {},
              ),
              _buildSettingToggle(
                'Event Reminders',
                true,
                (value) {},
              ),
              _buildSettingItem(
                'Notification Templates',
                'Configure',
                Icons.arrow_forward_ios,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Security Settings
          _buildSettingsSection(
            'Security Settings',
            Icons.security_outlined,
            [
              _buildSettingToggle(
                'Two-Factor Authentication',
                false,
                (value) {},
              ),
              _buildSettingItem(
                'Password Policy',
                'Strong',
                Icons.arrow_forward_ios,
                () {},
              ),
              _buildSettingItem(
                'Session Timeout',
                '30 minutes',
                Icons.edit,
                () {},
              ),
              _buildSettingItem(
                'Data Backup',
                'Configure',
                Icons.arrow_forward_ios,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save button
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Save settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Settings',
                style: TextStyles.buttonText.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 16,
              color: AppColors.textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(String title, bool initialValue, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: onChanged,
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}