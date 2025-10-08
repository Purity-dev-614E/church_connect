import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class OverallEventDetailsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OverallEventDetailsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<OverallEventDetailsScreen> createState() => _OverallEventDetailsScreenState();
}

class _OverallEventDetailsScreenState extends State<OverallEventDetailsScreen> {
  late Future<Map<String, dynamic>> _eventDataFuture;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _eventDataFuture = _fetchEventData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchEventData() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    try {
      // Fetch event details
      final event = await eventProvider.fetchEventById(widget.eventId);
      if (event == null) throw Exception('Event not found');

      // Fetch group members and convert JSON -> UserModel
      final groupMembersJson = await groupProvider.getGroupMembers(event.groupId);
      final groupMembers = groupMembersJson
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fetch attendance records
      final attendanceList = await attendanceProvider.fetchEventAttendance(widget.eventId);

      // Create a map of attendance by userId for quick lookup
      final Map<String, AttendanceModel> attendanceMap = {
        for (var record in attendanceList) record.userId: record
      };

      final attendees = <Map<String, dynamic>>[];
      final nonAttendees = <Map<String, dynamic>>[];

      // Process each group member
      for (final user in groupMembers) {
        final record = attendanceMap[user.id];
        final attendanceData = {
          'user': user,
          'attendance': record ??
              AttendanceModel(
                eventId: widget.eventId,
                userId: user.id,
                isPresent: false,
                apology: null,
                aob: null,
                topic: null,
              ),
        };

        if (record != null && record.isPresent) {
          attendees.add(attendanceData);
        } else {
          nonAttendees.add(attendanceData);
        }
      }

      return {
        'event': event,
        'attendees': attendees,
        'nonAttendees': nonAttendees,
        'groupMembers': groupMembers,
      };
    } catch (e) {
      print('Error in _fetchEventData: $e');
      return {
        'event': EventModel(
          id: widget.eventId,
          title: widget.eventTitle,
          description: 'Error loading event details',
          dateTime: DateTime.now(),
          location: 'Unknown',
          groupId: '',
        ),
        'attendees': <Map<String, dynamic>>[],
        'nonAttendees': <Map<String, dynamic>>[],
        'groupMembers': <UserModel>[],
        'error': e.toString(),
      };
    }
  }



  void _showAttendanceDetailsDialog(UserModel user, bool markAsPresent, {AttendanceModel? attendance}) {
   final aobController = TextEditingController(text: attendance?.aob);
   final topicController = TextEditingController(text: attendance?.topic);
   final apologyController = TextEditingController(text: attendance?.apology);

   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: Text(
         markAsPresent ? 'Mark Attendance' : 'Record Absence',
         style: TextStyles.heading2,
       ),
       content: SingleChildScrollView(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             ListTile(
               leading: CircleAvatar(
                 backgroundColor: AppColors.primaryColor,
                 child: Text(
                   user.fullName.substring(0, 1),
                   style: const TextStyle(color: Colors.white),
                 ),
               ),
               title: Text(user.fullName),
               subtitle: Text(user.email),
             ),
             const SizedBox(height: 16),
             if (markAsPresent) ...[
               TextField(
                 controller: aobController,
                 decoration: InputDecoration(
                   labelText: 'AOB',
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 maxLines: 2,
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: topicController,
                 decoration: InputDecoration(
                   labelText: 'Topic',
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 maxLines: 2,
               ),
             ] else
               TextField(
                 controller: apologyController,
                 decoration: InputDecoration(
                   labelText: 'Apology',
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 maxLines: 3,
               ),
           ],
         ),
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: Text(
             'Cancel',
             style: TextStyles.bodyText.copyWith(
               color: Theme.of(context).colorScheme.onBackground,
             ),
           ),
         ),
         ElevatedButton(
           onPressed: () {
             Navigator.pop(context);
             _markAttendance(
               user.id,
               markAsPresent,
               aob: aobController.text.isNotEmpty ? aobController.text : null,
               topic: topicController.text.isNotEmpty ? topicController.text : null,
               apology: apologyController.text.isNotEmpty ? apologyController.text : null,
             );
           },
           style: ElevatedButton.styleFrom(
             backgroundColor: AppColors.primaryColor,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8),
             ),
           ),
           child: Text(
             markAsPresent ? 'Mark as Present' : 'Record Absence',
             style: const TextStyle(color: Colors.white),
           ),
         ),
       ],
     ),
   );

   // Clean up controllers
   WidgetsBinding.instance.addPostFrameCallback((_) {
     aobController.dispose();
     topicController.dispose();
     apologyController.dispose();
   });
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

  Future<void> _markAttendance(String userId, bool present, {String? aob, String? topic, String? apology}) async {
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.markAttendance(
        eventId: widget.eventId,
        userId: userId,
        present: present,
        aob: aob,
        topic: topic,
        apology: apology,
      );
      
      // Refresh the data
      setState(() {
        _eventDataFuture = _fetchEventData();
      });
      
      _showSuccess(present ? 'Marked as present' : 'Marked as absent');
    } catch (e) {
      _showError('Error marking attendance: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle),
        backgroundColor: AppColors.primaryColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _eventDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final eventDetails = snapshot.data!['event'] as EventModel;

          final attendeesJson = snapshot.data!['attendees'] as List<dynamic>;
          final attendees = attendeesJson.map((e) => e as Map<String, dynamic>).toList();

          final nonAttendeesJson = snapshot.data!['nonAttendees'] as List<dynamic>;
          final nonAttendees = nonAttendeesJson.map((e) => e as Map<String, dynamic>).toList();

          final groupMembersJson = snapshot.data!['groupMembers'] as List<dynamic>;
          final groupMembers = groupMembersJson.map((e) => e as UserModel).toList();


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventDetailsCard(eventDetails),
                const SizedBox(height: 24),
                _buildAttendanceStats(attendees.length, nonAttendees.length),
                const SizedBox(height: 24),
                _buildSectionHeader('Attendees (${attendees.length})', Icons.check_circle),
                _buildUserList(attendees, isAttendee: true),
                const SizedBox(height: 24),
                _buildSectionHeader('Non-Attendees (${nonAttendees.length})', Icons.cancel),
                _buildUserList(nonAttendees, isAttendee: false),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final eventData = await _eventDataFuture;
          final groupMembers = eventData['groupMembers'] as List<UserModel>;
          _showMarkAttendanceDialog(context, groupMembers);
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Mark Attendance'),
      ),

    );
  }

  Widget _buildEventDetailsCard(EventModel event) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            _buildEventDetailRow(
              Icons.calendar_today,
              'Date',
              DateFormat('EEEE, MMMM d, y').format(event.dateTime),
            ),
            const SizedBox(height: 12),
            _buildEventDetailRow(
              Icons.access_time,
              'Time',
              DateFormat('h:mm a').format(event.dateTime),
            ),
            const SizedBox(height: 12),
            _buildEventDetailRow(
              Icons.location_on,
              'Location',
              event.location,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(int attendeesCount, int nonAttendeesCount) {
    final total = attendeesCount + nonAttendeesCount;
    final attendanceRate = total > 0 ? (attendeesCount / total * 100).round() : 0;

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
              'Attendance Overview',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', total.toString(), Icons.people),
                _buildStatItem('Attended', attendeesCount.toString(), Icons.check_circle),
                _buildStatItem('Not Attended', nonAttendeesCount.toString(), Icons.cancel),
                _buildStatItem('Rate', '$attendanceRate%', Icons.percent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyles.bodyText.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, {required bool isAttendee}) {
    if (users.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(top: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAttendee ? Icons.people_outline : Icons.person_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  isAttendee ? 'No attendees yet' : 'No absent members',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index]['user'] as UserModel;
        final attendance = users[index]['attendance'] as AttendanceModel;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isAttendee ? AppColors.primaryColor : Colors.red,
              child: Text(
                user.fullName.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isAttendee ? Icons.check_circle : Icons.cancel,
                    color: isAttendee ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    _showAttendanceDetailsDialog(user, !isAttendee);
                  },
                  tooltip: isAttendee ? 'Mark as absent' : 'Mark as present',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showAttendanceDetailsDialog(
                      user,
                      isAttendee,
                      attendance: attendance,
                    );
                  },
                  tooltip: 'Edit details',
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isAttendee
                      ? [
                          _buildDetailItem('AOB', attendance.aob ?? 'No AOB provided'),
                          const SizedBox(height: 8),
                          _buildDetailItem('Topic', attendance.topic ?? 'No topic provided'),
                        ]
                      : [
                          _buildDetailItem('Apology', attendance.apology ?? 'No apology provided'),
                        ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.bodyText.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyles.bodyText.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showMarkAttendanceDialog(BuildContext context, List<UserModel> groupMembers) {
    final Map<String, bool> isAbsentTapped = {}; // tracks which members have tapped "absent"
    final Map<String, TextEditingController> apologyControllers = {}; // stores apology text

    // Initialize controllers
    for (var user in groupMembers) {
      isAbsentTapped[user.id] = false;
      apologyControllers[user.id] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Mark Attendance', style: TextStyles.heading2),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: groupMembers.map((user) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          child: Text(
                            user.fullName.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () {
                                Navigator.pop(context);
                                _markAttendance(user.id, true); // mark present
                              },
                              tooltip: 'Mark as present',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  isAbsentTapped[user.id] = true; // show apology field
                                });
                              },
                              tooltip: 'Mark as absent',
                            ),
                          ],
                        ),
                      ),
                      if (isAbsentTapped[user.id] == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: apologyControllers[user.id],
                                decoration: const InputDecoration(
                                  labelText: 'Apology (optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // close dialog
                                    _markAttendance(
                                      user.id,
                                      false,
                                      apology: apologyControllers[user.id]!.text, // send apology
                                    );
                                  },
                                  child: const Text('Save Absent'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}