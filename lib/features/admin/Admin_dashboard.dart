
import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/features/profile_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/event_card.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';

import '../../data/providers/user_provider.dart';

class AdminDashboard extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AdminDashboard({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

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
      final members = await groupProvider.getGroupMembers(widget.groupId);

      // Convert the dynamic list to UserModel list
      // Note: In a real app, you might need to adjust this conversion based on your API response
      final List<UserModel> userMembers = members.map((member) {
        // This assumes the member data structure matches UserModel
        // You might need to adjust this based on your actual API response
        return UserModel.fromJson(member);
      }).toList();

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

  @override
  void initState() {
    super.initState();
    // Load members when the widget initializes
    Future.microtask(() => _loadGroupMembers());
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
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    final totalMembers = (await groupProvider.getGroupMembers(widget.groupId)).length.toDouble();
    final activeMembers = (await userProvider.getAllUsers()).length.toDouble(); // Assuming this returns active members
    final averageAttendance = 0.0; // Replace with actual logic to get average attendance
    final eventsThisMonth = 0.0; // Replace with actual logic to get events this month

    return {
      'Total Members': totalMembers,
      'Active Members': activeMembers,
      'Average Attendance': averageAttendance,
      'Events This Month': eventsThisMonth,
    };

  }

  // Controllers for event creation form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Member',
          style: TextStyles.heading2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search for members to add to your group',
              style: TextStyles.bodyText,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // This is a simplified implementation
              // In a real app, you would first search for users and then select one

              // For now, we'll just show a success message
              // In a real implementation, you would:
              // 1. Get the selected user ID from the search results
              // 2. Use the GroupProvider to add the member

              final groupProvider = Provider.of<GroupProvider>(context, listen: false);

              // Mock implementation - in a real app, you would get the userId from selection
              String mockUserId = "new_user_id";

              groupProvider.addMemberToGroup(widget.groupId, mockUserId).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member added successfully')),
                  );
                  // Refresh UI
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add member')),
                  );
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
            child: Text(
              'Add',
              style: TextStyles.bodyText.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
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
                  controller: _locationController,
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
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
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
                _titleController.clear();
                _descriptionController.clear();
                _locationController.clear();
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
              onPressed: () {
                // Create event using provider
                if (_titleController.text.isEmpty ||
                    _descriptionController.text.isEmpty ||
                    _locationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                // Combine date and time
                final DateTime eventDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );

                // Create new event
                final eventProvider = Provider.of<EventProvider>(context, listen: false);
                eventProvider.createEvent(
                  groupId: widget.groupId,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dateTime: eventDateTime,
                  location: _locationController.text,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event created successfully')),
                );

                // Clear form
                _titleController.clear();
                _descriptionController.clear();
                _locationController.clear();

                // Refresh UI
                setState(() {});
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
      builder: (context) => AlertDialog(
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Attendance'),
              onTap: () {
                Navigator.pop(context);
                // Show member attendance
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
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.fullName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove member using provider
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              groupProvider.removeMemberFromGroup(widget.groupId, member.id).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.fullName} has been removed from the group')),
                  );
                  // Refresh UI
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove ${member.fullName} from the group')),
                  );
                }
              });

              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEventOptionsDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          event.title,
          style: TextStyles.heading2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to event details
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                // Show edit event dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Attendance'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to attendance management
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final eventProvider = Provider.of<EventProvider>(context, listen: false);
              eventProvider.deleteEvent(event.id, widget.groupId).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete event')),
                  );
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1 || _selectedIndex == 2
          ? FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 1) {
            _showAddMemberDialog();
          } else if (_selectedIndex == 2) {
            _showCreateEventDialog();
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          _selectedIndex == 1 ? Icons.person_add : Icons.add,
          color: Colors.white,
        ),
      )
          : null,
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
                        'Manage your ${widget.groupName} group from this dashboard',
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

  Widget _createQuickActionButton(String label, IconData icon, VoidCallback onTap) {
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
              _buildStatCard('Total Members', '${data['Total Members']?.toInt()}', Icons.people, AppColors.primaryColor),
              _buildStatCard('Active Members', '${data['Active Members']?.toInt()}', Icons.person_outline, AppColors.secondaryColor),
              _buildStatCard('Avg. Attendance', '${data['Average Attendance']?.toInt()}%', Icons.trending_up, AppColors.accentColor),
              _buildStatCard('Events This Month', '${data['Events This Month']?.toInt()}', Icons.event, AppColors.buttonColor),
            ],
          );
        }
      },
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

  Widget _buildAttendanceChart() {
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
                            const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                            if (value.toInt() >= 0 && value.toInt() < titles.length) {
                              return Text(
                                titles[value.toInt()],
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
                    barGroups: [
                      _buildBarGroup(0, 75),
                      _buildBarGroup(1, 82),
                      _buildBarGroup(2, 88),
                      _buildBarGroup(3, 85),
                      _buildBarGroup(4, 92),
                      _buildBarGroup(5, 90),
                    ],
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Analytics',
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
            'Monthly attendance rates',
            _buildAttendanceTrendChart(),
          ),
          const SizedBox(height: 24),

          // Member participation chart
          _buildAnalyticsCard(
            'Member Participation',
            'Attendance rates by member',
            _buildMemberParticipationChart(),
          ),
          const SizedBox(height: 24),

          // Event comparison
          _buildAnalyticsCard(
            'Event Comparison',
            'Attendance rates by event',
            _buildEventComparisonChart(),
          ),
          const SizedBox(height: 24),

          // Gender distribution
          _buildAnalyticsCard(
            'Gender Distribution',
            'Group demographics',
            _buildGenderDistributionChart(),
          ),
          const SizedBox(height: 32),

          // Export options
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Export as PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting as PDF...')),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting as CSV...')),
                  );
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

  Widget _buildAttendanceTrendChart() {
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
                const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
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
            spots: const [
              FlSpot(0, 75),
              FlSpot(1, 82),
              FlSpot(2, 88),
              FlSpot(3, 85),
              FlSpot(4, 92),
              FlSpot(5, 90),
            ],
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

  Widget _buildMemberParticipationChart() {
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
                const titles = ['John', 'Jane', 'Michael', 'Sarah', 'David'];
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
          _buildBarGroup(0, 95),
          _buildBarGroup(1, 82),
          _buildBarGroup(2, 78),
          _buildBarGroup(3, 90),
          _buildBarGroup(4, 85),
        ],
      ),
    );
  }

  Widget _buildEventComparisonChart() {
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

  Widget _buildGenderDistributionChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: AppColors.primaryColor,
            value: 60,
            title: 'Female\n60%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: AppColors.secondaryColor,
            value: 40,
            title: 'Male\n40%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
