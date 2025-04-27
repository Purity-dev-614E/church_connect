import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/features/events/event_details_screen.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/event_card.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class UserDashboard extends StatefulWidget {
  final String groupId;

  const UserDashboard({
    super.key,
    required this.groupId,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  // State variables
  String _userName = 'User';
  String _groupName = 'Loading...';
  List<EventModel> _weekEvents = [];
  List<EventModel> _allEvents = [];
  GroupModel? _currentGroup;

  // Loading states
  bool _isLoadingUser = true;
  bool _isLoadingGroup = true;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    // Schedule data loading after the current build is complete
    Future.microtask(() => _loadData());
    
    // Add a timeout to reset loading state if it takes too long
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && (_isLoadingUser || _isLoadingGroup)) {
        print('Loading timeout reached, resetting loading state');
        setState(() {
          _isLoadingUser = false;
          _isLoadingGroup = false;
        });
      }
    });
  }

  // Load all necessary data
  Future<void> _loadData() async {
    print('Starting _loadData');
    try {
      // Load data sequentially to avoid concurrent provider updates
      await _loadUserData();
      await _loadGroupData();
      await _loadEventData();
      print('All data loaded successfully');
    } catch (e) {
      print('Error loading data: $e');
      
      // Reset loading states if there was an error
      if (mounted) {
        setState(() {
          if (_isLoadingUser) _isLoadingUser = false;
          if (_isLoadingGroup) _isLoadingGroup = false;
          if (_isLoadingEvents) _isLoadingEvents = false;
        });
      }
    } finally {
      // Ensure loading states are reset even if there was an error
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isLoadingUser || _isLoadingGroup || _isLoadingEvents) {
            print('Forcing reset of loading states in finally block');
            setState(() {
              _isLoadingUser = false;
              _isLoadingGroup = false;
              _isLoadingEvents = false;
            });
          }
        });
      }
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    print('Starting _loadUserData');
    // Only set loading state if the widget is still mounted
    if (!mounted) {
      print('Widget not mounted in _loadUserData');
      return;
    }
    
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final userId = authProvider.currentUser?.id;
      print('User ID from auth provider: $userId');
      
      if (userId != null) {
        print('Loading user with ID: $userId');
        await userProvider.loadUser(userId);
        print('User loaded, current user: ${userProvider.currentUser?.fullName}');

        // Only update state if the widget is still mounted
        if (mounted && userProvider.currentUser != null) {
          setState(() {
            _userName = userProvider.currentUser!.fullName;
            _isLoadingUser = false;
          });
          print('User state updated, name: $_userName, loading: $_isLoadingUser');
        } else {
          print('Widget not mounted or user is null after loading');
          if (mounted) {
            setState(() {
              _isLoadingUser = false;
            });
          }
        }
      } else {
        print('User ID is null, cannot load user');
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  // Load group data
  Future<void> _loadGroupData() async {
    print('Starting _loadGroupData with groupId: ${widget.groupId}');
    // Only set loading state if the widget is still mounted
    if (!mounted) {
      print('Widget not mounted in _loadGroupData');
      return;
    }
    
    setState(() {
      _isLoadingGroup = true;
    });

    try {
      // Get the provider outside of the build context
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // Fetch the group data
      print('Fetching group with ID: ${widget.groupId}');
      final group = await groupProvider.getGroupById(widget.groupId);
      print('Group loaded: ${group?.name}');

      // Only update state if the widget is still mounted
      if (mounted && group != null) {
        setState(() {
          _currentGroup = group;
          _groupName = group.name;
          _isLoadingGroup = false;
        });
        print('Group state updated, name: $_groupName, loading: $_isLoadingGroup');
      } else {
        print('Widget not mounted or group is null after loading');
        if (mounted) {
          setState(() {
            _isLoadingGroup = false;
            _groupName = 'Group not found';
          });
        }
      }
    } catch (e) {
      print('Error loading group data: $e');
      
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoadingGroup = false;
          _groupName = 'Error loading group';
        });
      }
    }
  }

  // Load event data
  Future<void> _loadEventData() async {
    // Only set loading state if the widget is still mounted
    if (!mounted) return;
    
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // Set current group in provider
      eventProvider.setCurrentGroup(widget.groupId);

      // Load upcoming events
      await eventProvider.fetchUpcomingEvents(widget.groupId);

      // Get the current date
      final now = DateTime.now();

      // Calculate the date one week from now
      final oneWeekFromNow = now.add(const Duration(days: 7));

      // Filter upcoming events to get events for this week
      final weekEvents = eventProvider.upcomingEvents
          .where((event) => event.dateTime.isBefore(oneWeekFromNow))
          .toList();

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _weekEvents = weekEvents;
          _allEvents = eventProvider.upcomingEvents;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print('Error loading event data: $e');
      
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
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

  // Refresh all data
  Future<void> _refreshData() async {
    // Check if widget is mounted before starting refresh
    if (!mounted) return;
    
    await _loadData();
    
    // Check again if widget is still mounted after data load
    if (mounted) {
      _showSuccess('Data refreshed');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          event: event,
          groupId: widget.groupId,
        )
      )
    ).then((_) {
      // Refresh events when returning from event details
      // Use microtask to ensure we're not in the build phase
      if (mounted) {
        print('Returned from event details, refreshing events');
        Future.microtask(() => _loadEventData());
      }
    });
  }

  void _navigateToProfile() {
    // Navigate to profile page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen())
    ).then((_) {
      // Refresh user data when returning from profile screen
      // Use microtask to ensure we're not in the build phase
      if (mounted) {
        print('Returned from profile, refreshing user data');
        Future.microtask(() => _loadUserData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers for changes but with listen: false to avoid rebuild loops
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Use a post-frame callback to check for errors after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check for errors
      final hasEventError = eventProvider.errorMessage != null;
      final hasGroupError = groupProvider.errorMessage != null;

      // Show error notification if needed
      if (hasEventError && mounted) {
        _showError('Event error: ${eventProvider.errorMessage}');
        eventProvider.clearError();
      }

      if (hasGroupError && mounted) {
        _showError('Group error: ${groupProvider.errorMessage}');
        groupProvider.clearError();
      }
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: _isLoadingGroup ? 'User Dashboard' : _groupName,
        showBackButton: true,
        showProfileAvatar: true,
        onProfileTap: _navigateToProfile,
      ),
      body: _selectedIndex == 0
          ? _buildHomeTab()
          : _buildAllEventsTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'All Events',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to format date nicely
  String _formatEventDate(DateTime dateTime) {
    final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Ensure we're not in the build phase when refreshing
        await Future.microtask(() => _refreshData());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: _buildWelcomeCard(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Events This Week',
                    style: TextStyles.heading2.copyWith(
                      fontSize: 22,
                      color: AppColors.textColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _onItemTapped(1), // Switch to All Events tab
                    child: Text(
                      'See All',
                      style: TextStyles.bodyText.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _isLoadingEvents
              ? _buildLoadingEvents()
              : _weekEvents.isEmpty
                ? _buildEmptyEventsMessage('No events scheduled for this week')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _weekEvents.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final event = _weekEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: EventCard(
                          eventTitle: event.title,
                          eventDate: _formatEventDate(event.dateTime),
                          eventLocation: event.location,
                          onTap: () => _navigateToEventDetails(event),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build welcome card with fallback handling
  Widget _buildWelcomeCard() {
    // If loading, show loading card with timeout
    if (_isLoadingUser || _isLoadingGroup) {
      // Start a timer to force a fallback if loading takes too long
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && (_isLoadingUser || _isLoadingGroup)) {
          print('Loading card timeout reached, forcing fallback');
          setState(() {
            _isLoadingUser = false;
            _isLoadingGroup = false;
          });
        }
      });
      
      return Column(
        children: [
          _buildLoadingCard(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton(
              onPressed: () {
                print('Force refreshing data');
                setState(() {
                  _isLoadingUser = false;
                  _isLoadingGroup = false;
                });
                Future.microtask(() => _loadData());
              },
              child: Text(
                'Tap if stuck loading',
                style: TextStyles.bodyText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // If not loading, show the actual card
    return CardWidget(
      userName: _userName,
      icon: Icons.person,
      group_name: _groupName,
    );
  }

  // Loading card widget
  Widget _buildLoadingCard() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 6,
        shadowColor: AppColors.primaryColor.withOpacity(0.4),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.8),
                AppColors.secondaryColor.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyles.bodyText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading events widget
  Widget _buildLoadingEvents() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading events...',
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

  // Empty events message
  Widget _buildEmptyEventsMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
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

  Widget _buildAllEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'All Upcoming Events',
                style: TextStyles.heading2.copyWith(
                  fontSize: 22,
                  color: AppColors.textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Ensure we're not in the build phase when refreshing
                  Future.microtask(() => _loadEventData());
                },
                tooltip: 'Refresh events',
              ),
            ],
          ),
        ),
        _isLoadingEvents
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading events...',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _allEvents.isEmpty
                ? Expanded(
                    child: Center(
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
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Ensure we're not in the build phase when refreshing
                        await Future.microtask(() => _loadEventData());
                      },
                      child: ListView.builder(
                        itemCount: _allEvents.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemBuilder: (context, index) {
                          final event = _allEvents[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: EventCard(
                              eventTitle: event.title,
                              eventDate: _formatEventDate(event.dateTime),
                              eventLocation: event.location,
                              onTap: () => _navigateToEventDetails(event),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ],
    );
  }
}

//card widget for user
class CardWidget extends StatefulWidget {
  final String userName;
  final IconData icon;
  final String? group_name;

  const CardWidget({super.key, 
    required this.userName,
    required this.icon,
    this.group_name,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 6,
        shadowColor: AppColors.primaryColor.withOpacity(0.4),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withOpacity(0.8),
                AppColors.secondaryColor.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 0.1,
                        child: const Icon(
                          Icons.waving_hand,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Hello, ${widget.userName}',
                      style: TextStyles.heading2.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome to ${widget.group_name}',
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Check out your upcoming events below',
                  style: TextStyles.bodyText.copyWith(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
