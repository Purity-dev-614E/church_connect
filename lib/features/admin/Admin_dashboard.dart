import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/features/admin/screens/analytics_screen.dart';
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
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int initialTabIndex;

  const AdminDashboard({
    super.key,
    required this.groupId,
    required this.groupName,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  late AdminAnalyticsProvider _analyticsProvider;
  late SuperAdminAnalyticsProvider _superAdminAnalyticsProvider;
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


  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<AdminAnalyticsProvider>(context, listen: false);
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
        loadAnalytic('Fetch Dashboard Data', () =>
            _superAdminAnalyticsProvider.getGroupDashboardData(widget.groupId)
                .then((data) {
              // Process the data if needed
              print('Dashboard data loaded: $data');
            })
        ),
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

          loadAnalytic('Dashboard Data', () =>
            _superAdminAnalyticsProvider.getGroupDashboardData(widget.groupId)
          .then((data) {
            // Process the data if needed
            print('Dashboard data loaded for date range: $data');
          }))
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
        rethrow;
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
                regionId: memberMap['region_id'] ??
                    memberMap['regionId'] ?? '',
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
      _showInfo('No members found. Please refresh or try again later.');
      return [];
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
      final analyticsProvider = Provider.of<AdminAnalyticsProvider>(
          context, listen: false);

      // Initialize with default values
      double totalMembers = 0.0;
      double activeMembers = 0.0;
      double averageAttendance = 0.0;
      double eventsThisMonth = 0.0;

      // Try to get data from analytics provider first (more efficient)
      try {
        // Check if we have dashboard data from the analytics provider
          final trends = await _superAdminAnalyticsProvider.getGroupDashboardData(widget.groupId);

         totalMembers = trends.memberStats.totalMembers.toDouble();
         activeMembers = trends.memberStats.activeMembers.toDouble();
         eventsThisMonth = (trends.upcomingEvents as num).toDouble();

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
                  content: SizedBox(
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
             onPressed: () {
               print('Member passed to _showMemberOptionsDialog: ${member.fullName}, ID: ${member.id}');
               _showMemberOptionsDialog(member);
             },
            ),
            onTap: () {
              print('Member passed to _showMemberOptionsDialog: ${member
                  .fullName}, ID: ${member.id}');
              _showMemberOptionsDialog(member);
            },
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
    return AdminAnalyticsScreen(
      groupId: widget.groupId,
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
  //
  // /// Convert GroupDemographics to Map<String, dynamic>
  // Map<String, dynamic> _convertGroupDemographicsToMap(
  //     GroupDemographics demographics) {
  //   // Calculate total members from gender distribution
  //   int totalFromGender = demographics.genderDistribution.values.fold(
  //       0, (sum, value) => sum + value);
  //
  //   // Calculate total members from role distribution
  //   int totalFromRole = demographics.roleDistribution.values.fold(
  //       0, (sum, value) => sum + value);
  //
  //   // Use the larger value as the total members count
  //   int totalMembers = totalFromGender > 0 ? totalFromGender :
  //                     (totalFromRole > 0 ? totalFromRole :
  //                     demographics.ageDistribution.values.fold(0, (sum, value) => sum + value));
  //
  //   return {
  //     'ageDistribution': demographics.ageDistribution,
  //     'genderDistribution': demographics.genderDistribution,
  //     'roleDistribution': demographics.roleDistribution,
  //     'locationDistribution': demographics.locationDistribution,
  //     'additionalMetrics': demographics.additionalMetrics,
  //     // Add common field names for compatibility with the UI
  //     'age_distribution': demographics.ageDistribution,
  //     'gender_distribution': demographics.genderDistribution,
  //     'role_distribution': demographics.roleDistribution,
  //     'location_distribution': demographics.locationDistribution,
  //     'totalMembers': totalMembers,
  //     'maleCount': demographics.genderDistribution['male'] ?? 0,
  //     'femaleCount': demographics.genderDistribution['female'] ?? 0,
  //     'adminCount': demographics.roleDistribution['admin'] ?? 0,
  //     'userCount': demographics.roleDistribution['user'] ?? 0,
  //     'ageGroups': demographics.ageDistribution,
  //     'isEmpty': demographics.isEmpty,
  //     // Use the isEmpty property from the model
  //   };
  // }
  //
  // // /// Convert GroupAttendanceStats to Map<String, dynamic>
  // // Map<String, dynamic> _convertGroupAttendanceStatsToMap(GroupAttendanceStats stats) {
  // //   return {
  // //     'averageAttendance': stats.averageAttendance,
  // //     'attendanceTrend': stats.attendanceTrend,
  // //     'attendanceByDayOfWeek': stats.attendanceByDayOfWeek,
  // //     'totalSessions': stats.totalSessions,
  // //     'growthRate': stats.growthRate,
  // //     // Add common field names for compatibility with the UI
  // //     'average_attendance_rate': stats.averageAttendance,
  // //     'attendance_by_month': stats.attendanceTrend,
  // //     'total_events': stats.totalSessions,
  // //     'totalAttendance': stats.attendanceByDayOfWeek.values.fold(0, (sum, value) => sum + value),
  // //     'attendanceRate': stats.averageAttendance / 100,
  // //     'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
  // //   };
  // // }
  // //
  // /// Convert MemberParticipationStats to Map<String, dynamic>
  // Map<String, dynamic> _convertMemberParticipationStatsToMap(
  //     MemberParticipationStats stats) {
  //   // Calculate active and inactive members from top participants
  //   final activeMembers = stats.topParticipants.length;
  //   final inactiveMembers = stats
  //       .participationByDemographic['inactive_count'] ?? 0;
  //
  //   return {
  //     'topParticipants': stats.topParticipants,
  //     'participationByDemographic': stats.participationByDemographic,
  //     'participationTrend': stats.participationTrend,
  //     'engagementMetrics': stats.engagementMetrics,
  //     // Add common field names for compatibility with the UI
  //     'top_members': stats.topParticipants,
  //     'participation_by_demographic': stats.participationByDemographic,
  //     'participation_trend': stats.participationTrend,
  //     'engagement_metrics': stats.engagementMetrics,
  //     'activeMembers': activeMembers,
  //     'inactiveMembers': inactiveMembers,
  //     'participationRate': stats.engagementMetrics['overall_rate'] ?? 0.75,
  //     'topMembers': stats.topParticipants,
  //     'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
  //   };
  // }
  //
  // /// Convert EventParticipationStats to Map<String, dynamic>
  // Map<String, dynamic> _convertEventParticipationStatsToMap(
  //     EventParticipationStats stats) {
  //   // Format the event date for display
  //   String formattedDate = '';
  //   try {
  //     formattedDate = DateFormat('MMM d, y').format(stats.eventDate);
  //   } catch (e) {
  //     formattedDate = 'Unknown date';
  //   }
  //
  //   return {
  //     // New API fields
  //     'eventId': stats.eventId,
  //     'eventTitle': stats.eventTitle,
  //     'eventDate': stats.eventDate,
  //     'formattedEventDate': formattedDate,
  //     'totalPossible': stats.totalPossible,
  //     'presentCount': stats.presentCount,
  //     'absentCount': stats.absentCount,
  //     'attendanceRate': stats.attendanceRate / 100, // Convert percentage to decimal
  //
  //     // Legacy fields for backward compatibility
  //     'totalParticipants': stats.totalParticipants > 0 ? stats.totalParticipants : stats.presentCount,
  //     'participationRate': stats.participationRate > 0 ? stats.participationRate : stats.attendanceRate / 100,
  //     'participantDemographics': stats.participantDemographics,
  //     'participationTrend': stats.participationTrend,
  //     'feedback': stats.feedback,
  //
  //     // Add common field names for compatibility with the UI
  //     'total_participants': stats.totalParticipants > 0 ? stats.totalParticipants : stats.presentCount,
  //     'participation_rate': stats.participationRate > 0 ? stats.participationRate : stats.attendanceRate / 100,
  //     'participant_demographics': stats.participantDemographics,
  //     'participation_trend': stats.participationTrend,
  //     'totalEvents': 1, // Since we're now dealing with a single event
  //     'attendedEvents': stats.presentCount,
  //     'popularEvents': stats.feedback['popular_events'] ?? [],
  //     'isEmpty': stats.isEmpty, // Use the isEmpty property from the model
  //
  //     // Additional fields for the new UI
  //     'event_title': stats.eventTitle,
  //     'event_date': formattedDate,
  //     'total_possible': stats.totalPossible,
  //     'present_count': stats.presentCount,
  //     'absent_count': stats.absentCount,
  //     'attendance_rate': stats.attendanceRate,
  //   };
  // }
  //
  //

}
