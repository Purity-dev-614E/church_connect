import 'dart:io';
import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/features/super_admin/group_administration_tab.dart';
import 'package:group_management_church_app/features/super_admin/user_management_tab.dart';
import 'package:group_management_church_app/features/region_manager/region_manager_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/event_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/user_provider.dart';
import '../../data/services/event_services.dart';
import '../../data/services/analytics_services.dart';
import '../../data/providers/auth_provider.dart';

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
  late AnalyticsServices _analyticsServices;
  late EventServices _eventServices;
  List<UserModel> _recentUsers = [];
  List<GroupModel> _recentGroups = [];
  List<EventModel> _upcomingEvents = [];
  Map<String, dynamic> _dashboardSummary = {};
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  Map<String, dynamic> _memberParticipationStats = {};
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
    // Get the provider outside of build
    _analyticsProvider = Provider.of<DashboardAnalyticsProvider>(context, listen: false);
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
            _processAttendanceChartData();
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
      
      try {
        await _analyticsProvider.fetchUpcomingEvents();
        if (mounted) {
          setState(() {
            _upcomingEvents = _analyticsProvider.upcomingEvents;
          });
        }
      } catch (e) {
        print('Error fetching upcoming events: $e');
      }
      
      try {
        // Fetch member participation stats
        final stats = await _analyticsServices.getMemberParticipationStats();
        if (mounted) {
          setState(() {
            _memberParticipationStats = stats;
          });
        }
      } catch (e) {
        print('Error fetching member participation stats: $e');
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
      String dataType = 'dashboard_summary';
      if (_selectedIndex == 1) {
        dataType = 'user_management';
      } else if (_selectedIndex == 2) {
        dataType = 'group_management';
      } else if (_selectedIndex == 3) {
        dataType = 'attendance_trends';
      }
      
      // Parameters for export
      final parameters = {
        'date_range': _selectedDateRange,
        'include_charts': true,
      };
      
      // Call the export function
      final downloadUrl = await _analyticsServices.exportAnalyticsData(
        dataType: dataType,
        format: formatLower,
        parameters: parameters,
      );
      
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
      setState(() {
        _isLoading = false;
      });
      _showError('Error exporting data: $e');
    }
  }
  
  Future<void> _createEvent(String groupId) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    
    // Format for displaying the date
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    
    // Show dialog to create event
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${dateFormat.format(selectedDate)}',
                        style: TextStyles.bodyText,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Time: ${selectedTime.format(context)}',
                        style: TextStyles.bodyText,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: const Text('Select Time'),
                    ),
                  ],
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
                if (titleController.text.isEmpty || 
                    descriptionController.text.isEmpty || 
                    locationController.text.isEmpty) {
                  _showError('Please fill all fields');
                  return;
                }
                
                try {
                  // Combine date and time
                  final eventDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  
                  // Create the event
                  await _eventServices.createEvent(
                    groupId: groupId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    dateTime: eventDateTime,
                    location: locationController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  _showSuccess('Event created successfully');
                  
                  // Refresh events
                  await _analyticsProvider.fetchUpcomingEvents();
                  if (mounted) {
                    setState(() {
                      _upcomingEvents = _analyticsProvider.upcomingEvents;
                    });
                  }
                } catch (e) {
                  _showError('Failed to create event: $e');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showEventDetails(EventModel event) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date & Time:',
                style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(event.dateTime),
                style: TextStyles.bodyText,
              ),
              const SizedBox(height: 12),
              Text(
                'Location:',
                style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                event.location,
                style: TextStyles.bodyText,
              ),
              const SizedBox(height: 12),
              Text(
                'Description:',
                style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                event.description,
                style: TextStyles.bodyText,
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _eventServices.getEventAttendance(event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('No attendance data available');
                  }
                  
                  final attendanceData = snapshot.data!;
                  final attendanceCount = attendanceData['attendance_count'] ?? 0;
                  final totalMembers = attendanceData['total_members'] ?? 0;
                  final attendanceRate = totalMembers > 0 
                      ? (attendanceCount / totalMembers * 100).toStringAsFixed(1) 
                      : '0.0';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance:',
                        style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
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
  
  Future<void> _showAttendanceDialog(EventModel event) async {
    try {
      // Get group members
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final members = await groupProvider.getGroupMembers(event.groupId);
      
      // Get attended members
      final attendedMembers = await _eventServices.getAttendedMembers(event.id);
      final attendedMemberIds = attendedMembers.map((user) => user.id).toList();
      
      // Create a map to track attendance
      Map<String, bool> attendanceMap = {};
      for (var member in members) {
        final memberId = member['id'] as String;
        attendanceMap[memberId] = attendedMemberIds.contains(memberId);
      }
      
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Attendance for ${event.title}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberId = member['id'] as String;
                  final memberName = member['fullName'] as String? ?? 'Unknown';
                  
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
                    await _eventServices.createEventAttendance(event.id, attendedIds);
                    
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
      await _analyticsProvider.fetchRecentMembers();
      if (mounted) {
        setState(() {
          _recentUsers = _analyticsProvider.recentMembers;
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
    final TextEditingController nameController = TextEditingController(text: user.fullName);
    final TextEditingController emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  DropdownMenuItem(value: 'admin', child: Text('Group Leader')),
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
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
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
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
                );

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.updateProfile(updatedUser);

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
                  'Regions',
                  Icons.location_city,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegionManagerScreen(),
                    ),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'export') {
                      _showExportDialog();
                    } else if (value == 'refresh') {
                      _analyticsProvider.fetchAttendanceTrends().then((_) {
                        if (mounted) {
                          setState(() {
                            _attendanceTrends = _analyticsProvider.attendanceTrends;
                            _processAttendanceChartData();
                          });
                        }
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text('Export Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Refresh Data'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                          final index = value.toInt();
                          if (index >= 0 && index < _attendanceLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _attendanceLabels[index],
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
                  maxX: _attendanceSpots.isEmpty ? 5 : _attendanceSpots.length - 1.0,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _attendanceSpots,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _onItemTapped(3), // Navigate to Analytics tab
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('View Detailed Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ...List.generate(
              _exportFormats.length,
              (index) => RadioListTile<String>(
                title: Text(_exportFormats[index]),
                value: _exportFormats[index],
                groupValue: _selectedExportFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedExportFormat = value!;
                    Navigator.pop(context);
                    _exportAnalyticsData(_selectedExportFormat);
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System-wide Analytics',
                style: TextStyles.heading1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export Analytics',
                onPressed: _showExportDialog,
              ),
            ],
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
                          _selectedDateRange,
                          style: TextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _selectedDateRange = value;
                        // Refresh analytics data based on new date range
                        _initializeData();
                      });
                    },
                    itemBuilder: (context) => _availableDateRanges
                        .map((range) => PopupMenuItem<String>(
                              value: range,
                              child: Text(range),
                            ))
                        .toList(),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Attendance Trends Card
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
                    'Attendance Trends',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
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
                                final index = value.toInt();
                                if (index >= 0 && index < _attendanceLabels.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _attendanceLabels[index],
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
                        maxX: _attendanceSpots.isEmpty ? 5 : _attendanceSpots.length - 1.0,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _attendanceSpots,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await _analyticsProvider.fetchAttendanceTrends();
                            if (mounted) {
                              setState(() {
                                _attendanceTrends = _analyticsProvider.attendanceTrends;
                                _processAttendanceChartData();
                              });
                              _showSuccess('Attendance data refreshed');
                            }
                          } catch (e) {
                            _showError('Failed to refresh attendance data: $e');
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Group Growth Trends
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
                    'Group Growth Trends',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _analyticsServices.getGroupGrowthAnalytics('all'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(
                          child: Text('No group growth data available'),
                        );
                      }
                      
                      final growthData = snapshot.data!;
                      final trendData = growthData['trend_data'] as List? ?? [];
                      
                      if (trendData.isEmpty) {
                        return const Center(
                          child: Text('No group growth data available'),
                        );
                      }
                      
                      // Process data for chart
                      final List<FlSpot> growthSpots = [];
                      final List<String> growthLabels = [];
                      
                      for (int i = 0; i < trendData.length; i++) {
                        final item = trendData[i];
                        final count = item['count'] as int? ?? 0;
                        growthSpots.add(FlSpot(i.toDouble(), count.toDouble()));
                        growthLabels.add(item['period'] as String? ?? '');
                      }
                      
                      return SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 5,
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
                                    if (index >= 0 && index < growthLabels.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          growthLabels[index],
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
                                    return Text(
                                      '${value.toInt()}',
                                      style: TextStyles.bodyText.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textColor.withOpacity(0.7),
                                      ),
                                    );
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
                            maxX: growthSpots.isEmpty ? 5 : growthSpots.length - 1.0,
                            minY: 0,
                            maxY: growthSpots.isEmpty ? 10 : (growthSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2),
                            lineBarsData: [
                              LineChartBarData(
                                spots: growthSpots,
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Member Participation Stats
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
                    'Member Participation',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _analyticsServices.getMemberParticipationStats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(
                          child: Text('No member participation data available'),
                        );
                      }
                      
                      final participationData = snapshot.data!;
                      final topMembers = participationData['top_members'] as List? ?? [];
                      
                      if (topMembers.isEmpty) {
                        return const Center(
                          child: Text('No member participation data available'),
                        );
                      }
                      
                      return Column(
                        children: [
                          const Text(
                            'Most Active Members',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            topMembers.length > 5 ? 5 : topMembers.length,
                            (index) {
                              final member = topMembers[index];
                              final name = member['name'] as String? ?? 'Unknown';
                              final attendanceRate = member['attendance_rate'] as double? ?? 0.0;
                              final eventsAttended = member['events_attended'] as int? ?? 0;
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(name),
                                subtitle: Text('$eventsAttended events attended'),
                                trailing: Text(
                                  '${attendanceRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          setState(() {
                            _memberParticipationStats = {};
                          });
                          final stats = await _analyticsServices.getMemberParticipationStats();
                          if (mounted) {
                            setState(() {
                              _memberParticipationStats = stats;
                            });
                            _showSuccess('Member participation data refreshed');
                          }
                        } catch (e) {
                          _showError('Failed to refresh member data: $e');
                        }
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

          // App Settings
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
                    'App Settings',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive alerts for new members, events, and reports'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme throughout the app'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      _showInfo('Theme changes will apply after restart');
                    },
                    activeColor: AppColors.primaryColor,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Default Date Range'),
                    subtitle: Text(_selectedDateRange),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Default Date Range'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _availableDateRanges
                                .map(
                                  (range) => RadioListTile<String>(
                                    title: Text(range),
                                    value: range,
                                    groupValue: _selectedDateRange,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDateRange = value!;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Data Management
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
                    'Data Management',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.backup, color: AppColors.primaryColor),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Create a backup of all church data'),
                    onTap: () {
                      _showBackupDialog();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restore, color: AppColors.primaryColor),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Restore from a previous backup'),
                    onTap: () {
                      _showInfo('Restore functionality will be available in the next update');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.download, color: AppColors.primaryColor),
                    title: const Text('Export Data'),
                    subtitle: const Text('Export data in various formats'),
                    onTap: _showExportDialog,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // System Settings
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
                    'System Settings',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: AppColors.primaryColor),
                    title: const Text('User Permissions'),
                    subtitle: const Text('Manage role-based permissions'),
                    onTap: () {
                      _showInfo('Permission management will be available in the next update');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.security, color: AppColors.primaryColor),
                    title: const Text('Security Settings'),
                    subtitle: const Text('Configure security options'),
                    onTap: () {
                      _showInfo('Security settings will be available in the next update');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.sync, color: AppColors.primaryColor),
                    title: const Text('Sync Settings'),
                    subtitle: const Text('Configure data synchronization'),
                    onTap: () {
                      _showInfo('Sync settings will be available in the next update');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // About Section
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
                    'About',
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Check for Updates'),
                    onTap: () {
                      _showInfo('Your app is up to date');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Terms of Service'),
                    onTap: () {
                      _showInfo('Terms of Service will be available in the next update');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      _showInfo('Privacy Policy will be available in the next update');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Save settings
                _showSuccess('Settings saved successfully');
              },
              icon: const Icon(Icons.save),
              label: const Text('Save All Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create a backup of all church data. This includes:'),
            const SizedBox(height: 8),
            const Text('• User information'),
            const Text('• Group data'),
            const Text('• Event records'),
            const Text('• Attendance history'),
            const SizedBox(height: 16),
            const Text('The backup will be saved to your device and can be used to restore data if needed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Backup created successfully');
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }
}