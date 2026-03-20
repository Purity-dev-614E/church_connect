import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/services/member_activity_service.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
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
  State<OverallEventDetailsScreen> createState() =>
      _OverallEventDetailsScreenState();
}

class _OverallEventDetailsScreenState extends State<OverallEventDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _eventDataFuture;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  List<UserModel> _unmarkedMembers = [];

  // Local state for real-time updates
  EventModel? _event;
  List<Map<String, dynamic>> _attendees = [];
  List<Map<String, dynamic>> _nonAttendees = [];
  List<Map<String, dynamic>> _nonAttendeesWithApology = [];
  List<Map<String, dynamic>> _nonAttendeesWithoutApology = [];
  List<UserModel> _groupMembers = [];
  bool _isLoading = true;
  String? _error;

  // Tab controller for absentees
  late TabController _absenteesTabController;

  // User role and permissions
  String? _userRole;
  String? _userRegionId;
  String? _userGroupId; // Added to track user's group for admin permissions
  bool _canManageAttendance = false;

  @override
  void initState() {
    super.initState();
    _absenteesTabController = TabController(length: 2, vsync: this);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final userServices = UserServices();
      final role = await userServices.getUserRole();
      final regionId = await userServices.getUserRegionId();

      // Get current user details to find their group
      final userId = await userServices.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      final currentUser = await userServices.fetchCurrentUser(userId);
      final groupId =
          currentUser
              .citam_Assembly; // Using citam_Assembly as group ID for admins

      if (mounted) {
        setState(() {
          _userRole = role;
          _userRegionId = regionId;
          _userGroupId = groupId;
        });
      }

      // Load event data after getting user role
      _loadEventData();
    } catch (e) {
      print('Error loading user role: $e');
      // Still load event data even if role loading fails
      _loadEventData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _absenteesTabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _fetchEventData();
      setState(() {
        _event = data['event'] as EventModel;
        _attendees =
            (data['attendees'] as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList();
        _nonAttendees =
            (data['nonAttendees'] as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList();

        // Split non-attendees by apology status
        _nonAttendeesWithApology =
            _nonAttendees.where((record) {
              final attendance = record['attendance'] as AttendanceModel;
              return attendance.apology != null &&
                  attendance.apology!.isNotEmpty;
            }).toList();

        _nonAttendeesWithoutApology =
            _nonAttendees.where((record) {
              final attendance = record['attendance'] as AttendanceModel;
              return attendance.apology == null || attendance.apology!.isEmpty;
            }).toList();

        _groupMembers =
            (data['groupMembers'] as List<dynamic>)
                .map((e) => e as UserModel)
                .toList();
        _unmarkedMembers =
            (data['unmarkedMembers'] as List<dynamic>)
                .map((e) => e as UserModel)
                .toList();

        // Check attendance management permissions
        _checkAttendancePermissions();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _checkAttendancePermissions() {
    print('=== Attendance Permission Check ===');
    print('User Role: $_userRole');
    print('User Region ID: $_userRegionId');
    print('Event ID: ${_event?.id}');
    print('Event isLeadership: ${_event?.isLeadershipEvent}');
    print('Event regionalId: ${_event?.regionalId}');
    print('Event targetAudience: ${_event?.targetAudience}');

    if (_event == null || _userRole == null) {
      print('❌ Missing event or user role');
      _canManageAttendance = false;
      return;
    }

    // Admin (Group Leaders) can only manage attendance for their own group events
    if (RoleUtils.isAdmin(_userRole)) {
      if (_event!.isLeadershipEvent) {
        // Admins cannot manage leadership events (only super admin and above)
        print('❌ Admin cannot manage leadership events');
        _canManageAttendance = false;
      } else {
        // For regular events, check if this event belongs to their group
        _canManageAttendance =
            _event!.groupId != null &&
            _event!.groupId!.isNotEmpty &&
            _event!.groupId == _userGroupId;
        print('✅ Admin regular event permission: $_canManageAttendance');
      }
      return;
    }

    // Super admins and root users can manage all events
    if (RoleUtils.isSuperAdmin(_userRole) || RoleUtils.isRoot(_userRole)) {
      print('✅ Super admin/root has full permission');
      _canManageAttendance = true;
      return;
    }

    // Regional managers can manage:
    // 1. Leadership events in their region
    // 2. Regular events for groups in their region
    if (RoleUtils.isRegionalLeadership(_userRole)) {
      if (_event!.isLeadershipEvent) {
        // For leadership events, check if event targets their region
        final regionMatches = _event!.regionalId == _userRegionId;
        final eventHasNoRegion =
            _event!.regionalId == null || _event!.regionalId!.isEmpty;

        print('Regional Manager - Leadership Event:');
        print('  - Region matches: $regionMatches');
        print('  - Event has no region: $eventHasNoRegion');
        print('  - User region: $_userRegionId');
        print('  - Event region: ${_event!.regionalId}');

        // Allow regional managers to manage leadership events if:
        // 1. Event targets their specific region, OR
        // 2. Event is for all regions (null/empty regionalId), OR
        // 3. Event target_audience is 'all' or 'rc_only'
        final canManage =
            regionMatches ||
            eventHasNoRegion ||
            _event!.targetAudience == 'all' ||
            _event!.targetAudience == 'rc_only';

        print('✅ Regional Manager leadership permission: $canManage');
        _canManageAttendance = canManage;
      } else {
        // For regular events, they would need to check if the group is in their region
        // This is more complex and would require additional group lookup
        // For now, allow regional managers to manage regular events
        print('✅ Regional Manager regular event permission: true');
        _canManageAttendance = true;
      }
      return;
    }

    // Other roles cannot manage attendance
    print('❌ Role $_userRole cannot manage attendance');
    _canManageAttendance = false;
  }

  Future<Map<String, dynamic>> _fetchEventData() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    try {
      // Fetch event details
      final event = await eventProvider.fetchEventById(widget.eventId);
      if (event == null) throw Exception('Event not found');

      // Handle leadership events vs regular events
      List<UserModel> groupMembers = [];

      if (event.isLeadershipEvent) {
        // For leadership events, use the new endpoint that handles role-based filtering automatically
        print('Loading leadership event attendees using new endpoint...');
        print('  - Event ID: ${widget.eventId}');
        print('  - User role: $_userRole');
        print('  - User regionId: $_userRegionId');

        // The backend will automatically apply the conditional logic based on:
        // - User role (RM, admin, super admin)
        // - Event target_audience ('all', 'rc_only', 'regional')
        // - Event regional_id
        // - User region_id
        // - Optional user_tle filters

        // Optionally, we can pass user_tle values if needed for filtering
        // For now, we'll let the backend handle all the filtering logic
        final attendees = await eventProvider.fetchLeadershipAttendees(
          eventId: widget.eventId,
          // userTle: ['admin', 'regional_manager'], // Optional: uncomment if needed
        );

        print('Leadership attendees loaded: ${attendees.length}');
        for (int i = 0; i < attendees.length && i < 3; i++) {
          final attendee = attendees[i];
          print(
            '  ${i + 1}. ${attendee.fullName} (${attendee.role}) - Region: ${attendee.regionId}',
          );
        }

        groupMembers = attendees;
      } else {
        // For regular events, get group members
        if (event.groupId == null || event.groupId!.isEmpty) {
          throw Exception('Group ID is required for regular events');
        }
        final groupMembersJson = await groupProvider.getGroupMembers(
          event.groupId!,
        );
        groupMembers =
            groupMembersJson
                .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
                .toList();
      }

      // Fetch attendance records
      final attendanceList = await attendanceProvider.fetchEventAttendance(
        widget.eventId,
      );

      // Create a map of attendance by userId for quick lookup
      final Map<String, AttendanceModel> attendanceMap = {
        for (var record in attendanceList) record.userId: record,
      };

      final attendees = <Map<String, dynamic>>[];
      final nonAttendees = <Map<String, dynamic>>[];
      final unmarkedMembers = <UserModel>[];

      // Process each group member
      for (final user in groupMembers) {
        final record = attendanceMap[user.id];

        if (record != null) {
          // Member has been marked
          final attendanceData = {'user': user, 'attendance': record};

          if (record.isPresent) {
            attendees.add(attendanceData);
          } else {
            nonAttendees.add(attendanceData);
          }
        } else {
          // Member hasn't been marked yet
          unmarkedMembers.add(user);
        }
      }

      return {
        'event': event,
        'attendees': attendees,
        'nonAttendees': nonAttendees,
        'groupMembers': groupMembers,
        'unmarkedMembers': unmarkedMembers,
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
          createdAt: DateTime.now(),
        ),
        'attendees': <Map<String, dynamic>>[],
        'nonAttendees': <Map<String, dynamic>>[],
        'groupMembers': <UserModel>[],
        'unmarkedMembers': <UserModel>[],
        'error': e.toString(),
      };
    }
  }

  void _showAttendanceDetailsDialog(
    UserModel user,
    bool markAsPresent, {
    AttendanceModel? attendance,
  }) {
    final apologyController = TextEditingController(text: attendance?.apology);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              markAsPresent ? 'Mark as Present' : 'Record Absence',
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Marking ${user.fullName} as present',
                              style: TextStyles.bodyText.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: apologyController,
                      decoration: InputDecoration(
                        labelText: 'Apology (optional)',
                        hintText: 'Enter reason for absence...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  apologyController.dispose();
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
                onPressed: () {
                  final apologyText =
                      markAsPresent
                          ? null
                          : (apologyController.text.isNotEmpty
                              ? apologyController.text
                              : null);
                  apologyController.dispose();
                  Navigator.pop(context);
                  _markAttendance(user.id, markAsPresent, apology: apologyText);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: markAsPresent ? Colors.green : Colors.red,
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

  Future<void> _markAttendance(
    String userId,
    bool present, {
    String? apology,
  }) async {
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // Use different attendance marking based on event type
      if (_event?.isLeadershipEvent == true) {
        // Use leadership attendance endpoint
        await eventProvider.markLeadershipAttendance(
          eventId: widget.eventId,
          userId: userId,
          present: present,
          notes: apology,
        );
      } else {
        // Use regular attendance endpoint
        await attendanceProvider.markAttendance(
          eventId: widget.eventId,
          userId: userId,
          present: present,
          aob: null, // Admin doesn't need to provide AOB
          topic: null, // Admin doesn't need to provide topic
          apology: apology,
        );
      }

      // Update local state immediately
      _updateLocalState(userId, present, apology);

      _showSuccess(present ? 'Marked as present' : 'Marked as absent');

      // Check inactivity rules (6 consecutive without apology or 12 consecutive with apology)
      // Only apply to regular group events, not leadership events
      if (_event != null &&
          _event!.groupId != null &&
          _event!.groupId!.isNotEmpty) {
        MemberActivityService()
            .checkAndMarkInactiveAfterAttendance(_event!.groupId!)
            .ignore();
      }
    } catch (e) {
      _showError('Error marking attendance: $e');
    }
  }

  void _updateLocalState(String userId, bool present, String? apology) {
    // Find the user in unmarked members
    final userIndex = _unmarkedMembers.indexWhere((user) => user.id == userId);
    if (userIndex == -1) return;

    final user = _unmarkedMembers[userIndex];

    // Create attendance record
    final attendance = AttendanceModel(
      eventId: widget.eventId,
      userId: userId,
      isPresent: present,
      apology: apology,
      aob: null,
      topic: null,
    );

    // Remove from unmarked members
    setState(() {
      _unmarkedMembers.removeAt(userIndex);

      // Add to appropriate list
      if (present) {
        _attendees.add({'user': user, 'attendance': attendance});
      } else {
        _nonAttendees.add({'user': user, 'attendance': attendance});

        // Also update the split lists
        if (apology != null && apology.isNotEmpty) {
          _nonAttendeesWithApology.add({
            'user': user,
            'attendance': attendance,
          });
        } else {
          _nonAttendeesWithoutApology.add({
            'user': user,
            'attendance': attendance,
          });
        }
      }
    });
  }

  Widget _buildUnmarkedMembersList(List<UserModel> unmarkedMembers) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children:
            unmarkedMembers.map((user) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color:
                            _event?.isAttendanceLocked == true ||
                                    !_canManageAttendance
                                ? Colors.grey
                                : Colors.green,
                      ),
                      onPressed:
                          _event?.isAttendanceLocked == true ||
                                  !_canManageAttendance
                              ? null
                              : () => _showAttendanceDetailsDialog(user, true),
                      tooltip:
                          _event?.isAttendanceLocked == true ||
                                  !_canManageAttendance
                              ? _event?.isAttendanceLocked == true
                                  ? 'Locked'
                                  : 'No Permission'
                              : 'Mark as present',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color:
                            _event?.isAttendanceLocked == true ||
                                    !_canManageAttendance
                                ? Colors.grey
                                : Colors.red,
                      ),
                      onPressed:
                          _event?.isAttendanceLocked == true ||
                                  !_canManageAttendance
                              ? null
                              : () => _showAttendanceDetailsDialog(user, false),
                      tooltip:
                          _event?.isAttendanceLocked == true ||
                                  !_canManageAttendance
                              ? _event?.isAttendanceLocked == true
                                  ? 'Locked'
                                  : 'No Permission'
                              : 'Mark as absent',
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle),
        backgroundColor: AppColors.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _event == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_event!.isAttendanceLocked) _buildLockedBanner(),
                    if (_event!.isAttendanceLocked) const SizedBox(height: 16),
                    _buildEventDetailsCard(_event!),
                    const SizedBox(height: 24),
                    if (_unmarkedMembers.isNotEmpty) ...[
                      _buildSectionHeader('Mark Attendance', Icons.person_add),
                      if (_event!.isAttendanceLocked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Attendance cannot be changed after 24 hours from the event start.\nNote: Leadership events can always be updated.',
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      _buildUnmarkedMembersList(_unmarkedMembers),
                      const SizedBox(height: 24),
                    ],
                    _buildAttendanceStats(
                      _attendees.length,
                      _nonAttendees.length,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Attendees (${_attendees.length})',
                      Icons.check_circle,
                    ),
                    _buildUserList(_attendees, isAttendee: true),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Non-Attendees (${_nonAttendees.length})',
                      Icons.cancel,
                    ),
                    if (_nonAttendees.isNotEmpty) ...[
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: TabBar(
                                controller: _absenteesTabController,
                                labelColor:
                                    Theme.of(context).colorScheme.onSurface,
                                unselectedLabelColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                indicator: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                tabs: const [
                                  Tab(
                                    text: 'With Apology',
                                    icon: Icon(Icons.note_alt, size: 16),
                                  ),
                                  Tab(
                                    text: 'No Apology',
                                    icon: Icon(Icons.person_off, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _absenteesTabController,
                                children: [
                                  // Tab 1: With Apology
                                  _buildUserList(
                                    _nonAttendeesWithApology,
                                    isAttendee: false,
                                    showApology: true,
                                  ),
                                  // Tab 2: Without Apology
                                  _buildUserList(
                                    _nonAttendeesWithoutApology,
                                    isAttendee: false,
                                    showApology: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attendance and changes are locked 24 hours after the event start time.\nNote: Leadership events can always be updated.',
              style: TextStyles.bodyText.copyWith(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsCard(EventModel event) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            _buildEventDetailRow(Icons.location_on, 'Location', event.location),
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
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
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
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(int attendeesCount, int nonAttendeesCount) {
    final total = attendeesCount + nonAttendeesCount;
    final attendanceRate =
        total > 0 ? (attendeesCount / total * 100).round() : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', total.toString(), Icons.people),
                _buildStatItem(
                  'Attended',
                  attendeesCount.toString(),
                  Icons.check_circle,
                ),
                _buildStatItem(
                  'Not Attended',
                  nonAttendeesCount.toString(),
                  Icons.cancel,
                ),
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
          style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildUserList(
    List<Map<String, dynamic>> users, {
    required bool isAttendee,
    bool showApology = false,
  }) {
    if (users.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(top: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAttendee ? Icons.people_outline : Icons.person_off,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  isAttendee ? 'No attendees yet' : 'No absent members',
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
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
              style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
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
                  children:
                      isAttendee
                          ? [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Present',
                                    style: TextStyles.bodyText.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                          : [
                            if (showApology)
                              _buildDetailItem(
                                'Apology',
                                attendance.apology ?? 'No apology provided',
                              ),
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
}
