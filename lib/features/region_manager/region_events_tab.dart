import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RegionEventsTab extends StatefulWidget {
  final String regionId;

  const RegionEventsTab({super.key, required this.regionId});

  @override
  State<RegionEventsTab> createState() => _RegionEventsTabState();
}

class _RegionEventsTabState extends State<RegionEventsTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  List<GroupModel> _regionGroups = [];

  // State for search and filtering
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Upcoming, Past, Ongoing
  String _selectedTypeFilter = 'All'; // All, Regular, Leadership

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load groups first, then events (events depend on groups for filtering)
      await _loadGroups();
      await _loadEvents();

      if (mounted) {
        _filterEvents();
        setState(() {
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

  Future<void> _loadEvents() async {
    print('=== _loadEvents called for region ${widget.regionId} ===');
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      print('Calling fetchAllEvents...');
      await eventProvider.fetchAllEvents();

      final allEvents = eventProvider.events;
      print('Total events fetched: ${allEvents.length}');

      // Debug: Check leadership events specifically
      final leadershipEvents =
          allEvents.where((e) => e.isLeadershipEvent).toList();
      print('Leadership events found: ${leadershipEvents.length}');
      for (var event in leadershipEvents) {
        print(
          'Leadership event: ${event.title}, regionId: ${event.regionId}, target region: ${widget.regionId}',
        );
      }

      print('Region groups available: ${_regionGroups.length}');

      // Filter events for this region
      final regionEvents =
          allEvents.where((event) {
            // Include regular events from groups in this region
            if (event.groupId != null && event.groupId!.isNotEmpty) {
              final matchesGroup = _regionGroups.any(
                (group) => group.id == event.groupId,
              );
              if (matchesGroup) {
                print('Event ${event.title} matches group ${event.groupId}');
              }
              return matchesGroup;
            }
            // Include leadership events targeting this region OR all leadership events if regionId is null/empty
            if (event.isLeadershipEvent) {
              final matchesRegion = event.regionId == widget.regionId;
              final hasNoRegionId =
                  event.regionId == null || event.regionId!.isEmpty;

              if (matchesRegion) {
                print(
                  'Leadership event ${event.title} matches region ${widget.regionId}',
                );
                return true;
              } else if (hasNoRegionId) {
                print(
                  'Leadership event ${event.title} has no regionId, including by default',
                );
                return true; // Include leadership events without regionId as fallback
              } else {
                print(
                  'Leadership event ${event.title} region ${event.regionId} does not match target ${widget.regionId}',
                );
              }
            }
            return false;
          }).toList();

      print('Filtered region events: ${regionEvents.length}');

      if (mounted) {
        setState(() {
          _events = regionEvents;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      throw e;
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groups = await groupProvider.getGroupsByRegion(widget.regionId);

      if (mounted) {
        setState(() {
          _regionGroups = groups;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
      throw e;
    }
  }

  void _filterEvents() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();

    final filteredEvents =
        _events.where((event) {
          // Search filter
          final matchesQuery =
              query.isEmpty ||
              event.title.toLowerCase().contains(query) ||
              event.description.toLowerCase().contains(query) ||
              event.location.toLowerCase().contains(query);

          // Time filter
          bool matchesTimeFilter;
          switch (_selectedFilter) {
            case 'Upcoming':
              matchesTimeFilter = event.dateTime.isAfter(now);
              break;
            case 'Past':
              matchesTimeFilter = event.dateTime.isBefore(now);
              break;
            case 'Ongoing':
              final start = event.dateTime;
              final end = start.add(const Duration(hours: 2));
              matchesTimeFilter = now.isAfter(start) && now.isBefore(end);
              break;
            default:
              matchesTimeFilter = true;
          }

          // Type filter
          bool matchesTypeFilter;
          switch (_selectedTypeFilter) {
            case 'Regular':
              matchesTypeFilter = !event.isLeadershipEvent;
              break;
            case 'Leadership':
              matchesTypeFilter = event.isLeadershipEvent;
              break;
            default:
              matchesTypeFilter = true;
          }

          return matchesQuery && matchesTimeFilter && matchesTypeFilter;
        }).toList();

    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _filteredEvents = filteredEvents;
        });
      }
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

  String _formatEventDate(DateTime dateTime) {
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

  Color _getEventTypeColor(EventModel event) {
    if (event.isLeadershipEvent) {
      return AppColors.primaryColor;
    }
    return AppColors.secondaryColor;
  }

  String _getEventTypeName(EventModel event) {
    if (event.isLeadershipEvent) {
      return 'Leadership Event';
    }
    return 'Regular Event';
  }

  String _getGroupName(String? groupId) {
    if (groupId == null || groupId.isEmpty) return 'N/A';
    final group = _regionGroups.firstWhere(
      (g) => g.id == groupId,
      orElse:
          () => GroupModel(
            id: '',
            name: 'Unknown Group',
            region_id: '',
            group_admin: '',
          ),
    );
    return group.name;
  }

  @override
  Widget build(BuildContext context) {
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
              'Error loading events',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
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
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Create Event',
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _filterEvents();
                  },
                ),
                const SizedBox(height: 12),

                // Filter dropdowns
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Time Filter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Events'),
                          ),
                          DropdownMenuItem(
                            value: 'Upcoming',
                            child: Text('Upcoming'),
                          ),
                          DropdownMenuItem(value: 'Past', child: Text('Past')),
                          DropdownMenuItem(
                            value: 'Ongoing',
                            child: Text('Ongoing'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _selectedFilter = value;
                            _filterEvents();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTypeFilter,
                        decoration: InputDecoration(
                          labelText: 'Event Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Types'),
                          ),
                          DropdownMenuItem(
                            value: 'Regular',
                            child: Text('Regular'),
                          ),
                          DropdownMenuItem(
                            value: 'Leadership',
                            child: Text('Leadership'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _selectedTypeFilter = value;
                            _filterEvents();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child:
                _filteredEvents.isEmpty
                    ? const Center(
                      child: Text('No events found matching the criteria'),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final now = DateTime.now();
    final isPast = event.dateTime.isBefore(now);
    final isOngoing =
        now.isAfter(event.dateTime) &&
        now.isBefore(event.dateTime.add(const Duration(hours: 2)));

    Color statusColor;
    String statusText;
    if (isOngoing) {
      statusColor = Colors.green;
      statusText = 'Ongoing';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusText = 'Past';
    } else {
      statusColor = AppColors.accentColor;
      statusText = 'Upcoming';
    }

    // Leadership events get special styling
    final isLeadership = event.isLeadershipEvent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isLeadership ? 8 : 4, // Higher elevation for leadership events
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isLeadership
                ? BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 2,
                )
                : BorderSide.none, // Border for leadership events
      ),
      child: InkWell(
        onTap: () {
          // Navigate to event details
          _navigateToEventDetails(event);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Gradient background for leadership events
          decoration:
              isLeadership
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.05),
                        AppColors.primaryColor.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  )
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title, leadership badge, and status
                Row(
                  children: [
                    // Leadership badge
                    if (isLeadership) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LEADERSHIP',
                              style: TextStyles.bodyText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyles.heading2.copyWith(
                          fontWeight:
                              isLeadership ? FontWeight.bold : FontWeight.w600,
                          color: isLeadership ? AppColors.primaryColor : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyles.bodyText.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Event type and group
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getEventTypeColor(event).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getEventTypeColor(event).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getEventTypeName(event),
                        style: TextStyles.bodyText.copyWith(
                          color: _getEventTypeColor(event),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!event.isLeadershipEvent) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Group: ${_getGroupName(event.groupId)}',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.public,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Region-wide Event',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Date and time
                Row(
                  children: [
                    Icon(
                      isLeadership ? Icons.event : Icons.calendar_today,
                      size: 16,
                      color:
                          isLeadership ? AppColors.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatEventDate(event.dateTime),
                        style: TextStyles.bodyText.copyWith(
                          color:
                              isLeadership
                                  ? AppColors.primaryColor
                                  : Colors.grey[700],
                          fontWeight: isLeadership ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(
                      isLeadership
                          ? Icons.location_on
                          : Icons.location_on_outlined,
                      size: 16,
                      color:
                          isLeadership ? AppColors.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyles.bodyText.copyWith(
                          color:
                              isLeadership
                                  ? AppColors.primaryColor
                                  : Colors.grey[700],
                          fontWeight: isLeadership ? FontWeight.w500 : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description (truncated)
                if (event.description.isNotEmpty) ...[
                  Text(
                    event.description.length > 100
                        ? '${event.description.substring(0, 100)}...'
                        : event.description,
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Participant count if available
                if (event.participantCount != null) ...[
                  Row(
                    children: [
                      Icon(
                        isLeadership ? Icons.groups : Icons.people,
                        size: 16,
                        color:
                            isLeadership ? AppColors.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantCount} participants',
                        style: TextStyles.bodyText.copyWith(
                          color:
                              isLeadership
                                  ? AppColors.primaryColor
                                  : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: isLeadership ? FontWeight.w500 : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEventDetails(EventModel event) {
    // For now, show a simple dialog with event details
    // In the future, this could navigate to a detailed event screen
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${_getEventTypeName(event)}'),
                  const SizedBox(height: 8),
                  Text('Date: ${_formatEventDate(event.dateTime)}'),
                  const SizedBox(height: 8),
                  Text('Location: ${event.location}'),
                  if (!event.isLeadershipEvent) ...[
                    const SizedBox(height: 8),
                    Text('Group: ${_getGroupName(event.groupId)}'),
                  ],
                  const SizedBox(height: 8),
                  const Text('Description:'),
                  const SizedBox(height: 4),
                  Text(event.description),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showCreateEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedTag = 'org'; // 'org' or 'leadership'
    String? selectedGroupId;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Create Event', style: TextStyles.heading2),
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
                          'Event Type',
                          style: TextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Regular Event'),
                                value: 'org',
                                groupValue: selectedTag,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedTag = value;
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Leadership Event'),
                                value: 'leadership',
                                groupValue: selectedTag,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedTag = value;
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        // Group selection for regular events
                        if (selectedTag == 'org') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Select Group',
                            style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.secondaryColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedGroupId,
                                isExpanded: true,
                                hint: const Text('Select a group'),
                                items:
                                    _regionGroups.map((group) {
                                      return DropdownMenuItem(
                                        value: group.id,
                                        child: Text(group.name),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedGroupId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
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
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(selectedDate),
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
                                label: Text(selectedTime.format(context)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Validate form
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty ||
                            locationController.text.trim().isEmpty) {
                          _showError('Please fill in all required fields');
                          return;
                        }

                        if (selectedTag == 'org' && selectedGroupId == null) {
                          _showError(
                            'Please select a group for regular events',
                          );
                          return;
                        }

                        // Create event
                        try {
                          final eventProvider = Provider.of<EventProvider>(
                            context,
                            listen: false,
                          );

                          // Combine date and time
                          final eventDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final createdEvent = await eventProvider.createEvent(
                            groupId:
                                selectedTag == 'org'
                                    ? (selectedGroupId ?? '')
                                    : null, // Don't send groupId for leadership events
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            dateTime: eventDateTime,
                            location: locationController.text.trim(),
                            tag: selectedTag,
                          );

                          if (createdEvent != null) {
                            _showSuccess('Event created successfully');
                            Navigator.pop(context);
                            _loadData(); // Refresh the events list
                          } else {
                            _showError('Failed to create event');
                          }
                        } catch (e) {
                          _showError('Error creating event: ${e.toString()}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      child: const Text('Create Event'),
                    ),
                  ],
                ),
          ),
    );
  }
}
