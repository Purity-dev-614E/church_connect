import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/analytics_model.dart';
import 'package:group_management_church_app/features/events/overall_event_details.dart';
import 'package:group_management_church_app/features/member/member_attendance_screen.dart';
import 'package:group_management_church_app/features/member/member_profile_screen.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/event_card.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Define the ExportFormat enum
enum ExportFormat {
  pdf,
  csv,
  excel,
}

class AdminDashboard extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int initialTabIndex;

  const AdminDashboard({
    Key? key,
    required this.groupId,
    required this.groupName,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  late AnalyticsProvider _analyticsProvider;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 180)),
    end: DateTime.now(),
  );

  // Theme settings
  bool _isDarkMode = false;
  Color _accentColor = AppColors.primaryColor;

  // Animation controllers
  late AnimationController _refreshAnimationController;

  // Settings
  bool _notificationsEnabled = true;
  bool _autoRefreshEnabled = false;
  int _autoRefreshInterval = 30; // minutes
  bool _analyticsExpanded = true;

  // Export settings
  ExportFormat _selectedExportFormat = ExportFormat.pdf;

  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    _loadAnalyticsData();

    // Initialize animation controllers
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Load settings from shared preferences
    _loadSettings();

    // Set up auto-refresh if enabled
    if (_autoRefreshEnabled) {
      _setupAutoRefresh();
    }
  }

  Future<void> _loadSettings() async {
    // In a real app, you would load these from SharedPreferences
    // For now, we'll just use default values
    setState(() {
      _isDarkMode = false;
      _accentColor = AppColors.primaryColor;
      _notificationsEnabled = true;
      _autoRefreshEnabled = false;
      _autoRefreshInterval = 30;
      _analyticsExpanded = true;
    });
  }

  void _setupAutoRefresh() {
    // Set up a timer to refresh data at the specified interval
    Future.delayed(Duration(minutes: _autoRefreshInterval), () {
      if (mounted && _autoRefreshEnabled) {
        _refreshData();
        _setupAutoRefresh(); // Schedule the next refresh
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    // Start the refresh animation
    _refreshAnimationController.repeat();

    try {
      await _loadAnalyticsData();
      await _loadGroupMembers();
      await _loadGroupEvents();

      if (_notificationsEnabled) {
        _showInfo('Dashboard data refreshed');
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (_notificationsEnabled) {
        _showError('Failed to refresh data: $e');
      }
    } finally {
      // Stop the refresh animation
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // List to track which analytics failed to load
    List<String> failedAnalytics = [];

    // Define a helper function to load analytics with proper error handling
    Future<void> loadAnalytic(String name,
        Future<dynamic> Function() loader) async {
      try {
        await loader();
        print('Successfully loaded $name');
      } catch (e) {
        print('Error fetching $name: $e');
        failedAnalytics.add(name);
      }
    }

    try {
      // Load only the active analytics that are needed for the dashboard
      List<Future<void>> activeAnalytics = [
        loadAnalytic('Group Demographics', () =>
            _analyticsProvider.fetchGroupDemographics(widget.groupId)),
        loadAnalytic('Group Attendance Stats', () =>
            _analyticsProvider.fetchGroupAttendanceStats(widget.groupId)),
        loadAnalytic('Member Participation Stats', () =>
            _analyticsProvider.fetchMemberParticipationStats()),
        loadAnalytic('Event Participation Stats', () =>
            _analyticsProvider.fetchEventParticipationStats(widget.groupId)),
      ];

      // Wait for all active analytics to complete
      await Future.wait(activeAnalytics);

      // Set error message if any analytics failed to load
      if (failedAnalytics.isNotEmpty) {
        _showInfo(
            'Some analytics data could not be loaded. The dashboard may show incomplete information.');

        setState(() {
          _errorMessage =
          'Some analytics data could not be loaded: ${failedAnalytics.join(
              ', ')}';
        });
      }
    } catch (e) {
      print('Error in _loadAnalyticsData: $e');
      setState(() =>
      _errorMessage = 'Error loading analytics data: ${e.toString()}');
      _showError('Failed to load analytics data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDateRange() async {
    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      // Show loading indicator
      setState(() {
        _selectedDateRange = newRange;
        _isLoading = true;
        _errorMessage = null;
      });

      // Convert date range to string format for analytics
      final timeframe = {
        'start_date': newRange.start.toIso8601String(),
        'end_date': newRange.end.toIso8601String(),
      };

      // Format date range for display
      final startFormatted = DateFormat('MMM d, y').format(newRange.start);
      final endFormatted = DateFormat('MMM d, y').format(newRange.end);
      _showInfo(
          'Updating dashboard for date range: $startFormatted to $endFormatted');

      // List to track which analytics failed to load
      List<String> failedAnalytics = [];

      // Define a helper function to load analytics with proper error handling
      Future<void> loadAnalytic(String name,
          Future<dynamic> Function() loader) async {
        try {
          await loader();
          print('Successfully loaded $name for date range');
        } catch (e) {
          print('Error fetching $name for date range: $e');
          failedAnalytics.add(name);
        }
      }

      try {
        // Notify the analytics provider about the date range change
        _analyticsProvider.setDateRange(newRange.start, newRange.end);

        // Load only the active analytics with the new date range
        List<Future<void>> activeAnalytics = [
          loadAnalytic('Group Demographics', () =>
              _analyticsProvider.fetchGroupDemographics(widget.groupId)),
          loadAnalytic('Group Attendance Stats', () =>
              _analyticsProvider.fetchGroupAttendanceStats(widget.groupId)),
          loadAnalytic('Member Participation Stats', () =>
              _analyticsProvider.fetchMemberParticipationStats()),
          loadAnalytic('Event Participation Stats', () =>
              _analyticsProvider.fetchEventParticipationStats(widget.groupId)),
        ];

        // Wait for all active analytics to complete
        await Future.wait(activeAnalytics);

        // Set error message if any analytics failed to load
        if (failedAnalytics.isNotEmpty) {
          _showInfo(
              'Some analytics data could not be loaded for the selected date range. The dashboard may show incomplete information.');

          setState(() {
            _errorMessage =
            'Some analytics data could not be loaded for the selected date range: ${failedAnalytics
                .join(', ')}';
          });
        } else {
          _showSuccess(
              'Dashboard updated for date range: $startFormatted to $endFormatted');
        }
      } catch (e) {
        print('Error in _updateDateRange: $e');
        setState(() => _errorMessage =
        'Error updating analytics for date range: ${e.toString()}');
        _showError('Failed to update dashboard for selected date range: ${e
            .toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Group members from provider
  List<UserModel> _cachedGroupMembers = [];
  bool _isLoadingMembers = false;

  Future<void> _loadGroupMembers() async {
    if (_isLoadingMembers) return;

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Get members data
      dynamic membersData;
      try {
        membersData = await groupProvider.getGroupMembers(widget.groupId);
      } catch (e) {
        print('Error in getGroupMembers: $e');
        throw e;
      }

      // Handle different response formats
      List<dynamic> members = [];

      if (membersData is List) {
        // If it's already a list, use it directly
        members = membersData;
      } else if (membersData is Map<String, dynamic>) {
        // Check for common response structures
        if (membersData.containsKey('members') &&
            membersData['members'] is List) {
          members = membersData['members'];
        } else
        if (membersData.containsKey('data') && membersData['data'] is List) {
          members = membersData['data'];
        } else
        if (membersData.containsKey('users') && membersData['users'] is List) {
          members = membersData['users'];
        } else
        if (membersData.containsKey('items') && membersData['items'] is List) {
          members = membersData['items'];
        } else if (membersData.containsKey('results') &&
            membersData['results'] is List) {
          members = membersData['results'];
        } else {
          // Try to find any list in the map
          for (var key in membersData.keys) {
            if (membersData[key] is List) {
              members = membersData[key];
              break;
            }
          }
        }
      }

      print('Processing ${members.length} group members');

      // Convert the dynamic list to UserModel list
      final List<UserModel> userMembers = [];

      for (var member in members) {
        try {
          // Check if the member is already a UserModel
          if (member is UserModel) {
            userMembers.add(member);
            continue;
          }

          // Check if it's a map with user data
          if (member is Map) {
            // Convert to Map<String, dynamic> if needed
            Map<String, dynamic> memberMap;
            if (member is Map<String, dynamic>) {
              memberMap = member;
            } else {
              memberMap = {};
              member.forEach((key, value) {
                memberMap[key.toString()] = value;
              });
            }

            // Check if it has a user_id or uid field
            String? userId;
            for (var idField in [
              'user_id',
              'uid',
              'id',
              '_id',
              'userId',
              'member_id'
            ]) {
              if (memberMap.containsKey(idField)) {
                userId = memberMap[idField].toString();
                break;
              }
            }

            if (userId != null && userId.isNotEmpty) {
              // Try to fetch the complete user data
              try {
                final user = await userProvider.getUserById(userId);
                if (user != null) {
                  userMembers.add(user);
                  continue;
                }
              } catch (e) {
                print('Error fetching user by ID $userId: $e');
                // Continue to create from map
              }
            }

            // If we couldn't get the user by ID, try to create from the map
            try {
              userMembers.add(UserModel.fromJson(memberMap));
            } catch (e) {
              print('Error creating UserModel from map: $e');
              // Try to create a minimal user model with available data
              String name = memberMap['full_name'] ??
                  memberMap['fullName'] ??
                  memberMap['name'] ??
                  memberMap['username'] ??
                  'Unknown User';

              String email = memberMap['email'] ??
                  memberMap['mail'] ??
                  'unknown@example.com';

              String role = memberMap['role'] ??
                  memberMap['user_role'] ??
                  'Member';

              String gender = memberMap['gender'] ??
                  memberMap['sex'] ??
                  'Unknown';

              userMembers.add(UserModel(
                id: userId ?? 'unknown_${userMembers.length}',
                fullName: name,
                email: email,
                contact: memberMap['contact'] ?? memberMap['phone'] ??
                    memberMap['phone_number'] ?? '',
                nextOfKin: memberMap['next_of_kin'] ?? memberMap['nextOfKin'] ??
                    memberMap['emergency_contact_name'] ?? '',
                nextOfKinContact: memberMap['next_of_kin_contact'] ??
                    memberMap['nextOfKinContact'] ??
                    memberMap['emergency_contact_number'] ?? '',
                role: role,
                gender: gender,
              ));
            }
          } else if (member is String) {
            // If it's just a user ID string, try to fetch the user
            try {
              final user = await userProvider.getUserById(member);
              if (user != null) {
                userMembers.add(user);
              }
            } catch (e) {
              print('Error fetching user by ID string $member: $e');
            }
          }
        } catch (e) {
          print('Error processing member: $e');
          // Continue with the next member
        }
      }

      print('Successfully processed ${userMembers.length} members');

      setState(() {
        _cachedGroupMembers = userMembers;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('Error loading group members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  // Cache for group events
  bool _isLoadingEvents = false;

  Future<void> _loadGroupEvents() async {
    if (_isLoadingEvents) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // Set current group ID in the provider
      eventProvider.setCurrentGroup(widget.groupId);

      // Load both upcoming and past events with error handling for each
      List<String> errors = [];

      try {
        await eventProvider.fetchUpcomingEvents(widget.groupId);
      } catch (e) {
        print('Error fetching upcoming events: $e');
        errors.add('Upcoming events: $e');
      }

      try {
        await eventProvider.fetchPastEvents(widget.groupId);
      } catch (e) {
        print('Error fetching past events: $e');
        errors.add('Past events: $e');
      }

      // If both failed, show an error
      if (errors.length == 2) {
        _showError('Failed to load events: ${errors.join(', ')}');
      } else if (errors.isNotEmpty) {
        // If only one failed, show a warning
        _showInfo('Some events could not be loaded');
      }

      setState(() {
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('Error loading group events: $e');
      _showError('Failed to load events: $e');
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move the page jump to didChangeDependencies to ensure PageView is ready
    if (_pageController.hasClients) {
      _pageController.jumpToPage(widget.initialTabIndex);
    }
  }

  // Getter for group members
  List<UserModel> get _groupMembers {
    if (_cachedGroupMembers.isEmpty) {
      // Return sample data if we haven't loaded real data yet
      return [
        UserModel(
          id: '1',
          fullName: 'John Doe',
          email: 'john.doe@example.com',
          contact: '+1 234 567 8901',
          nextOfKin: 'Jane Doe',
          nextOfKinContact: '+1 234 567 8902',
          role: 'Member',
          gender: 'Male',
        ),
        UserModel(
          id: '2',
          fullName: 'Jane Smith',
          email: 'jane.smith@example.com',
          contact: '+1 234 567 8903',
          nextOfKin: 'John Smith',
          nextOfKinContact: '+1 234 567 8904',
          role: 'Member',
          gender: 'Female',
        ),
      ];
    }
    return _cachedGroupMembers;
  }

  // Events data from provider
  List<EventModel> get _upcomingEvents {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    return eventProvider.upcomingEvents;
  }

  List<EventModel> get _pastEvents {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    return eventProvider.pastEvents;
  }

  // Analytics data from provider
  Future<Map<String, double>> get _analyticsData async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(
          context, listen: false);
      final analyticsProvider = Provider.of<AnalyticsProvider>(
          context, listen: false);

      // Initialize with default values
      double totalMembers = 0.0;
      double activeMembers = 0.0;
      double averageAttendance = 0.0;
      double eventsThisMonth = 0.0;

      // Try to get data from analytics provider first (more efficient)
      try {
        // Check if we have dashboard data from the analytics provider
        if (analyticsProvider.dashboardTrends != null &&
            analyticsProvider.dashboardTrends!.isNotEmpty) {
          final trends = analyticsProvider.dashboardTrends!;

          // Extract values with fallbacks
          if (trends.containsKey('totalMembers')) {
            totalMembers = _parseDouble(trends['totalMembers']);
          } else if (trends.containsKey('total_members')) {
            totalMembers = _parseDouble(trends['total_members']);
          } else if (trends.containsKey('members')) {
            totalMembers = _parseDouble(trends['members']);
          }

          if (trends.containsKey('activeMembers')) {
            activeMembers = _parseDouble(trends['activeMembers']);
          } else if (trends.containsKey('active_members')) {
            activeMembers = _parseDouble(trends['active_members']);
          }

          if (trends.containsKey('averageAttendance')) {
            averageAttendance = _parseDouble(trends['averageAttendance']);
          } else if (trends.containsKey('average_attendance')) {
            averageAttendance = _parseDouble(trends['average_attendance']);
          } else if (trends.containsKey('attendance_rate')) {
            averageAttendance = _parseDouble(trends['attendance_rate']);
          }

          if (trends.containsKey('eventsThisMonth')) {
            eventsThisMonth = _parseDouble(trends['eventsThisMonth']);
          } else if (trends.containsKey('events_this_month')) {
            eventsThisMonth = _parseDouble(trends['events_this_month']);
          } else if (trends.containsKey('monthly_events')) {
            eventsThisMonth = _parseDouble(trends['monthly_events']);
          }

          // If we got all the data we need, return it
          if (totalMembers > 0 && averageAttendance > 0 &&
              eventsThisMonth > 0) {
            return {
              'totalMembers': totalMembers,
              'activeMembers': activeMembers,
              'averageAttendance': averageAttendance,
              'eventsThisMonth': eventsThisMonth,
            };
          }
        }
      } catch (analyticsError) {
        print('Error getting analytics data from provider: $analyticsError');
        // Continue with manual calculation
      }

      // If analytics provider didn't have the data, calculate it manually

      // Get total members
      try {
        final members = await groupProvider.getGroupMembers(widget.groupId);
        totalMembers = members.length.toDouble();
      } catch (e) {
        print('Error getting group members: $e');
        totalMembers = 0.0;
      }

      // Calculate active members (members who attended at least one event in the last 30 days)
      try {
        // Fetch past events
        final pastEvents = await eventProvider.fetchPastEvents(widget.groupId);

        // Get events in the last 30 days
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final recentEvents = pastEvents.where((event) =>
        event.dateTime.isAfter(thirtyDaysAgo) && event.dateTime.isBefore(now)
        ).toList();

        // Track unique active members
        Set<String> activeUserIds = {};

        // Calculate average attendance
        if (pastEvents.isNotEmpty) {
          double totalAttendanceRate = 0.0;
          int eventsWithAttendance = 0;

          for (var event in pastEvents) {
            try {
              final attendanceList = await attendanceProvider
                  .fetchEventAttendance(event.id);
              if (attendanceList.isNotEmpty) {
                final presentCount = attendanceList
                    .where((a) => a.isPresent)
                    .length;
                final attendanceRate = (presentCount / attendanceList.length) *
                    100;
                totalAttendanceRate += attendanceRate;
                eventsWithAttendance++;

                // Add active users from recent events
                if (recentEvents.any((e) => e.id == event.id)) {
                  for (var attendance in attendanceList) {
                    if (attendance.isPresent) {
                      activeUserIds.add(attendance.userId);
                    }
                  }
                }
              }
            } catch (e) {
              print('Error processing attendance for event ${event.id}: $e');
              // Continue with next event
            }
          }

          if (eventsWithAttendance > 0) {
            averageAttendance = totalAttendanceRate / eventsWithAttendance;
          }

          // Set active members count
          activeMembers = activeUserIds.length.toDouble();
        }
      } catch (e) {
        print('Error calculating active members and attendance: $e');
        activeMembers = 0.0;
        averageAttendance = 0.0;
      }

      // Calculate events this month
      try {
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

        final pastEvents = await eventProvider.fetchPastEvents(widget.groupId);
        final upcomingEvents = eventProvider.upcomingEvents;
        final allEvents = [...pastEvents, ...upcomingEvents];

        eventsThisMonth = allEvents.where((event) {
          return event.dateTime.isAfter(
              firstDayOfMonth.subtract(const Duration(days: 1))) &&
              event.dateTime.isBefore(
                  lastDayOfMonth.add(const Duration(days: 1)));
        }).length.toDouble();
      } catch (e) {
        print('Error calculating events this month: $e');
        eventsThisMonth = 0.0;
      }

      return {
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'averageAttendance': averageAttendance,
        'eventsThisMonth': eventsThisMonth,
      };
    } catch (e) {
      print('Error calculating analytics data: $e');
      return {
        'totalMembers': 0.0,
        'activeMembers': 0.0,
        'averageAttendance': 0.0,
        'eventsThisMonth': 0.0,
      };
    }
  }

  // Helper method to parse various types to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Date and time for event creation
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _pageController.dispose();
    _refreshAnimationController.dispose();
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

  void _showAddMemberDialog() {
    final TextEditingController searchController = TextEditingController();
    List<UserModel> searchResults = [];
    UserModel? selectedUser;
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: Text(
                    'Add New Member',
                    style: TextStyles.heading2,
                  ),
                  content: Container(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search for members to add to your group',
                          style: TextStyles.bodyText,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or email',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) {
                                  // Clear selection when search query changes
                                  setDialogState(() {
                                    selectedUser = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (searchController.text.isEmpty) return;

                                setDialogState(() {
                                  isSearching = true;
                                });

                                try {
                                  final userProvider = Provider.of<
                                      UserProvider>(context, listen: false);
                                  final results = await userProvider
                                      .searchUsers(searchController.text);

                                  setDialogState(() {
                                    searchResults = results;
                                    isSearching = false;
                                  });
                                } catch (e) {
                                  print('Error searching users: $e');
                                  setDialogState(() {
                                    isSearching = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Search',
                                style: TextStyles.bodyText.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isSearching)
                          const Center(child: CircularProgressIndicator())
                        else
                          if (searchResults.isNotEmpty)
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 300),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = searchResults[index];
                                    final isSelected = selectedUser?.id ==
                                        user.id;

                                    return ListTile(
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      selected: isSelected,
                                      tileColor: isSelected ? AppColors
                                          .primaryColor.withOpacity(0.1) : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: isSelected
                                            ? BorderSide(
                                            color: AppColors.primaryColor,
                                            width: 1)
                                            : BorderSide.none,
                                      ),
                                      onTap: () {
                                        setDialogState(() {
                                          selectedUser = user;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            if (searchController.text.isNotEmpty)
                              Center(
                                child: Text(
                                  'No users found matching "${searchController
                                      .text}"',
                                  style: TextStyles.bodyText,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        searchController.dispose();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedUser == null ? null : () {
                        final groupProvider = Provider.of<GroupProvider>(
                            context, listen: false);

                        groupProvider.addMemberToGroup(
                            widget.groupId, selectedUser!.id).then((success) {
                          if (success) {
                            _showSuccess('${selectedUser!
                                .fullName} added to group successfully');
                            // Refresh the members list
                            _loadGroupMembers();
                          } else {
                            _showError('Failed to add ${selectedUser!
                                .fullName} to group');
                          }
                        });

                        searchController.dispose();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: AppColors.primaryColor
                            .withOpacity(0.5),
                      ),
                      child: Text(
                        'Add',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showCreateEventDialog() {
    // Create new controllers for each dialog instance
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    // Use local copies of date and time
    DateTime selectedDate = _selectedDate;
    TimeOfDay selectedTime = _selectedTime;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: Text(
                    'Create New Event',
                    style: TextStyles.heading2,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Event Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Date & Time',
                          style: TextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                        const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      selectedDate = date;
                                    });
                                    // Also update the parent state
                                    setState(() {
                                      _selectedDate = date;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  '${selectedDate.day}/${selectedDate
                                      .month}/${selectedDate.year}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      selectedTime = time;
                                    });
                                    // Also update the parent state
                                    setState(() {
                                      _selectedTime = time;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  '${selectedTime.hour}:${selectedTime.minute
                                      .toString().padLeft(2, '0')}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Just close the dialog, no need to clear controllers
                        Navigator.pop(context);

                        // Dispose controllers to prevent memory leaks
                        titleController.dispose();
                        descriptionController.dispose();
                        locationController.dispose();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Create event using provider
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            locationController.text.isEmpty) {
                          _showError('Please fill all fields');
                          return;
                        }

                        // Combine date and time
                        final DateTime eventDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Create new event
                        final eventProvider = Provider.of<EventProvider>(
                            context, listen: false);
                        eventProvider.createEvent(
                          groupId: widget.groupId,
                          title: titleController.text,
                          description: descriptionController.text,
                          dateTime: eventDateTime,
                          location: locationController.text,
                        );

                        // Close the dialog
                        Navigator.pop(context);

                        // Show success message
                        _showSuccess('Event created successfully');

                        // Refresh UI in the parent widget
                        setState(() {});

                        // Dispose controllers to prevent memory leaks
                        titleController.dispose();
                        descriptionController.dispose();
                        locationController.dispose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showMemberOptionsDialog(UserModel member) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              member.fullName,
              style: TextStyles.heading2,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to member profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MemberProfileScreen(
                              userId: member.id,
                              groupId: widget.groupId,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('View Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to member attendance screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MemberAttendanceScreen(
                              userId: member.id,
                              groupId: widget.groupId,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text('Remove from Group'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveMemberConfirmation(member);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showRemoveMemberConfirmation(UserModel member) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Remove Member'),
            content: Text('Are you sure you want to remove ${member
                .fullName} from this group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Remove member using provider
                  final groupProvider = Provider.of<GroupProvider>(
                      context, listen: false);
                  groupProvider.removeMemberFromGroup(widget.groupId, member.id)
                      .then((success) {
                    if (success) {
                      _showSuccess(
                          '${member.fullName} has been removed from the group');
                      // Refresh UI
                      setState(() {});
                    } else {
                      _showError(
                          'Failed to remove ${member.fullName} from the group');
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                    'Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showEventOptionsDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              event.title,
              style: TextStyles.heading2,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.visibility,
                    color: AppColors.primaryColor, // App theme color
                  ),
                  title: Text(
                    'View Details',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OverallEventDetailsScreen(
                              eventId: event.id,
                              eventTitle: event.title,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Event'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditEventDialog(event);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Event'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteEventConfirmation(event);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteEventConfirmation(EventModel event) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Event'),
            content: Text('Are you sure you want to delete "${event
                .title}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final eventProvider = Provider.of<EventProvider>(
                      context, listen: false);
                  eventProvider.deleteEvent(event.id, widget.groupId).then((
                      success) {
                    if (success) {
                      _showSuccess('Event deleted successfully');
                    } else {
                      _showError('Failed to delete event');
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showEditEventDialog(EventModel event) {
    // Create controllers and initialize with existing event data
    final TextEditingController titleController = TextEditingController(
        text: event.title);
    final TextEditingController descriptionController = TextEditingController(
        text: event.description);
    final TextEditingController locationController = TextEditingController(
        text: event.location);

    // Use event's date and time
    DateTime selectedDate = event.dateTime;
    TimeOfDay selectedTime = TimeOfDay(
      hour: event.dateTime.hour,
      minute: event.dateTime.minute,
    );

    showDialog(
      context: context,
      builder: (dialogContext) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: Text(
                    'Edit Event',
                    style: TextStyles.heading2,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Event Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Date & Time',
                          style: TextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                        const Duration(days: 365)),
                                    lastDate: DateTime.now().add(
                                        const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      selectedDate = date;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  '${selectedDate.day}/${selectedDate
                                      .month}/${selectedDate.year}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      selectedTime = time;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  '${selectedTime.hour}:${selectedTime.minute
                                      .toString().padLeft(2, '0')}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Just close the dialog
                        Navigator.pop(context);

                        // Dispose controllers to prevent memory leaks
                        titleController.dispose();
                        descriptionController.dispose();
                        locationController.dispose();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Update event using provider
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            locationController.text.isEmpty) {
                          _showError('Please fill all fields');
                          return;
                        }

                        // Combine date and time
                        final DateTime eventDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Update event
                        final eventProvider = Provider.of<EventProvider>(
                            context, listen: false);
                        eventProvider.updateEvent(
                          eventId: event.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          dateTime: eventDateTime,
                          location: locationController.text,
                          groupId: widget.groupId,
                        ).then((updatedEvent) {
                          if (updatedEvent != null) {
                            // Close the dialog
                            Navigator.pop(context);

                            // Show success message
                            _showSuccess('Event updated successfully');

                            // Refresh UI in the parent widget
                            setState(() {});
                          } else {
                            _showError('Failed to update event');
                          }
                        });

                        // Dispose controllers to prevent memory leaks
                        titleController.dispose();
                        descriptionController.dispose();
                        locationController.dispose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Update',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  // Helper method to format date nicely
  String _formatEventDate(DateTime dateTime) {
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final String weekday = weekdays[dateTime.weekday - 1];
    final String month = months[dateTime.month - 1];
    final String day = dateTime.day.toString();

    String hour = dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';

    if (dateTime.hour > 12) {
      hour = (dateTime.hour - 12).toString();
    } else if (dateTime.hour == 0) {
      hour = '12';
    }

    return '$weekday, $month $day at $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.groupName} Admin',
        showBackButton: true,
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
          _buildMembersTab(),
          _buildEventsTab(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
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
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // DASHBOARD TAB
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader('Group Members', Icons.people, () {
            _onItemTapped(1); // Navigate to Members tab
          }),
          const SizedBox(height: 16),
          _buildMembersList(showLimit: true),
          const SizedBox(height: 24),
          _buildSectionHeader('Upcoming Events', Icons.event, () {
            _onItemTapped(2); // Navigate to Events tab
          }),
          const SizedBox(height: 16),
          _buildUpcomingEventsList(showLimit: true),
          const SizedBox(height: 24),
          _buildSectionHeader('Attendance Overview', Icons.analytics, () {
            _onItemTapped(3); // Navigate to Analytics tab
          }),
          const SizedBox(height: 16),
          _buildAttendanceChart(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
                  Icons.groups,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Group Admin',
                        style: TextStyles.heading1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your ${widget
                            .groupName} group from this dashboard',
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
                _createQuickActionButton(
                  'Add Member',
                  Icons.person_add,
                      () {
                    _onItemTapped(1);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _showAddMemberDialog();
                    });
                  },
                ),
                _createQuickActionButton(
                  'Create Event',
                  Icons.event_available,
                      () {
                    _onItemTapped(2);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _showCreateEventDialog();
                    });
                  },
                ),
                _createQuickActionButton(
                  'Analytics',
                  Icons.analytics,
                      () => _onItemTapped(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createActionButton(String label, IconData icon, VoidCallback onTap) {
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

  Widget _createQuickActionButton(String label, IconData icon,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyles.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return FutureBuilder<Map<String, double>>(
      future: _analyticsData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        } else {
          final data = snapshot.data!;
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                  'Total Members', '${data['totalMembers']?.toInt()}',
                  Icons.people, AppColors.primaryColor),
              _buildStatCard(
                  'Active Members', '${data['activeMembers']?.toInt()}',
                  Icons.person_outline, AppColors.secondaryColor),
              _buildStatCard(
                  'Avg. Attendance', '${data['averageAttendance']?.toInt()}%',
                  Icons.trending_up, AppColors.accentColor),
              _buildStatCard(
                  'Events This Month', '${data['eventsThisMonth']?.toInt()}',
                  Icons.event, AppColors.buttonColor),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
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

  Widget _buildSectionHeader(String title, IconData icon,
      VoidCallback onSeeAll) {
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

  Widget _buildAttendanceChart() {
    return SizedBox(
      height: 250,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Attendance',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  DropdownButton<String>(
                    value: 'Last 6 Months',
                    items: const [
                      DropdownMenuItem(
                          value: 'Last 3 Months', child: Text('Last 3 Months')),
                      DropdownMenuItem(
                          value: 'Last 6 Months', child: Text('Last 6 Months')),
                      DropdownMenuItem(
                          value: 'Last Year', child: Text('Last Year')),
                    ],
                    onChanged: (value) {
                      // In a real app, this would update the chart data
                      _showInfo('Chart period changed to $value');
                    },
                    underline: Container(
                      height: 1,
                      color: _accentColor,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: _accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<AnalyticsProvider>(
                  builder: (context, analyticsProvider, _) {
                    final groupAttendanceTrends = analyticsProvider
                        .groupAttendanceTrends;

                    if (analyticsProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Use real data if available, otherwise use sample data
                    List<BarChartGroupData> barGroups = [];
                    List<String> months = [];

                    if (groupAttendanceTrends != null) {
                      try {
                        // Try to extract attendance data
                        List<dynamic>? attendanceData;

                        if (groupAttendanceTrends.containsKey('attendance') &&
                            groupAttendanceTrends['attendance'] is List) {
                          attendanceData =
                          groupAttendanceTrends['attendance'] as List;
                        } else
                        if (groupAttendanceTrends.containsKey('trends') &&
                            groupAttendanceTrends['trends'] is List) {
                          attendanceData =
                          groupAttendanceTrends['trends'] as List;
                        } else if (groupAttendanceTrends.containsKey(
                            'monthly') &&
                            groupAttendanceTrends['monthly'] is List) {
                          attendanceData =
                          groupAttendanceTrends['monthly'] as List;
                        } else if (groupAttendanceTrends.containsKey('data') &&
                            groupAttendanceTrends['data'] is List) {
                          attendanceData =
                          groupAttendanceTrends['data'] as List;
                        }

                        if (attendanceData != null &&
                            attendanceData.isNotEmpty) {
                          // Process the data
                          for (int i = 0; i < attendanceData.length; i++) {
                            final item = attendanceData[i];

                            if (item is Map) {
                              // Extract month name
                              String month = item['month'] ??
                                  item['period'] ??
                                  item['name'] ??
                                  'Month ${i + 1}';

                              // Extract attendance rate
                              double rate = 0.0;
                              final rateValue = item['rate'] ??
                                  item['attendance'] ??
                                  item['value'] ??
                                  item['percentage'];

                              if (rateValue is num) {
                                rate = rateValue.toDouble();
                              } else if (rateValue is String) {
                                rate = double.tryParse(rateValue) ?? 0.0;
                              }

                              // Add to chart data
                              months.add(month);
                              barGroups.add(_buildBarGroup(i, rate));
                            }
                          }
                        }
                      } catch (e) {
                        print('Error processing attendance chart data: $e');
                      }
                    }

                    // If no data or error, use sample data
                    if (barGroups.isEmpty) {
                      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      barGroups = [
                        _buildBarGroup(0, 75),
                        _buildBarGroup(1, 82),
                        _buildBarGroup(2, 88),
                        _buildBarGroup(3, 85),
                        _buildBarGroup(4, 92),
                        _buildBarGroup(5, 90),
                      ];
                    }

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
                                final index = value.toInt();
                                if (index >= 0 && index < months.length) {
                                  return Text(
                                    months[index],
                                    style: TextStyles.bodyText.copyWith(
                                      fontSize: 12,
                                      color: AppColors.textColor.withOpacity(
                                          0.7),
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
                                      color: AppColors.textColor.withOpacity(
                                          0.7),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: barGroups,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Attendance rate by month',
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 12,
                    color: Colors.grey,
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

  // MEMBERS TAB
  Widget _buildMembersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'All Members (${_groupMembers.length})',
                style: TextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: 'All',
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  // Filter members by status
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildMembersList(showLimit: false),
        ),
      ],
    );
  }

  Widget _buildMembersList({required bool showLimit}) {
    final displayMembers = showLimit && _groupMembers.length > 3
        ? _groupMembers.sublist(0, 3)
        : _groupMembers;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: displayMembers.length,
      shrinkWrap: true,
      physics: showLimit
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final member = displayMembers[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Text(
                member.fullName.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              member.fullName,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              member.email,
              style: TextStyles.bodyText.copyWith(
                fontSize: 14,
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMemberOptionsDialog(member),
            ),
            onTap: () => _showMemberOptionsDialog(member),
          ),
        );
      },
    );
  }

  // EVENTS TAB
  Widget _buildEventsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryColor,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUpcomingEventsList(showLimit: false),
                _buildPastEventsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsList({required bool showLimit}) {
    final displayEvents = showLimit && _upcomingEvents.length > 2
        ? _upcomingEvents.sublist(0, 2)
        : _upcomingEvents;

    return displayEvents.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Create Event',
            onPressed: _showCreateEventDialog,
            icon: Icons.add,
            color: AppColors.primaryColor,
            isFullWidth: false,
            horizontalPadding: 24,
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayEvents.length,
      shrinkWrap: true,
      physics: showLimit
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _showEventOptionsDialog(event),
            child: EventCard(
              eventTitle: event.title,
              eventDate: _formatEventDate(event.dateTime),
              eventLocation: event.location,
              onTap: () => _showEventOptionsDialog(event),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPastEventsList() {
    return _pastEvents.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No past events',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastEvents.length,
      itemBuilder: (context, index) {
        final event = _pastEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _showEventOptionsDialog(event),
            child: EventCard(
              eventTitle: event.title,
              eventDate: _formatEventDate(event.dateTime),
              eventLocation: event.location,
              onTap: () => _showEventOptionsDialog(event),
            ),
          ),
        );
      },
    );
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab() {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        if (_isLoading || analyticsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_errorMessage != null || analyticsProvider.errorMessage != null) {
          final errorMsg = _errorMessage ?? analyticsProvider.errorMessage;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAnalyticsData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Date Range:'),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: _updateDateRange,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${DateFormat('MMM d, y').format(
                                _selectedDateRange.start)} - '
                                '${DateFormat('MMM d, y').format(
                                _selectedDateRange.end)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Group Demographics
              if (analyticsProvider.groupDemographics != null) ...[
                _buildGroupDemographics(_convertGroupDemographicsToMap(
                    analyticsProvider.groupDemographics!)),
                const SizedBox(height: 16),
              ],

              // Group Attendance Stats
              if (analyticsProvider.groupAttendanceStats != null) ...[
                _buildGroupAttendanceStats(_convertGroupAttendanceStatsToMap(
                    analyticsProvider.groupAttendanceStats!)),
                const SizedBox(height: 16),
              ],

              // Member Participation Stats
              if (analyticsProvider.memberParticipationStats != null) ...[
                _buildMemberParticipationStats(
                    _convertMemberParticipationStatsToMap(
                        analyticsProvider.memberParticipationStats!)),
                const SizedBox(height: 16),
              ],

              // Event Participation Stats
              if (analyticsProvider.eventParticipationStats != null) ...[
                _buildEventParticipationStats(
                    _convertEventParticipationStatsToMap(
                            analyticsProvider.eventParticipationStats!)),
                const SizedBox(height: 16),
              ],

              // Export Options
              _buildExportOptions(analyticsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupDemographics(Map<String, dynamic> demographics) {
    // Extract values with fallbacks for different field names
    final totalMembers = demographics['totalMembers'] ??
        demographics['total_members'] ??
        demographics['members'] ??
        demographics['member_count'] ?? 0;

    final maleCount = demographics['maleCount'] ??
        demographics['male_count'] ??
        demographics['males'] ?? 0;

    final femaleCount = demographics['femaleCount'] ??
        demographics['female_count'] ??
        demographics['females'] ?? 0;

    final ageGroups = demographics['ageGroups'] ??
        demographics['age_groups'] ??
        demographics['age_distribution'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Demographics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Total Members',
                  totalMembers.toString(),
                  Icons.people,
                ),
                _buildSummaryStat(
                  'Male',
                  maleCount.toString(),
                  Icons.man,
                ),
                _buildSummaryStat(
                  'Female',
                  femaleCount.toString(),
                  Icons.woman,
                ),
              ],
            ),
            if (ageGroups is Map && ageGroups.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Age Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAgeDistributionChart(ageGroups),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgeDistributionChart(Map<dynamic, dynamic> ageGroups) {
    // Convert age groups to a format suitable for a chart
    List<MapEntry<String, dynamic>> entries = [];

    if (ageGroups is Map) {
      ageGroups.forEach((key, value) {
        if (key is String && (value is int || value is double)) {
          entries.add(MapEntry(key, value));
        }
      });
    }

    // Sort entries by age group
    entries.sort((a, b) {
      // Extract numbers from strings like "18-24", "25-34", etc.
      final aNum = int.tryParse(a.key
          .split('-')
          .first) ?? 0;
      final bNum = int.tryParse(b.key
          .split('-')
          .first) ?? 0;
      return aNum.compareTo(bNum);
    });

    if (entries.isEmpty) {
      return const Center(
        child: Text('No age distribution data available'),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: entries.map((e) => e.value as num).reduce((a, b) =>
          a > b
              ? a
              : b) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${entries[groupIndex].key}: ${rod.toY.round()}',
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
                  if (index >= 0 && index < entries.length) {
                    return Text(
                      entries[index].key,
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 10,
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
                  if (value % 5 == 0 && value > 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 10,
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
            entries.length,
                (index) =>
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entries[index].value.toDouble(),
                      color: AppColors.primaryColor,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAttendanceStats(Map<String, dynamic> stats) {
    // Extract values with fallbacks for different field names
    final averageAttendance = stats['averageAttendance'] ??
        stats['average_attendance'] ??
        stats['avg_attendance'] ?? 0.0;

    final totalAttendance = stats['totalAttendance'] ??
        stats['total_attendance'] ??
        stats['attendance_count'] ?? 0;

    final attendanceRate = stats['attendanceRate'] ??
        stats['attendance_rate'] ??
        stats['rate'] ?? 0.0;

    final attendanceTrend = stats['attendanceTrend'] ??
        stats['attendance_trend'] ??
        stats['trend'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Average',
                  '${averageAttendance.toStringAsFixed(1)}',
                  Icons.people,
                ),
                _buildSummaryStat(
                  'Total',
                  totalAttendance.toString(),
                  Icons.groups,
                ),
                _buildSummaryStat(
                  'Rate',
                  '${(attendanceRate * 100).toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ],
            ),
            if (attendanceTrend is List && attendanceTrend.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Attendance Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAttendanceTrendChart(attendanceTrend),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTrendChart(List<dynamic> trend) {
    // Convert trend data to a format suitable for a chart
    List<FlSpot> spots = [];
    List<String> labels = [];

    for (int i = 0; i < trend.length; i++) {
      final item = trend[i];
      if (item is Map) {
        final value = item['value'] ??
            item['attendance'] ??
            item['count'] ?? 0.0;

        final label = item['label'] ??
            item['date'] ??
            item['period'] ??
            'Period ${i + 1}';

        if (value is num) {
          spots.add(FlSpot(i.toDouble(), value.toDouble()));
          labels.add(label.toString());
        }
      }
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text('No attendance trend data available'),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final label = index >= 0 && index < labels.length
                      ? labels[index]
                      : '';
                  return LineTooltipItem(
                    '$label: ${spot.y.toInt()}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length && index % 2 == 0) {
                    return Text(
                      labels[index],
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 10,
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
                  if (value % 10 == 0 && value > 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 10,
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberParticipationStats(Map<String, dynamic> stats) {
    // Extract values with fallbacks for different field names
    final activeMembers = stats['activeMembers'] ??
        stats['active_members'] ??
        stats['active'] ?? 0;

    final inactiveMembers = stats['inactiveMembers'] ??
        stats['inactive_members'] ??
        stats['inactive'] ?? 0;

    final participationRate = stats['participationRate'] ??
        stats['participation_rate'] ??
        stats['rate'] ?? 0.0;

    final topMembers = stats['topMembers'] ??
        stats['top_members'] ??
        stats['most_active'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Member Participation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Active',
                  activeMembers.toString(),
                  Icons.person,
                ),
                _buildSummaryStat(
                  'Inactive',
                  inactiveMembers.toString(),
                  Icons.person_off,
                ),
                _buildSummaryStat(
                  'Rate',
                  '${(participationRate * 100).toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ],
            ),
            if (topMembers is List && topMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Most Active Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTopMembersList(topMembers),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopMembersList(List<dynamic> members) {
    if (members.isEmpty) {
      return const Center(
        child: Text('No member data available'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(members.length, 5), // Show at most 5 members
      itemBuilder: (context, index) {
        final member = members[index];
        String name = 'Unknown';
        String metric = '0';

        if (member is Map) {
          name = member['name'] ??
              member['fullName'] ??
              member['full_name'] ??
              member['username'] ??
              'Member ${index + 1}';

          final value = member['value'] ??
              member['attendance'] ??
              member['participation'] ??
              member['score'] ?? 0;

          metric = value is num ? value.toString() : value.toString();
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(name),
          trailing: Text(
            metric,
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventParticipationStats(Map<String, dynamic> stats) {
    // Extract values with fallbacks for different field names
    final totalEvents = stats['totalEvents'] ??
        stats['total_events'] ??
        stats['events'] ?? 0;

    final attendedEvents = stats['attendedEvents'] ??
        stats['attended_events'] ??
        stats['attended'] ?? 0;

    final participationRate = stats['participationRate'] ??
        stats['participation_rate'] ??
        stats['rate'] ?? 0.0;

    final popularEvents = stats['popularEvents'] ??
        stats['popular_events'] ??
        stats['top_events'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Participation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Total Events',
                  totalEvents.toString(),
                  Icons.event,
                ),
                _buildSummaryStat(
                  'Attended',
                  attendedEvents.toString(),
                  Icons.event_available,
                ),
                _buildSummaryStat(
                  'Rate',
                  '${(participationRate * 100).toStringAsFixed(1)}%',
                  Icons.percent,
                ),
              ],
            ),
            if (popularEvents is List && popularEvents.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Popular Events',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPopularEventsList(popularEvents),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPopularEventsList(List<dynamic> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No event data available'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(events.length, 5), // Show at most 5 events
      itemBuilder: (context, index) {
        final event = events[index];
        String title = 'Unknown Event';
        String metric = '0';
        String date = '';

        if (event is Map) {
          title = event['title'] ??
              event['name'] ??
              event['event_name'] ??
              'Event ${index + 1}';

          final value = event['value'] ??
              event['attendance'] ??
              event['participants'] ??
              event['count'] ?? 0;

          metric = value is num ? value.toString() : value.toString();

          // Try to extract date
          final dateValue = event['date'] ??
              event['dateTime'] ??
              event['event_date'] ?? '';

          if (dateValue is String && dateValue.isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(dateValue);
              date = DateFormat('MMM d, y').format(parsedDate);
            } catch (e) {
              date = dateValue;
            }
          }
        }

        return ListTile(
          leading: const Icon(Icons.event, color: AppColors.primaryColor),
          title: Text(title),
          subtitle: date.isNotEmpty ? Text(date) : null,
          trailing: Text(
            metric,
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> metrics) {
    // Extract values with fallbacks for different field names
    final attendanceRate = metrics['attendanceRate'] ??
        metrics['attendance_rate'] ??
        metrics['attendance'] ??
        metrics['attendance_percentage'] ?? 0.0;

    final memberGrowth = metrics['memberGrowth'] ??
        metrics['member_growth'] ??
        metrics['growth'] ??
        metrics['growth_rate'] ?? 0.0;

    final eventParticipation = metrics['eventParticipation'] ??
        metrics['event_participation'] ??
        metrics['participation'] ??
        metrics['participation_rate'] ?? 0.0;

    // Convert to double if needed
    double attendanceRateDouble = attendanceRate is double
        ? attendanceRate
        : double.tryParse(attendanceRate.toString()) ?? 0.0;
    double memberGrowthDouble = memberGrowth is double ? memberGrowth : double
        .tryParse(memberGrowth.toString()) ?? 0.0;
    double eventParticipationDouble = eventParticipation is double
        ? eventParticipation
        : double.tryParse(eventParticipation.toString()) ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  'Attendance Rate',
                  '${attendanceRateDouble.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
                _buildMetricCard(
                  'Member Growth',
                  '${memberGrowthDouble.toStringAsFixed(1)}%',
                  Icons.person_add,
                ),
                _buildMetricCard(
                  'Event Participation',
                  '${eventParticipationDouble.toStringAsFixed(1)}%',
                  Icons.event_available,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularEvents(Map<String, dynamic> events) {
    // Handle different response formats
    List<dynamic> popularEventsList = [];

    try {
      if (events.containsKey('events') && events['events'] is List) {
        popularEventsList = events['events'];
      } else if (events.containsKey('items') && events['items'] is List) {
        popularEventsList = events['items'];
      } else if (events.containsKey('data') && events['data'] is List) {
        popularEventsList = events['data'];
      } else if (events.containsKey('results') && events['results'] is List) {
        popularEventsList = events['results'];
      } else if (events.containsKey('popular_events') &&
          events['popular_events'] is List) {
        popularEventsList = events['popular_events'];
      } else {
        // Try to find any list in the map
        for (var key in events.keys) {
          final value = events[key];
          if (value is List && value.isNotEmpty) {
            // Check if the first item looks like an event
            if (value.first is Map) {
              final firstItem = value.first as Map;
              if (firstItem.containsKey('name') ||
                  firstItem.containsKey('title') ||
                  firstItem.containsKey('event_name') ||
                  firstItem.containsKey('attendance') ||
                  firstItem.containsKey('participationRate')) {
                popularEventsList = value;
                break;
              }
            }
          }
        }

        // If still empty, try any list
        if (popularEventsList.isEmpty) {
          for (var key in events.keys) {
            final value = events[key];
            if (value is List && value.isNotEmpty) {
              popularEventsList = value;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting popular events list: $e');
    }

    if (popularEventsList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Popular Events',
                    style: TextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No popular events data available',
                      style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Events will appear here once data is available',
                      style: TextStyles.bodyText.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Popular Events',
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(popularEventsList.length, 5), // Limit to 5 items
              itemBuilder: (context, index) {
                try {
                  final event = popularEventsList[index];
                  if (event is! Map) {
                    return const SizedBox.shrink();
                  }

                  // Convert to Map<String, dynamic> if needed
                  Map<String, dynamic> eventMap;
                  if (event is Map<String, dynamic>) {
                    eventMap = event;
                  } else {
                    eventMap = {};
                    event.forEach((key, value) {
                      eventMap[key.toString()] = value;
                    });
                  }

                  // Handle different field names
                  final name = eventMap['name'] ??
                      eventMap['title'] ??
                      eventMap['event_name'] ??
                      eventMap['eventName'] ??
                      'Event ${index + 1}';

                  final attendance = _parseNumeric(eventMap['attendance']) ??
                      _parseNumeric(eventMap['attendees']) ??
                      _parseNumeric(eventMap['count']) ??
                      _parseNumeric(eventMap['participants']) ??
                      0;

                  final rate = _parseNumeric(eventMap['participationRate']) ??
                      _parseNumeric(eventMap['rate']) ??
                      _parseNumeric(eventMap['percentage']) ??
                      _parseNumeric(eventMap['attendance_rate']) ??
                      0.0;

                  return Card(
                    elevation: 0,
                    color: index.isEven ? Colors.grey[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          name.toString(),
                          style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Attendance: $attendance members',
                          style: TextStyles.bodyText.copyWith(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rate is double
                                ? rate.toStringAsFixed(1)
                                : rate}%',
                            style: TextStyles.bodyText.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  print('Error rendering event at index $index: $e');
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to parse numeric values from various formats
  dynamic _parseNumeric(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      try {
        if (value.contains('.')) {
          return double.parse(value);
        } else {
          return int.parse(value);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAttendanceByCategory(Map<String, dynamic> categories) {
    // Handle different response formats
    List<dynamic> categoryList = [];

    try {
      if (categories.containsKey('categories') &&
          categories['categories'] is List) {
        categoryList = categories['categories'];
      } else
      if (categories.containsKey('items') && categories['items'] is List) {
        categoryList = categories['items'];
      } else if (categories.containsKey('data') && categories['data'] is List) {
        categoryList = categories['data'];
      } else
      if (categories.containsKey('results') && categories['results'] is List) {
        categoryList = categories['results'];
      } else if (categories.containsKey('event_categories') &&
          categories['event_categories'] is List) {
        categoryList = categories['event_categories'];
      } else {
        // Try to find any list in the map
        for (var key in categories.keys) {
          final value = categories[key];
          if (value is List && value.isNotEmpty) {
            // Check if the first item looks like a category
            if (value.first is Map) {
              final firstItem = value.first as Map;
              if (firstItem.containsKey('name') ||
                  firstItem.containsKey('category') ||
                  firstItem.containsKey('type') ||
                  firstItem.containsKey('totalEvents') ||
                  firstItem.containsKey('attendanceRate')) {
                categoryList = value;
                break;
              }
            }
          }
        }

        // If still empty, try any list
        if (categoryList.isEmpty) {
          for (var key in categories.keys) {
            final value = categories[key];
            if (value is List && value.isNotEmpty) {
              categoryList = value;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting category list: $e');
    }

    if (categoryList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance by Event Category',
                    style: TextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 48,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No category data available',
                      style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Categories will appear here once data is available',
                      style: TextStyles.bodyText.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Define category colors
    final List<Color> categoryColors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
      Colors.amber[400]!,
      Colors.indigo[400]!,
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Attendance by Event Category',
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(categoryList.length, 5), // Limit to 5 items
              itemBuilder: (context, index) {
                try {
                  final category = categoryList[index];
                  if (category is! Map) {
                    return const SizedBox.shrink();
                  }

                  // Convert to Map<String, dynamic> if needed
                  Map<String, dynamic> categoryMap;
                  if (category is Map<String, dynamic>) {
                    categoryMap = category;
                  } else {
                    categoryMap = {};
                    category.forEach((key, value) {
                      categoryMap[key.toString()] = value;
                    });
                  }

                  // Handle different field names
                  final name = categoryMap['name'] ??
                      categoryMap['category'] ??
                      categoryMap['type'] ??
                      categoryMap['categoryName'] ??
                      'Category ${index + 1}';

                  final totalEvents = _parseNumeric(
                      categoryMap['totalEvents']) ??
                      _parseNumeric(categoryMap['events']) ??
                      _parseNumeric(categoryMap['count']) ??
                      _parseNumeric(categoryMap['event_count']) ??
                      0;

                  final rate = _parseNumeric(categoryMap['attendanceRate']) ??
                      _parseNumeric(categoryMap['rate']) ??
                      _parseNumeric(categoryMap['percentage']) ??
                      _parseNumeric(categoryMap['attendance_rate']) ??
                      0.0;

                  final color = categoryColors[index % categoryColors.length];

                  return Card(
                    elevation: 0,
                    color: index.isEven ? Colors.grey[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Icon(
                            _getCategoryIcon(name.toString()),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name.toString(),
                          style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Total Events: $totalEvents',
                          style: TextStyles.bodyText.copyWith(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rate is double
                                ? rate.toStringAsFixed(1)
                                : rate}%',
                            style: TextStyles.bodyText.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  print('Error rendering category at index $index: $e');
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get an icon for a category based on its name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('worship') || name.contains('prayer')) {
      return Icons.music_note;
    } else if (name.contains('study') || name.contains('bible') ||
        name.contains('class')) {
      return Icons.book;
    } else if (name.contains('meeting') || name.contains('conference')) {
      return Icons.people;
    } else if (name.contains('youth') || name.contains('children')) {
      return Icons.child_care;
    } else if (name.contains('service') || name.contains('sunday')) {
      return Icons.church;
    } else if (name.contains('outreach') || name.contains('mission')) {
      return Icons.volunteer_activism;
    } else if (name.contains('social') || name.contains('fellowship')) {
      return Icons.groups;
    } else {
      return Icons.event;
    }
  }

  // Helper method to convert GroupAttendanceStats to Map<String, dynamic>
  Map<String, dynamic> _convertGroupAttendanceStatsToMap(
      GroupAttendanceStats stats) {
    return {
      'averageAttendance': stats.averageAttendance,
      'attendanceTrend': stats.attendanceTrend,
      'attendanceByDayOfWeek': stats.attendanceByDayOfWeek,
      'totalSessions': stats.totalSessions,
      'growthRate': stats.growthRate,
    };
  }

  Widget _buildMemberEngagement(Map<String, dynamic> engagement) {
    // Handle different response formats
    List<dynamic> engagementList = [];

    try {
      if (engagement.containsKey('scores') && engagement['scores'] is List) {
        engagementList = engagement['scores'];
      } else
      if (engagement.containsKey('items') && engagement['items'] is List) {
        engagementList = engagement['items'];
      } else
      if (engagement.containsKey('members') && engagement['members'] is List) {
        engagementList = engagement['members'];
      } else if (engagement.containsKey('data') && engagement['data'] is List) {
        engagementList = engagement['data'];
      } else
      if (engagement.containsKey('results') && engagement['results'] is List) {
        engagementList = engagement['results'];
      } else if (engagement.containsKey('engagement_scores') &&
          engagement['engagement_scores'] is List) {
        engagementList = engagement['engagement_scores'];
      } else {
        // Try to find any list in the map
        for (var key in engagement.keys) {
          final value = engagement[key];
          if (value is List && value.isNotEmpty) {
            // Check if the first item looks like a member engagement score
            if (value.first is Map) {
              final firstItem = value.first as Map;
              if (firstItem.containsKey('memberName') ||
                  firstItem.containsKey('name') ||
                  firstItem.containsKey('full_name') ||
                  firstItem.containsKey('engagementScore') ||
                  firstItem.containsKey('score')) {
                engagementList = value;
                break;
              }
            }
          }
        }

        // If still empty, try any list
        if (engagementList.isEmpty) {
          for (var key in engagement.keys) {
            final value = engagement[key];
            if (value is List && value.isNotEmpty) {
              engagementList = value;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting member engagement list: $e');
    }

    if (engagementList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Member Engagement',
                    style: TextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, size: 48,
                        color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No member engagement data available',
                      style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Member engagement scores will appear here once data is available',
                      style: TextStyles.bodyText.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Member Engagement',
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(engagementList.length, 5), // Limit to 5 items
              itemBuilder: (context, index) {
                try {
                  final score = engagementList[index];
                  if (score is! Map) {
                    return const SizedBox.shrink();
                  }

                  // Convert to Map<String, dynamic> if needed
                  Map<String, dynamic> scoreMap;
                  if (score is Map<String, dynamic>) {
                    scoreMap = score;
                  } else {
                    scoreMap = {};
                    score.forEach((key, value) {
                      scoreMap[key.toString()] = value;
                    });
                  }

                  // Handle different field names
                  final memberName = scoreMap['memberName'] ??
                      scoreMap['name'] ??
                      scoreMap['full_name'] ??
                      scoreMap['user_name'] ??
                      scoreMap['member'] ??
                      'Member ${index + 1}';

                  final groupName = scoreMap['groupName'] ??
                      scoreMap['group'] ??
                      scoreMap['group_name'] ??
                      widget.groupName;

                  final engagementScore = _parseNumeric(
                      scoreMap['engagementScore']) ??
                      _parseNumeric(scoreMap['score']) ??
                      _parseNumeric(scoreMap['engagement']) ??
                      _parseNumeric(scoreMap['value']) ??
                      _parseNumeric(scoreMap['engagement_score']) ??
                      0.0;

                  // Calculate a color based on the score
                  Color scoreColor;
                  if (engagementScore >= 80) {
                    scoreColor = Colors.green;
                  } else if (engagementScore >= 60) {
                    scoreColor = Colors.blue;
                  } else if (engagementScore >= 40) {
                    scoreColor = Colors.orange;
                  } else {
                    scoreColor = Colors.red;
                  }

                  return Card(
                    elevation: 0,
                    color: index.isEven ? Colors.grey[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryColor.withOpacity(
                              0.1),
                          child: Text(
                            memberName.toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          memberName.toString(),
                          style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Group: $groupName',
                          style: TextStyles.bodyText.copyWith(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Score: ${engagementScore is double
                                ? engagementScore.toStringAsFixed(1)
                                : engagementScore}',
                            style: TextStyles.bodyText.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  print(
                      'Error rendering member engagement at index $index: $e');
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberActivityLevels(Map<String, dynamic> activity) {
    // Handle different response formats
    List<dynamic> activityList = [];

    if (activity.containsKey('levels') && activity['levels'] is List) {
      activityList = activity['levels'];
    } else if (activity.containsKey('items') && activity['items'] is List) {
      activityList = activity['items'];
    } else
    if (activity.containsKey('activity') && activity['activity'] is List) {
      activityList = activity['activity'];
    } else {
      // Try to find any list in the map
      for (var value in activity.values) {
        if (value is List && value.isNotEmpty) {
          activityList = value;
          break;
        }
      }
    }

    if (activityList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Member Activity Levels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No activity level data available'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Member Activity Levels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activityList.length,
              itemBuilder: (context, index) {
                final level = activityList[index];
                // Handle different field names
                final levelName = level['level'] ?? level['name'] ??
                    level['activity_level'] ?? 'Level ${index + 1}';
                final memberCount = level['memberCount'] ?? level['count'] ??
                    level['members'] ?? 0;
                final percentage = level['percentage'] ?? level['rate'] ??
                    level['percent'] ?? 0.0;

                return ListTile(
                  title: Text(levelName),
                  subtitle: Text('Members: $memberCount'),
                  trailing: Text('${percentage is double
                      ? percentage.toStringAsFixed(1)
                      : percentage}%'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCorrelation(Map<String, dynamic> correlation) {
    // Handle different response formats
    List<dynamic> factorsList = [];

    if (correlation.containsKey('factors') && correlation['factors'] is List) {
      factorsList = correlation['factors'];
    } else
    if (correlation.containsKey('items') && correlation['items'] is List) {
      factorsList = correlation['items'];
    } else if (correlation.containsKey('correlations') &&
        correlation['correlations'] is List) {
      factorsList = correlation['correlations'];
    } else {
      // Try to find any list in the map
      for (var value in correlation.values) {
        if (value is List && value.isNotEmpty) {
          factorsList = value;
          break;
        }
      }
    }

    if (factorsList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Attendance Correlation Factors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No correlation data available'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Correlation Factors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: factorsList.length,
              itemBuilder: (context, index) {
                final factor = factorsList[index];
                // Handle different field names
                final factorName = factor['factor'] ?? factor['name'] ??
                    factor['type'] ?? 'Factor ${index + 1}';
                final impact = factor['impact'] ?? factor['effect'] ??
                    factor['significance'] ?? 'Medium';
                final correlationValue = factor['correlation'] ??
                    factor['value'] ?? factor['coefficient'] ?? 0.0;

                return ListTile(
                  title: Text(factorName),
                  subtitle: Text('Impact: $impact'),
                  trailing: Text(
                      '${correlationValue is double ? correlationValue
                          .toStringAsFixed(2) : correlationValue}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions(AnalyticsProvider analyticsProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Export Reports',
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                _buildExportButton(
                  label: 'Attendance Report',
                  icon: Icons.bar_chart,
                  onPressed: () => _exportAttendanceReport(analyticsProvider),
                  color: Colors.blue,
                ),
                _buildExportButton(
                  label: 'Member Report',
                  icon: Icons.people,
                  onPressed: () => _exportMemberReport(analyticsProvider),
                  color: Colors.green,
                ),
                _buildExportButton(
                  label: 'Group Report',
                  icon: Icons.groups,
                  onPressed: () => _exportGroupReport(analyticsProvider),
                  color: AppColors.primaryColor,
                ),
                _buildExportButton(
                  label: 'Analytics Dashboard',
                  icon: Icons.analytics,
                  onPressed: () => _exportAnalyticsDashboard(analyticsProvider),
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Export Format',
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFormatOption(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf,
                  isSelected: _selectedExportFormat == ExportFormat.pdf,
                  onTap: () =>
                      setState(() => _selectedExportFormat = ExportFormat.pdf),
                ),
                _buildFormatOption(
                  label: 'CSV',
                  icon: Icons.table_chart,
                  isSelected: _selectedExportFormat == ExportFormat.csv,
                  onTap: () =>
                      setState(() => _selectedExportFormat = ExportFormat.csv),
                ),
                _buildFormatOption(
                  label: 'Excel',
                  icon: Icons.table_view,
                  isSelected: _selectedExportFormat == ExportFormat.excel,
                  onTap: () => setState(() =>
                  _selectedExportFormat = ExportFormat.excel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyles.bodyText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors
              .transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey
                .withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyles.bodyText.copyWith(
                color: isSelected ? AppColors.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Export methods
  Future<void> _exportAttendanceReport(
      AnalyticsProvider analyticsProvider) async {
    setState(() => _isLoading = true);

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError('Storage permission is required to export reports');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get attendance data
      final attendanceStats = await analyticsProvider.fetchGroupAttendanceStats(
          widget.groupId);

      if (attendanceStats == null) {
        _showError('No attendance data available to export');
        setState(() => _isLoading = false);
        return;
      }

      // Convert GroupAttendanceStats to Map<String, dynamic>
      final attendanceData = _convertGroupAttendanceStatsToMap(attendanceStats);

      // Generate file based on selected format
      late String filePath;
      String fileName = 'attendance_report_${DateFormat('yyyyMMdd').format(
          DateTime.now())}';

      switch (_selectedExportFormat) {
        case ExportFormat.pdf:
          filePath = await _generatePdfReport(
              attendanceData, fileName, 'Attendance Report');
          break;
        case ExportFormat.csv:
          filePath = await _generateCsvReport(attendanceData, fileName);
          break;
        case ExportFormat.excel:
          filePath =
          await _generateCsvReport(attendanceData, fileName, isExcel: true);
          break;
      }

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Attendance Report');

      _showSuccess('Attendance report exported successfully');
    } catch (e) {
      print('Error exporting attendance report: $e');
      _showError('Failed to export attendance report: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportMemberReport(AnalyticsProvider analyticsProvider) async {
    setState(() => _isLoading = true);

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError('Storage permission is required to export reports');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get member data
      final memberData = await analyticsProvider
          .fetchMemberParticipationStats();

      if (memberData == null || memberData.isEmpty) {
        _showError('No member data available to export');
        setState(() => _isLoading = false);
        return;
      }

      // Generate file based on selected format
      late String filePath;
      String fileName = 'member_report_${DateFormat('yyyyMMdd').format(
          DateTime.now())}';

      switch (_selectedExportFormat) {
        case ExportFormat.pdf:
          filePath =
          await _generatePdfReport(memberData, fileName, 'Member Report');
          break;
        case ExportFormat.csv:
          filePath = await _generateCsvReport(memberData, fileName);
          break;
        case ExportFormat.excel:
          filePath =
          await _generateCsvReport(memberData, fileName, isExcel: true);
          break;
      }

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Member Report');

      _showSuccess('Member report exported successfully');
    } catch (e) {
      print('Error exporting member report: $e');
      _showError('Failed to export member report: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportGroupReport(AnalyticsProvider analyticsProvider) async {
    setState(() => _isLoading = true);

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError('Storage permission is required to export reports');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get group data
      final groupData = await analyticsProvider.fetchGroupDemographics(
          widget.groupId);

      if (groupData == null || groupData.isEmpty) {
        _showError('No group data available to export');
        setState(() => _isLoading = false);
        return;
      }

      // Generate file based on selected format
      late String filePath;
      String fileName = 'group_report_${DateFormat('yyyyMMdd').format(
          DateTime.now())}';

      switch (_selectedExportFormat) {
        case ExportFormat.pdf:
          filePath =
          await _generatePdfReport(groupData, fileName, 'Group Report');
          break;
        case ExportFormat.csv:
          filePath = await _generateCsvReport(groupData, fileName);
          break;
        case ExportFormat.excel:
          filePath =
          await _generateCsvReport(groupData, fileName, isExcel: true);
          break;
      }

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Group Report');

      _showSuccess('Group report exported successfully');
    } catch (e) {
      print('Error exporting group report: $e');
      _showError('Failed to export group report: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAnalyticsDashboard(
      AnalyticsProvider analyticsProvider) async {
    setState(() => _isLoading = true);

    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError('Storage permission is required to export reports');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Collect all analytics data
      final dashboardData = analyticsProvider.dashboardTrends;
      final performanceData = analyticsProvider.performanceMetrics;
      final attendanceData = analyticsProvider.attendanceByEventCategory;
      final popularEventsData = analyticsProvider.popularEvents;

      if (dashboardData == null || dashboardData.isEmpty) {
        _showError('No analytics data available to export');
        setState(() => _isLoading = false);
        return;
      }

      // Combine all data
      final combinedData = {
        'dashboardTrends': dashboardData,
        'performanceMetrics': performanceData,
        'attendanceByCategory': attendanceData,
        'popularEvents': popularEventsData,
      };

      // Generate file based on selected format
      late String filePath;
      String fileName = 'analytics_dashboard_${DateFormat('yyyyMMdd').format(
          DateTime.now())}';

      switch (_selectedExportFormat) {
        case ExportFormat.pdf:
          filePath = await _generatePdfReport(
              combinedData, fileName, 'Analytics Dashboard');
          break;
        case ExportFormat.csv:
          filePath = await _generateCsvReport(combinedData, fileName);
          break;
        case ExportFormat.excel:
          filePath =
          await _generateCsvReport(combinedData, fileName, isExcel: true);
          break;
      }

      // Share the file
      await Share.shareXFiles(
          [XFile(filePath)], text: 'Analytics Dashboard Report');

      _showSuccess('Analytics dashboard exported successfully');
    } catch (e) {
      print('Error exporting analytics dashboard: $e');
      _showError('Failed to export analytics dashboard: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper methods for generating reports
  Future<String> _generatePdfReport(dynamic data, String fileName,
      String title) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on ${DateFormat('MMMM d, y').format(
                      DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Group: ${widget.groupName}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add data pages
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Report Data',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: _buildPdfTableRows(data),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  List<pw.TableRow> _buildPdfTableRows(Map<String, dynamic> data) {
    final List<pw.TableRow> rows = [];

    // Add header row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey300,
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Key',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Value',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Add data rows
    data.forEach((key, value) {
      if (value is Map) {
        // Handle nested maps
        value.forEach((subKey, subValue) {
          rows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('$key - $subKey'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(subValue.toString()),
                ),
              ],
            ),
          );
        });
      } else if (value is List) {
        // Handle lists
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(key),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${value.length} items'),
              ),
            ],
          ),
        );
      } else {
        // Handle simple values
        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(key),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(value.toString()),
              ),
            ],
          ),
        );
      }
    });

    return rows;
  }

  Future<String> _generateCsvReport(dynamic data, String fileName,
      {bool isExcel = false}) async {
    final List<List<dynamic>> csvData = [];

    // Add header row
    csvData.add(['Key', 'Value']);

    // Add data rows
    data.forEach((key, value) {
      if (value is Map) {
        // Handle nested maps
        value.forEach((subKey, subValue) {
          csvData.add(['$key - $subKey', subValue.toString()]);
        });
      } else if (value is List) {
        // For lists, add a summary row
        csvData.add([key, '${value.length} items']);

        // Then add individual items if they are maps
        if (value.isNotEmpty && value.first is Map) {
          for (int i = 0; i < value.length; i++) {
            final item = value[i];
            if (item is Map) {
              item.forEach((itemKey, itemValue) {
                csvData.add(['$key[$i].$itemKey', itemValue.toString()]);
              });
            }
          }
        }
      } else {
        // Handle simple values
        csvData.add([key, value.toString()]);
      }
    });

    // Convert to CSV
    final String csv = const ListToCsvConverter().convert(csvData);

    // Save the CSV file
    final output = await getTemporaryDirectory();
    final extension = isExcel ? 'xlsx' : 'csv';
    final file = File('${output.path}/$fileName.$extension');
    await file.writeAsString(csv);

    return file.path;
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label),
          ],
        ),
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
          _buildSettingsSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              _buildThemeSelector(),
              const SizedBox(height: 16),
              _buildAccentColorSelector(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts about group activities'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeColor: _accentColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'Data & Sync',
            icon: Icons.sync,
            children: [
              SwitchListTile(
                title: const Text('Auto-Refresh Data'),
                subtitle: Text(
                    'Automatically refresh data every $_autoRefreshInterval minutes'),
                value: _autoRefreshEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoRefreshEnabled = value;
                  });
                  if (value) {
                    _setupAutoRefresh();
                  }
                },
                activeColor: _accentColor,
              ),
              if (_autoRefreshEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text('Refresh Interval: '),
                      Expanded(
                        child: Slider(
                          value: _autoRefreshInterval.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '$_autoRefreshInterval minutes',
                          onChanged: (value) {
                            setState(() {
                              _autoRefreshInterval = value.toInt();
                            });
                          },
                          activeColor: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ListTile(
                title: const Text('Refresh All Data Now'),
                subtitle: const Text('Update all dashboard information'),
                trailing: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(
                      _refreshAnimationController),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshData,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Backup Data'),
                subtitle: const Text('Create a backup of your group data'),
                trailing: const Icon(Icons.backup),
                onTap: () {
                  _showInfo(
                      'Backup feature will be available in the next update');
                },
              ),
              ListTile(
                title: const Text('Restore Data'),
                subtitle: const Text('Restore from a previous backup'),
                trailing: const Icon(Icons.restore),
                onTap: () {
                  _showInfo(
                      'Restore feature will be available in the next update');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'Analytics',
            icon: Icons.analytics,
            children: [
              SwitchListTile(
                title: const Text('Expanded Analytics'),
                subtitle: const Text('Show detailed analytics on dashboard'),
                value: _analyticsExpanded,
                onChanged: (value) {
                  setState(() {
                    _analyticsExpanded = value;
                  });
                },
                activeColor: _accentColor,
              ),
              ListTile(
                title: const Text('Clear Analytics Cache'),
                subtitle: const Text('Reset all analytics data'),
                trailing: const Icon(Icons.cleaning_services),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        AlertDialog(
                          title: const Text('Clear Analytics Cache'),
                          content: const Text(
                              'Are you sure you want to clear all cached analytics data? This will not affect your actual group data.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showSuccess('Analytics cache cleared');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Clear',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            title: 'About',
            icon: Icons.info,
            children: [
              ListTile(
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.system_update),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showInfo(
                      'Terms of Service will be available in the next update');
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showInfo(
                      'Privacy Policy will be available in the next update');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyles.heading2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Row(
      children: [
        const Text('Theme Mode:'),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {_isDarkMode},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isDarkMode = selection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccentColorSelector() {
    final List<Color> colorOptions = [
      AppColors.primaryColor,
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
    ];

    return Row(
      children: [
        const Text('Accent Color:'),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colorOptions.map((color) {
                final isSelected = _accentColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _accentColor = color;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                    )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 1) {
      // Members tab
      return FloatingActionButton(
        onPressed: _showAddMemberDialog,
        backgroundColor: _accentColor,
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
      );
    } else if (_selectedIndex == 2) {
      // Events tab
      return FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: _accentColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      );
    } else if (_selectedIndex == 0 || _selectedIndex == 3) {
      // Dashboard or Analytics tab - show refresh button
      return FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: _accentColor,
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(
              _refreshAnimationController),
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(); // No FAB for settings tab
  }

  // Conversion methods for analytics models

  /// Convert GroupDemographics to Map<String, dynamic>
  Map<String, dynamic> _convertGroupDemographicsToMap(
      GroupDemographics demographics) {
    return {
      'ageDistribution': demographics.ageDistribution,
      'genderDistribution': demographics.genderDistribution,
      'locationDistribution': demographics.locationDistribution,
      'additionalMetrics': demographics.additionalMetrics,
      // Add common field names for compatibility with the UI
      'age_distribution': demographics.ageDistribution,
      'gender_distribution': demographics.genderDistribution,
      'location_distribution': demographics.locationDistribution,
      'totalMembers': demographics.ageDistribution.values.fold(
          0, (sum, value) => sum + value),
      'maleCount': demographics.genderDistribution['male'] ?? 0,
      'femaleCount': demographics.genderDistribution['female'] ?? 0,
      'ageGroups': demographics.ageDistribution,
      'isEmpty': demographics.isEmpty,
      // Use the isEmpty property from the model
    };
  }

  // /// Convert GroupAttendanceStats to Map<String, dynamic>
  // Map<String, dynamic> _convertGroupAttendanceStatsToMap(GroupAttendanceStats stats) {
  //   return {
  //     'averageAttendance': stats.averageAttendance,
  //     'attendanceTrend': stats.attendanceTrend,
  //     'attendanceByDayOfWeek': stats.attendanceByDayOfWeek,
  //     'totalSessions': stats.totalSessions,
  //     'growthRate': stats.growthRate,
  //     // Add common field names for compatibility with the UI
  //     'average_attendance_rate': stats.averageAttendance,
  //     'attendance_by_month': stats.attendanceTrend,
  //     'total_events': stats.totalSessions,
  //     'totalAttendance': stats.attendanceByDayOfWeek.values.fold(0, (sum, value) => sum + value),
  //     'attendanceRate': stats.averageAttendance / 100,
  //     'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
  //   };
  // }
  //
  /// Convert MemberParticipationStats to Map<String, dynamic>
  Map<String, dynamic> _convertMemberParticipationStatsToMap(
      MemberParticipationStats stats) {
    // Calculate active and inactive members from top participants
    final activeMembers = stats.topParticipants.length;
    final inactiveMembers = stats
        .participationByDemographic['inactive_count'] ?? 0;

    return {
      'topParticipants': stats.topParticipants,
      'participationByDemographic': stats.participationByDemographic,
      'participationTrend': stats.participationTrend,
      'engagementMetrics': stats.engagementMetrics,
      // Add common field names for compatibility with the UI
      'top_members': stats.topParticipants,
      'participation_by_demographic': stats.participationByDemographic,
      'participation_trend': stats.participationTrend,
      'engagement_metrics': stats.engagementMetrics,
      'activeMembers': activeMembers,
      'inactiveMembers': inactiveMembers,
      'participationRate': stats.engagementMetrics['overall_rate'] ?? 0.75,
      'topMembers': stats.topParticipants,
      'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
    };
  }

  /// Convert EventParticipationStats to Map<String, dynamic>
  Map<String, dynamic> _convertEventParticipationStatsToMap(
      EventParticipationStats stats) {
    return {
      'totalParticipants': stats.totalParticipants,
      'participationRate': stats.participationRate,
      'participantDemographics': stats.participantDemographics,
      'participationTrend': stats.participationTrend,
      'feedback': stats.feedback,
      // Add common field names for compatibility with the UI
      'total_participants': stats.totalParticipants,
      'participation_rate': stats.participationRate,
      'participant_demographics': stats.participantDemographics,
      'participation_trend': stats.participationTrend,
      'totalEvents': stats.participationTrend.length,
      'attendedEvents': stats.totalParticipants,
      'popularEvents': stats.feedback['popular_events'] ?? [],
      'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
    };
  }



}
