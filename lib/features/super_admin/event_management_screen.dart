import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../data/models/event_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/region_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/region_provider.dart';
import '../../data/services/user_services.dart';
import '../events/overall_event_details.dart';
import '../../widgets/event_card.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  String selectedRegion = 'All';
  String selectedFilter = 'All'; // could be All / Upcoming / Past / Ongoing
  final TextEditingController _searchController = TextEditingController();
  List<RegionModel> _regions = [];
  bool _isLoadingRegions = false;
  final UserServices _userServices = UserServices();
  String? _userRole;
  bool _initialized = false; // Flag to prevent multiple initializations

  // Local state for events (like region manager)
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_initialized) return;
    _initialized = true;

    _loadUserRole();

    // Add listener to search controller
    _searchController.addListener(() {
      if (mounted) {
        _filterEvents();
      }
    });

    // Load data
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load regions first, then events
      await _loadRegions();
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
    print('=== _loadEvents called for super admin ===');
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      print('Calling fetchAllEvents...');
      await eventProvider.fetchAllEvents();

      final allEvents = eventProvider.events;
      print('📊 Total events fetched: ${allEvents.length}');

      // Debug: Print event details
      for (int i = 0; i < allEvents.length; i++) {
        final event = allEvents[i];
        print(
          'Event $i: ${event.title} | Leadership: ${event.isLeadershipEvent} | Group: ${event.groupId} | Region: ${event.regionalId}',
        );
      }

      // Store in local state (like region manager)
      if (mounted) {
        setState(() {
          _events = allEvents;
          _errorMessage = null; // Clear any previous errors
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load events: ${e.toString()}';
          _events = []; // Ensure empty list on error
        });
      }
      // Don't re-throw the error to prevent white screen
    }
  }

  void _filterEvents() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();

    print('🔍 Filtering ${_events.length} events...');
    print('📝 Search query: "$query"');
    print('⏰ Time filter: "$selectedFilter"');
    print('🌍 Region filter: "$selectedRegion"');

    int filteredCount = 0;
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
          switch (selectedFilter) {
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

          // Region filter (simplified for now)
          bool matchesRegionFilter = true;
          if (selectedRegion != 'All' && _regions.isNotEmpty) {
            if (event.isLeadershipEvent) {
              matchesRegionFilter = event.regionalId == selectedRegion;
            } else {
              // For regular events, include all for now (can be enhanced later)
              matchesRegionFilter = true;
            }
          }

          final passesAllFilters =
              matchesQuery && matchesTimeFilter && matchesRegionFilter;

          if (!passesAllFilters) {
            print(
              '❌ Filtered out: ${event.title} | Search: $matchesQuery | Time: $matchesTimeFilter | Region: $matchesRegionFilter',
            );
          } else {
            filteredCount++;
          }

          return passesAllFilters;
        }).toList();

    print('✅ Passed all filters: $filteredCount events');

    if (mounted) {
      setState(() {
        _filteredEvents = filteredEvents;
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await _userServices.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  bool get _canCreateLeadershipEvents {
    return RoleUtils.canCreateLeadershipEvents(_userRole);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    if (_isLoadingRegions) return; // Prevent multiple simultaneous loads

    setState(() => _isLoadingRegions = true);
    try {
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );
      await regionProvider.loadRegions();

      if (mounted) {
        setState(() {
          _regions = regionProvider.regions;
          _isLoadingRegions = false;
        });
        print(
          'Loaded ${_regions.length} regions: ${_regions.map((r) => r.name).toList()}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
        print('Error loading regions: $e');
      }
    }
  }

  // Helper function to get region name from group
  Future<String> _getRegionNameFromGroup(String groupId) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );

      // Get the group first
      final group = await groupProvider.getGroupById(groupId);
      if (group == null ||
          group.region_id == null ||
          group.region_id!.isEmpty) {
        return 'Unknown Region';
      }

      // Get the region name
      final region = await regionProvider.getRegionById(group.region_id!);
      return region?.name ?? 'Unknown Region';
    } catch (e) {
      print('Error getting region name for group $groupId: $e');
      return 'Unknown Region';
    }
  }

  // Helper function to check if an event belongs to a specific region
  Future<bool> _eventBelongsToRegion(EventModel event, String regionId) async {
    try {
      // Leadership events don't belong to groups, handle them separately
      if (event.isLeadershipEvent) {
        // For leadership events, check if they have a regionId that matches
        return event.regionalId == regionId;
      }

      // For regular events, check the group's region
      if (event.groupId == null) {
        return false; // Regular event without groupId shouldn't happen, but handle gracefully
      }

      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final group = await groupProvider.getGroupById(event.groupId!);
      return group?.region_id == regionId;
    } catch (e) {
      print('Error checking event region: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🚀 NEW EventManagementScreen build() called ===');
    print('Local events count: ${_events.length}');
    print('Local filtered events count: ${_filteredEvents.length}');
    print('Is loading: $_isLoading');
    print('Error message: $_errorMessage');

    // Show loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      return _buildErrorState(_errorMessage!);
    }

    // Ensure we have valid data
    final events = _filteredEvents;
    print('Rendering ${events.length} events');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child:
                events.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(
                          event: event,
                          onTap: () => _navigateToEventDetails(event),
                          getRegionNameFromGroup: _getRegionNameFromGroup,
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OverallEventDetailsScreen(
              eventId: event.id,
              eventTitle: event.title,
            ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          // Don't call setState here - let the build method use the controller value directly
        },
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      // Don't call setState here - the text field will update automatically
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Events',
            style: TextStyles.heading2.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final eventProvider = Provider.of<EventProvider>(
                context,
                listen: false,
              );
              eventProvider.fetchAllEvents();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No events found',
            style: TextStyles.heading2.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              print('Retry button pressed - loading all events');
              _loadData();
            },
            child: const Text('Refresh Events'),
          ),
        ],
      ),
    );
  }

  // 🔸 Region + Filter Dropdowns
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryColor),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRegion,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Regions'),
                          ),
                          if (_isLoadingRegions)
                            const DropdownMenuItem(
                              value: 'loading',
                              child: Text('Loading regions...'),
                            )
                          else
                            ..._regions.map((region) {
                              print(
                                'Adding region to dropdown: ${region.name} (${region.id})',
                              );
                              return DropdownMenuItem(
                                value: region.id,
                                child: Text(region.name),
                              );
                            }),
                        ],
                        onChanged:
                            _isLoadingRegions
                                ? null
                                : (value) {
                                  print('Region selected: $value');
                                  setState(() {
                                    selectedRegion = value!;
                                  });
                                  _filterEvents();
                                },
                      ),
                    ),
                  ),
                  if (!_isLoadingRegions && _regions.isEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        print('Manually refreshing regions...');
                        _loadRegions();
                      },
                      tooltip: 'Refresh regions',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryColor),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Events')),
                    DropdownMenuItem(
                      value: 'Upcoming',
                      child: Text('Upcoming'),
                    ),
                    DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(value: 'Past', child: Text('Past')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                    _filterEvents();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedTag = 'org';
    String selectedTarget = 'all'; // 'all', 'regional', or 'rc_only'
    String? selectedRegionId;
    String? selectedGroupId; // For regular events

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
                                title: Text('Org Event'),
                                value: 'org',
                                groupValue: selectedTag,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedTag = value;
                                      selectedTarget = 'all';
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (_canCreateLeadershipEvents)
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('Leadership Meeting'),
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
                          FutureBuilder<List<GroupModel>>(
                            future: Provider.of<GroupProvider>(
                              context,
                              listen: false,
                            ).fetchGroups().then((_) {
                              return Provider.of<GroupProvider>(
                                context,
                                listen: false,
                              ).groups;
                            }),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.secondaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final groups = snapshot.data ?? [];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
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
                                        groups.map((group) {
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
                              );
                            },
                          ),
                        ],
                        if (selectedTag == 'leadership') ...[
                          const SizedBox(height: 16),
                          Text(
                            'Target Audience',
                            style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Root/SuperAdmin: see all options
                          if (RoleUtils.isRoot(_userRole) ||
                              RoleUtils.isSuperAdmin(_userRole)) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text('All RCs + Admins'),
                                    value: 'all',
                                    groupValue: selectedTarget,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setDialogState(() {
                                          selectedTarget = value;
                                          selectedRegionId = null;
                                        });
                                      }
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text('Super Admin + RCs'),
                                    value: 'rc_only',
                                    groupValue: selectedTarget,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setDialogState(() {
                                          selectedTarget = value;
                                          selectedRegionId = null;
                                        });
                                      }
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const Expanded(
                                  child: SizedBox(),
                                ), // Empty space for alignment
                              ],
                            ),
                            // Regional managers: simplified options
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Leadership events will be sent to all regional coordinators',
                                    style: TextStyles.bodyText.copyWith(
                                      color: AppColors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                        if (selectedTag == 'leadership') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  selectedTarget == 'all'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    selectedTarget == 'all'
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.purple.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedTarget == 'all'
                                      ? Icons.people
                                      : Icons.admin_panel_settings,
                                  color:
                                      selectedTarget == 'all'
                                          ? Colors.blue.shade700
                                          : Colors.purple.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedTarget == 'all'
                                        ? 'This will be visible to all Regional Coordinators and their administrators'
                                        : 'This will be visible only to Super Admins and Regional Coordinators',
                                    style: TextStyles.bodyText.copyWith(
                                      color:
                                          selectedTarget == 'all'
                                              ? Colors.blue.shade700
                                              : Colors.purple.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        if (selectedTag == 'org' &&
                            (selectedGroupId == null ||
                                selectedGroupId!.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select a group for regular events',
                              ),
                            ),
                          );
                          return;
                        }

                        final DateTime eventDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // For now, we'll create the event. The backend will handle the targeting logic
                        final eventProvider = Provider.of<EventProvider>(
                          context,
                          listen: false,
                        );

                        try {
                          EventModel? createdEvent;

                          if (selectedTag == 'leadership') {
                            // Create leadership event using the new endpoint
                            // Include regionId for regional managers targeting specific regions
                            createdEvent = await eventProvider
                                .createLeadershipEvent(
                                  title: titleController.text,
                                  description: descriptionController.text,
                                  dateTime: eventDateTime,
                                  location: locationController.text,
                                  regionId:
                                      selectedTarget == 'regional'
                                          ? selectedRegionId
                                          : null,
                                  targetAudience: selectedTarget,
                                );
                          } else {
                            // Create regular group event - require group selection
                            if (selectedGroupId == null ||
                                selectedGroupId!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select a group to create a regular event',
                                  ),
                                ),
                              );
                              return;
                            }

                            createdEvent = await eventProvider.createEvent(
                              groupId: selectedGroupId!,
                              title: titleController.text,
                              description: descriptionController.text,
                              dateTime: eventDateTime,
                              location: locationController.text,
                              tag: selectedTag,
                            );
                          }

                          if (createdEvent != null) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedTag == 'leadership'
                                      ? 'Leadership event created successfully'
                                      : 'Event created successfully',
                                ),
                              ),
                            );
                            // Refresh the events list to show the newly created event
                            await _loadEvents();
                            _filterEvents();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedTag == 'leadership'
                                      ? 'Failed to create leadership event'
                                      : 'Failed to create event',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }

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
