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
  bool _isLoading = true;
  String? _errorMessage;
  late AdminAnalyticsProvider _analyticsProvider;
  late SuperAdminAnalyticsProvider _superAdminAnalyticsProvider;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 180)),
    end: DateTime.now(),
  );

  // State variables for data
  Map<String, double> _analyticsData = {
    'totalMembers': 0.0,
    'activeMembers': 0.0,
    'eventsThisMonth': 0.0,
  };
  List<UserModel> _groupMembers = [];
  List<EventModel> _groupEvents = [];

  // Date and time selection
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

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

  // Getter for analytics data
  Map<String, double> get analyticsData => _analyticsData;

  // Getter for group members
  List<UserModel> get groupMembers => _groupMembers;

  // Getter for group events
  List<EventModel> get groupEvents => _groupEvents;

  // Getter for upcoming events
  List<EventModel> get _upcomingEvents {
    return _groupEvents.where((event) => event.dateTime.isAfter(DateTime.now())).toList();
  }

  // Getter for past events
  List<EventModel> get _pastEvents {
    return _groupEvents.where((event) => event.dateTime.isBefore(DateTime.now())).toList();
  }

  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<AdminAnalyticsProvider>(context, listen: false);
    _superAdminAnalyticsProvider = Provider.of<SuperAdminAnalyticsProvider>(context, listen: false);
    
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Move the page jump to didChangeDependencies to ensure PageView is ready
    if (_pageController.hasClients) {
      _pageController.jumpToPage(widget.initialTabIndex);
    }

    // Schedule data loading after the build is complete
    Future.microtask(() {
      if (mounted) {
        _loadInitialData();
      }
    });
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

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.wait([
        _loadAnalyticsData(),
        _loadGroupMembers(),
        _loadGroupEvents(),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryLoading() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    await _loadInitialData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      if (!mounted) return;
      
      print('Loading analytics data for group: ${widget.groupId}');
      
      // Get providers
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      // Get current date range for this month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      print('Fetching total members...');
      // Get total members
      final members = await groupProvider.getGroupMembers(widget.groupId);
      final totalMembers = members.length.toDouble();
      print('Total members found: $totalMembers');

      print('Fetching active members...');
      // Get active members (attended at least one event in last 30 days)
      final pastEvents = await eventProvider.fetchPastEvents(widget.groupId);
      final recentEvents = pastEvents.where((event) => 
        event.dateTime.isAfter(thirtyDaysAgo) && 
        event.dateTime.isBefore(now)
      ).toList();
      print('Found ${recentEvents.length} recent events');

      Set<String> activeUserIds = {};
      for (var event in recentEvents) {
        print('Checking attendance for event: ${event.title}');
        final attendanceList = await attendanceProvider.fetchEventAttendance(event.id);
        for (var attendance in attendanceList) {
          if (attendance.isPresent) {
            activeUserIds.add(attendance.userId);
          }
        }
      }
      final activeMembers = activeUserIds.length.toDouble();
      print('Active members found: $activeMembers');

      print('Fetching events this month...');
      // Get events this month
      final upcomingEvents = await eventProvider.getGroupEvents(widget.groupId);
      final allEvents = [...pastEvents, ...upcomingEvents];
      final eventsThisMonth = allEvents.where((event) => 
        event.dateTime.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
        event.dateTime.isBefore(lastDayOfMonth.add(const Duration(days: 1)))
      ).length.toDouble();
      print('Events this month: $eventsThisMonth');

      if (!mounted) return;
      
      setState(() {
        _analyticsData = {
          'totalMembers': totalMembers,
          'activeMembers': activeMembers,
          'eventsThisMonth': eventsThisMonth,
        };
        print('Analytics data updated: $_analyticsData');
      });
    } catch (e) {
      print('Error fetching analytics data: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error loading analytics data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadGroupMembers() async {
    try {
      if (!mounted) return;
      
      print('Loading group members for group: ${widget.groupId}');
      
      // Get provider
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // Get members
      final members = await groupProvider.getGroupMembers(widget.groupId);
      
      // Convert members to UserModel
      final userModels = members.map((member) {
        if (member is UserModel) {
          return member;
        } else if (member is Map<String, dynamic>) {
          return UserModel.fromJson(member);
        } else {
          print('Invalid member data type: ${member.runtimeType}');
          // Return a default UserModel for invalid data
          return UserModel(
            id: 'unknown',
            fullName: 'Unknown Member',
            email: '',
            contact: '',
            nextOfKin: '',
            nextOfKinContact: '',
            role: 'user',
            gender: '',
            regionId: '',
            regionalID: ''
          );
        }
      }).toList();
      
      if (mounted) {
        setState(() {
          _groupMembers = userModels;
        });
      }
    } catch (e) {
      print('Error loading group members: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading group members: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadGroupEvents() async {
    try {
      if (!mounted) return;
      
      // Load events directly
      final _eventProvider = Provider.of<EventProvider>(context, listen: false);
      final events = await _eventProvider.getGroupEvents(widget.groupId);
      
      if (!mounted) return;
      
      setState(() {
        _groupEvents = events;
      });
    } catch (e) {
      print('Error loading group events: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error loading group events: ${e.toString()}';
      });
    }
  }

  // Group members from provider
  List<UserModel> _cachedGroupMembers = [];
  bool _isLoadingMembers = false;

  @override
  void dispose() {
    _pageController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Use Future.microtask to ensure state update happens after build
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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

  void _showAddMemberDialog() {
    print('Starting member addition dialog for group: ${widget.groupId}');
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
                                  print('Search query changed: $value');
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
                                if (searchController.text.isEmpty) {
                                  print('Search attempted with empty query');
                                  return;
                                }

                                print('Initiating user search with query: ${searchController.text}');
                                setDialogState(() {
                                  isSearching = true;
                                });

                                try {
                                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                                  print('Fetching users from provider...');
                                  final results = await userProvider.searchUsers(searchController.text);
                                  print('Search completed. Found ${results.length} users');

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
                                    final isSelected = selectedUser?.id == user.id;

                                    return ListTile(
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      selected: isSelected,
                                      tileColor: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: isSelected
                                            ? BorderSide(color: AppColors.primaryColor, width: 1)
                                            : BorderSide.none,
                                      ),
                                      onTap: () {
                                        print('User selected: ${user.fullName} (${user.id})');
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
                                  'No users found matching "${searchController.text}"',
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
                        print('Member addition cancelled');
                        searchController.dispose();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyles.bodyText.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedUser == null ? null : () async {
                        print('Attempting to add member: ${selectedUser!.fullName} (${selectedUser!.id}) to group: ${widget.groupId}');
                        final groupProvider = Provider.of<GroupProvider>(context, listen: false);

                        try {
                          print('Sending request to add member...');
                          print('Request details:');
                          print('Group ID: ${widget.groupId}');
                          print('User ID: ${selectedUser!.id}');
                          print('User Name: ${selectedUser!.fullName}');
                          print('User Email: ${selectedUser!.email}');

                          final success = await groupProvider.addMemberToGroup(widget.groupId, selectedUser!.id);
                          
                          if (success) {
                            print('Member added successfully');
                            _showSuccess('${selectedUser!.fullName} added to group successfully');
                            // Refresh the members list
                            await _loadGroupMembers();
                          } else {
                            print('Failed to add member - success returned false');
                            _showError('Failed to add ${selectedUser!.fullName} to group');
                          }
                        } catch (e) {
                          print('Error adding member: $e');
                          print('Error type: ${e.runtimeType}');
                          print('Error details:');
                          if (e is Exception) {
                            print('Exception message: ${e.toString()}');
                          }
                          _showError('Error adding member: ${e.toString()}');
                        } finally {
                          searchController.dispose();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.5),
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
                          color: Theme.of(context).colorScheme.onBackground,
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
                      color: Theme.of(context).colorScheme.onBackground,
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
                          color: Theme.of(context).colorScheme.onBackground,
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
      body: StatefulBuilder(
        builder: (context, setLocalState) {
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
                    _errorMessage!,
                    style: TextStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      setLocalState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      await _loadInitialData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Use setLocalState instead of setState
              setLocalState(() {
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
          );
        },
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
        onTap: (index) {
          // Use Future.microtask to ensure state update happens after build
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _selectedIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        },
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return FutureBuilder<Map<String, double>>(
      future: _getDirectStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading statistics: ${snapshot.error}',
                  style: TextStyles.bodyText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
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
                'Total Members',
                '${data['totalMembers']?.toInt() ?? 0}',
                Icons.people,
                AppColors.primaryColor,
              ),
              _buildStatCard(
                'Active Members',
                '${data['activeMembers']?.toInt() ?? 0}',
                Icons.person_outline,
                AppColors.secondaryColor,
              ),
              _buildStatCard(
                'Events This Month',
                '${data['eventsThisMonth']?.toInt() ?? 0}',
                Icons.event,
                AppColors.buttonColor,
              ),
            ],
          );
        }
      },
    );
  }

  Future<Map<String, double>> _getDirectStatistics() async {
    try {
      // Get providers
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      // Get current date range for this month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get total members
      final members = await groupProvider.getGroupMembers(widget.groupId);
      final totalMembers = members.length.toDouble();

      // Get active members (attended at least one event in last 30 days)
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final pastEvents = await eventProvider.fetchPastEvents(widget.groupId);
      final recentEvents = pastEvents.where((event) => 
        event.dateTime.isAfter(thirtyDaysAgo) && 
        event.dateTime.isBefore(now)
      ).toList();

      Set<String> activeUserIds = {};
      for (var event in recentEvents) {
        final attendanceList = await attendanceProvider.fetchEventAttendance(event.id);
        for (var attendance in attendanceList) {
          if (attendance.isPresent) {
            activeUserIds.add(attendance.userId);
          }
        }
      }
      final activeMembers = activeUserIds.length.toDouble();

      // Get events this month
      final upcomingEvents = eventProvider.upcomingEvents;
      final allEvents = [...pastEvents, ...upcomingEvents];
      final eventsThisMonth = allEvents.where((event) => 
        event.dateTime.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
        event.dateTime.isBefore(lastDayOfMonth.add(const Duration(days: 1)))
      ).length.toDouble();

      return {
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'eventsThisMonth': eventsThisMonth,
      };
    } catch (e) {
      print('Error getting direct statistics: $e');
      return {
        'totalMembers': 0.0,
        'activeMembers': 0.0,
        'eventsThisMonth': 0.0,
      };
    }
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
                color: Theme.of(context).colorScheme.onBackground,
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
                'All Members (${groupMembers.length})',
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
    final displayMembers = showLimit && groupMembers.length > 3
        ? groupMembers.sublist(0, 3)
        : groupMembers;

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
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming events',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Create Event',
                  onPressed: _showCreateEventDialog,
                  icon: Icons.add,
                  color: Color(0xffc62828),
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
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No past events',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
              _buildThemeSelector(_isDarkMode,(bool newValue){
                setState(() {
                  _isDarkMode = newValue;
                });
              }),
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

  Widget _buildThemeSelector(bool? isDarkMode, Function(bool) onChanged) {
    // default to false if null for UI selection
    final selected = isDarkMode ?? WidgetsBinding.instance.window.platformBrightness == Brightness.dark;

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
            selected: {selected},
            onSelectionChanged: (Set<bool> selection) {
              onChanged(selection.first); // user overrides system
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

}
