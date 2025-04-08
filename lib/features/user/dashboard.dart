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
    _loadData();
  }

  // Load all necessary data
  Future<void> _loadData() async {
    await Future.wait([
      _loadUserData(),
      _loadGroupData(),
      _loadEventData(),
    ]);
  }

  // Load user data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        await userProvider.loadUser(userId);

        if (userProvider.currentUser != null) {
          setState(() {
            _userName = userProvider.currentUser!.fullName;
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // Load group data
  Future<void> _loadGroupData() async {
    setState(() {
      _isLoadingGroup = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final group = await groupProvider.getGroupById(widget.groupId);

      if (group != null) {
        setState(() {
          _currentGroup = group;
          _groupName = group.name;
          _isLoadingGroup = false;
        });
      }
    } catch (e) {
      print('Error loading group data: $e');
      setState(() {
        _isLoadingGroup = false;
      });
    }
  }

  // Load event data
  Future<void> _loadEventData() async {
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

      setState(() {
        _weekEvents = weekEvents;
        _allEvents = eventProvider.upcomingEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('Error loading event data: $e');
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data refreshed')),
      );
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
      _loadEventData();
    });
  }

  void _navigateToProfile() {
    // Navigate to profile page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen())
    ).then((_) {
      // Refresh user data when returning from profile screen
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to providers for changes
    final eventProvider = Provider.of<EventProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);

    // Check for errors
    final hasEventError = eventProvider.errorMessage != null;
    final hasGroupError = groupProvider.errorMessage != null;

    // Show error snackbar if needed
    if (hasEventError && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event error: ${eventProvider.errorMessage}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadEventData,
            ),
          ),
        );
        eventProvider.clearError();
      });
    }

    if (hasGroupError && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group error: ${groupProvider.errorMessage}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadGroupData,
            ),
          ),
        );
        groupProvider.clearError();
      });
    }

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
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingUser || _isLoadingGroup
                ? _buildLoadingCard()
                : CardWidget(
                    userName: _userName,
                    icon: Icons.person,
                    group_name: _groupName,
                  ),
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
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
                onPressed: _loadEventData,
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
                      onRefresh: _loadEventData,
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

  CardWidget({
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
