import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../data/models/event_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/region_model.dart';
import '../../data/providers/event_provider.dart';
import '../../data/providers/group_provider.dart';
import '../../data/providers/region_provider.dart';
import '../events/overall_event_details.dart';

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

  @override
  void initState() {
    super.initState();

    // Safe: Schedule provider fetch after the first frame
    Future.microtask(() {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.fetchOverallEvents();
      _loadRegions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      await regionProvider.loadRegions();
      
      if (mounted) {
        setState(() {
          _regions = regionProvider.regions;
          _isLoadingRegions = false;
        });
        print('Loaded ${_regions.length} regions: ${_regions.map((r) => r.name).toList()}');
        
        // If no regions loaded, try again after a short delay
        if (_regions.isEmpty) {
          print('No regions loaded, retrying...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _loadRegions();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
        print('Error loading regions: $e');
        
        // Retry once after error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            print('Retrying region load after error...');
            _loadRegions();
          }
        });
      }
    }
  }

  // Helper function to get region name from group
  Future<String> _getRegionNameFromGroup(String groupId) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      
      // Get the group first
      final group = await groupProvider.getGroupById(groupId);
      if (group == null || group.region_id == null || group.region_id!.isEmpty) {
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
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final group = await groupProvider.getGroupById(event.groupId);
      return group?.region_id == regionId;
    } catch (e) {
      print('Error checking event region: $e');
      return false;
    }
  }

  // Filter events by region
  Future<List<EventModel>> _filterEventsByRegion(List<EventModel> events) async {
    if (selectedRegion == 'All') {
      return events;
    }

    final filteredEvents = <EventModel>[];
    
    for (final event in events) {
      try {
        final belongsToRegion = await _eventBelongsToRegion(event, selectedRegion);
        if (belongsToRegion) {
          filteredEvents.add(event);
        }
      } catch (e) {
        print('Error filtering event ${event.id} by region: $e');
        // Include the event if we can't determine its region
        filteredEvents.add(event);
      }
    }
    
    return filteredEvents;
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    final allEvents = eventProvider.events;

    // 🔹 Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    final filteredBySearch = searchQuery.isEmpty
        ? allEvents
        : allEvents.where((event) {
            return event.title.toLowerCase().contains(searchQuery) ||
                   event.description.toLowerCase().contains(searchQuery) ||
                   event.location.toLowerCase().contains(searchQuery);
          }).toList();

    // 🔹 Apply time filter
    final now = DateTime.now();
    final filteredByTime = filteredBySearch.where((event) {
      switch (selectedFilter) {
        case 'Upcoming':
          return event.dateTime.isAfter(now);
        case 'Past':
          return event.dateTime.isBefore(now);
        case 'Ongoing':
          final start = event.dateTime;
          final end = start.add(const Duration(hours: 2)); // assume 2h duration
          return now.isAfter(start) && now.isBefore(end);
        default:
          return true;
      }
    }).toList();

    // Note: Region filtering will be handled in the UI with FutureBuilder
    final filteredEvents = filteredByTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: eventProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          _buildFilters(eventProvider),
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : FutureBuilder<List<EventModel>>(
                    future: _filterEventsByRegion(filteredEvents),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final events = snapshot.data ?? [];
                      
                      if (events.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventCard(
                            event: event,
                            onTap: () => _navigateToEventDetails(event),
                            getRegionNameFromGroup: _getRegionNameFromGroup,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OverallEventDetailsScreen(
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
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search events...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
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
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Region + Filter Dropdowns
  Widget _buildFilters(EventProvider eventProvider) {
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
                          const DropdownMenuItem(value: 'All', child: Text('All Regions')),
                          if (_isLoadingRegions)
                            const DropdownMenuItem(
                              value: 'loading',
                              child: Text('Loading regions...'),
                            )
                          else
                            ..._regions.map((region) {
                              print('Adding region to dropdown: ${region.name} (${region.id})');
                              return DropdownMenuItem(
                                value: region.id,
                                child: Text(region.name),
                              );
                            }),
                        ],
                        onChanged: _isLoadingRegions ? null : (value) {
                          print('Region selected: $value');
                          setState(() => selectedRegion = value!);
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
                DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                DropdownMenuItem(value: 'Past', child: Text('Past')),
              ],
              onChanged: (value) {
                setState(() => selectedFilter = value!);
              },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final Future<String> Function(String groupId)? getRegionNameFromGroup;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.getRegionNameFromGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
    final formattedTime = DateFormat('h:mm a').format(event.dateTime);
    final isUpcoming = event.dateTime.isAfter(DateTime.now());
    final isPast = event.dateTime.isBefore(DateTime.now());

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final regionProvider = Provider.of<RegionProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<GroupModel?>(
            future: groupProvider.getGroupById(event.groupId).timeout(
              const Duration(seconds: 10),
              onTimeout: () => null,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                print('Error loading group data: ${snapshot.error}');
                return _buildEventCardContent(
                  context,
                  event,
                  formattedDate,
                  isUpcoming,
                  isPast,
                  null, // group
                  'Unknown Region', // region name
                );
              }

              final group = snapshot.data;
              return _buildEventCardContent(
                context,
                event,
                formattedDate,
                isUpcoming,
                isPast,
                group,
                'Loading Region...', // Will be updated with actual region name
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventCardContent(
    BuildContext context,
    EventModel event,
    String formattedDate,
    bool isUpcoming,
    bool isPast,
    GroupModel? group,
    String regionName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event title and status
        Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: TextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUpcoming 
                    ? Colors.green.withOpacity(0.1)
                    : isPast 
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUpcoming 
                      ? Colors.green
                      : isPast 
                          ? Colors.grey
                          : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                isUpcoming ? 'Upcoming' : isPast ? 'Past' : 'Ongoing',
                style: TextStyles.bodyText.copyWith(
                  color: isUpcoming 
                      ? Colors.green
                      : isPast 
                          ? Colors.grey
                          : Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Event description
        if (event.description.isNotEmpty) ...[
          Text(
            event.description,
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],

        // Group and Region info
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                Icons.group,
                'Group',
                group?.name ?? 'Unknown Group',
                context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: group != null && group.region_id != null && group.region_id!.isNotEmpty && getRegionNameFromGroup != null
                  ? FutureBuilder<String>(
                      future: getRegionNameFromGroup!(group.id),
                      builder: (context, snapshot) {
                        return _buildInfoRow(
                          Icons.location_on,
                          'Region',
                          snapshot.data ?? 'Loading...',
                          context,
                        );
                      },
                    )
                  : _buildInfoRow(
                      Icons.location_on,
                      'Region',
                      'Unknown Region',
                      context,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date and Location
        Row(
          children: [
            Expanded(
              child: _buildInfoRow(
                Icons.calendar_today,
                'Date',
                formattedDate,
                context,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow(
                Icons.place,
                'Location',
                event.location,
                context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
