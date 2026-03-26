import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'dart:convert';
import 'package:group_management_church_app/features/member/member_attendance_screen.dart';
import 'package:group_management_church_app/features/events/overall_event_details.dart';
import 'package:group_management_church_app/features/events/event_details_screen.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _members = [];
  List<EventModel> _events = [];
  List<RemovedMemberModel> _removedMembers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // Load members
      final members = await groupProvider.getActiveGroupMembers(widget.groupId);

      // Convert members to UserModel
      final userModels =
          members.map((member) {
            if (member is UserModel) {
              return member;
            } else if (member is Map<String, dynamic>) {
              return UserModel.fromJson(member);
            } else {
              throw Exception(
                'Invalid member data type: ${member.runtimeType}',
              );
            }
          }).toList();

      // Load events
      final events = await eventProvider.fetchEventsByGroup(widget.groupId);
      // Load removed members
      final removed = await groupProvider.getRemovedMembers(widget.groupId);

      if (mounted) {
        setState(() {
          _members = userModels;
          _events = events;
          _removedMembers = removed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
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

  bool _canRemoveMember() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return false;
    final role = RoleUtils.normalize(user.role);
    return role == 'root' ||
        role == 'super_admin' ||
        role == 'regional manager' ||
        role == 'admin';
  }

  Future<bool> _canManageGroup() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    return await groupProvider.canManageGroup(widget.groupId);
  }

  void _showRemoveMemberDialog(UserModel member) async {
    // Check if user can manage this specific group first
    final canManage = await _canManageGroup();
    if (!canManage) {
      _showError(
        'Access denied: This group is not in your region. You can only manage groups within your assigned region.',
      );
      return;
    }

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remove ${member.fullName} from this group? You must provide a reason.',
                      style: TextStyles.bodyText,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for removal *',
                        hintText: 'e.g. Relocated, requested removal...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a reason for removal';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final reason = reasonController.text.trim();

                  // Close the dialog and show loading
                  Navigator.pop(context);

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Removing member...'),
                            ],
                          ),
                        ),
                  );

                  final groupProvider = Provider.of<GroupProvider>(
                    context,
                    listen: false,
                  );
                  final success = await groupProvider
                      .removeMemberFromGroupWithReason(
                        widget.groupId,
                        member.id,
                        reason,
                      );

                  // Close loading dialog
                  if (mounted) {
                    Navigator.pop(context);

                    if (success) {
                      _showSuccess(
                        '${member.fullName} has been removed from the group',
                      );
                      _loadData();
                    } else {
                      // Show the specific error message from the provider
                      final errorMessage = groupProvider.errorMessage;
                      _showError(
                        errorMessage ??
                            'Failed to remove ${member.fullName} from the group',
                      );
                    }
                  }
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Events'),
            Tab(text: 'Removed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
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
                      'Error loading data',
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
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(),
                  _buildEventsTab(),
                  _buildRemovedMembersTab(),
                ],
              ),
    );
  }

  Widget _buildMembersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withOpacity(
                          0.2,
                        ),
                        child: Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        member.fullName,
                        style: TextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            member.email,
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Member',
                              style: TextStyles.bodyText.copyWith(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing:
                          _canRemoveMember()
                              ? IconButton(
                                icon: const Icon(
                                  Icons.person_remove,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _showRemoveMemberDialog(member),
                                tooltip: 'Remove member',
                              )
                              : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MemberAttendanceScreen(
                                  userId: member.id,
                                  groupId: widget.groupId,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEventsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _events.isEmpty
              ? const Center(child: Text('No upcoming events'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondaryColor,
                        child: const Icon(Icons.event, color: Colors.white),
                      ),
                      title: Text(
                        event.title,
                        style: TextStyles.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            event.description,
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatEventDateTime(event.dateTime),
                                style: TextStyles.bodyText.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              // For leadership events, navigate to read-only event details
                              // For regular events, navigate to overall event details
                              if (event.isLeadershipEvent) {
                                return EventDetailsScreen(
                                  event: event,
                                  groupId: widget.groupId,
                                );
                              } else {
                                return OverallEventDetailsScreen(
                                  eventId: event.id,
                                  eventTitle: event.title,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildRemovedMembersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _removedMembers.isEmpty
              ? const Center(
                child: Text(
                  'No removed members',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _removedMembers.length,
                itemBuilder: (context, index) {
                  final r = _removedMembers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: Text(
                          r.userName.isNotEmpty
                              ? r.userName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      title: Text(
                        r.userName,
                        style: TextStyles.bodyText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            r.userEmail,
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reason for removal',
                                  style: TextStyles.bodyText.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (r.reason?.isEmpty ?? true) ? '—' : r.reason!,
                                  style: TextStyles.bodyText.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onBackground.withOpacity(0.9),
                                  ),
                                ),
                                if (r.removedAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Removed: ${r.removedAt}',
                                    style: TextStyles.bodyText.copyWith(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatEventDateTime(DateTime dateTime) {
    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
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
      'Dec',
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

  void _showCreateEventDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedTag = 'leadership'; // RC can only create leadership events

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    'Create Regional Leadership Meeting',
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
                            labelText: 'Meeting Title',
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
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      selectedDate = date;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
                                  '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This will be a Regional Leadership Meeting for you and your regional administrators',
                                  style: TextStyles.bodyText.copyWith(
                                    color: Colors.amber.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            locationController.text.isEmpty) {
                          _showError('Please fill all fields');
                          return;
                        }

                        final DateTime eventDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        final eventProvider = Provider.of<EventProvider>(
                          context,
                          listen: false,
                        );
                        await eventProvider.createEvent(
                          groupId: widget.groupId,
                          title: titleController.text,
                          description: descriptionController.text,
                          dateTime: eventDateTime,
                          location: locationController.text,
                          tag: selectedTag,
                        );

                        await _loadData();
                        Navigator.pop(context);
                        _showSuccess(
                          'Regional Leadership Meeting created successfully',
                        );

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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
