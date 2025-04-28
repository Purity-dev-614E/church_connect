import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/event_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MemberAttendanceScreen extends StatefulWidget {
  final String userId;
  final String groupId;

  const MemberAttendanceScreen({
    super.key,
    required this.userId,
    required this.groupId,
  });

  @override
  State<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends State<MemberAttendanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _member;
  List<EventModel> _attendedEvents = [];
  List<EventModel> _unattendedEvents = [];
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get providers
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      // Load member details
      _member = await userProvider.getUserById(widget.userId);

      // Load all past events for the group
      final pastEvents = await eventProvider.fetchPastEvents(widget.groupId);

      // Load attendance records for the member
      final attendanceRecords = await attendanceProvider.getUserAttendanceRecords(widget.userId);

      // Convert records to AttendanceModel objects
      final List<AttendanceModel> attendanceModels = attendanceRecords;

      // Separate attended and unattended events
      final Set<String> attendedEventIds = attendanceModels
          .where((record) => record.isPresent)
          .map((record) => record.eventId)
          .toSet();

      _attendedEvents = pastEvents.where((event) => attendedEventIds.contains(event.id)).toList();
      _unattendedEvents = pastEvents.where((event) => !attendedEventIds.contains(event.id)).toList();

      // Calculate active status (attended at least one event in last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      _isActive = _attendedEvents.any((event) => event.dateTime.isAfter(thirtyDaysAgo));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading member data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatEventDate(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Member Attendance',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                        onPressed: _loadMemberData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryColor,
                                    radius: 30,
                                    child: Text(
                                      _member?.fullName.substring(0, 1) ?? '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _member?.fullName ?? 'Unknown Member',
                                          style: TextStyles.heading2,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _member?.email ?? 'No email',
                                          style: TextStyles.bodyText.copyWith(
                                            color: AppColors.textColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Active Status Card
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isActive ? Colors.green : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isActive ? Icons.check_circle : Icons.cancel,
                                      color: _isActive ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isActive ? 'Active Member' : 'Inactive Member',
                                      style: TextStyles.bodyText.copyWith(
                                        color: _isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Attendance Statistics
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Attended',
                              _attendedEvents.length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Missed',
                              _unattendedEvents.length.toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Attended Events Section
                      Text(
                        'Attended Events',
                        style: TextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      _attendedEvents.isEmpty
                          ? _buildEmptyState('No attended events found')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attendedEvents.length,
                              itemBuilder: (context, index) {
                                final event = _attendedEvents[index];
                                return EventCard(
                                  eventTitle: event.title,
                                  eventDate: _formatEventDate(event.dateTime),
                                  eventLocation: event.location,
                                  onTap: () {},
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                      // Unattended Events Section
                      Text(
                        'Missed Events',
                        style: TextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      _unattendedEvents.isEmpty
                          ? _buildEmptyState('No missed events found')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _unattendedEvents.length,
                              itemBuilder: (context, index) {
                                final event = _unattendedEvents[index];
                                return EventCard(
                                  eventTitle: event.title,
                                  eventDate: _formatEventDate(event.dateTime),
                                  eventLocation: event.location,
                                  onTap: () {},
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
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
    );
  }
}