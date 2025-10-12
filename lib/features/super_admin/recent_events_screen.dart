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

class RecentEventsScreen extends StatefulWidget {
  final List<dynamic> recentEvents;

  const RecentEventsScreen({
    super.key,
    required this.recentEvents,
  });

  @override
  State<RecentEventsScreen> createState() => _RecentEventsScreenState();
}

class _RecentEventsScreenState extends State<RecentEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RegionModel> _regions = [];
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
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
      setState(() {
        _regions = regionProvider.regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
      print('Error loading regions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert recent events to EventModel objects
    final List<EventModel> events = widget.recentEvents
        .map((event) => EventModel.fromJson(event as Map<String, dynamic>))
        .toList();

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    final filteredEvents = searchQuery.isEmpty
        ? events
        : events.where((event) {
            return event.title.toLowerCase().contains(searchQuery) ||
                   event.description.toLowerCase().contains(searchQuery) ||
                   event.location.toLowerCase().contains(searchQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Events'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return EventCard(
                  event: event,
                  onTap: () => _navigateToEventDetails(event),
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
          hintText: 'Search recent events...',
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
            'No recent events found',
            style: TextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
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

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);
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
          child: FutureBuilder(
            future: Future.wait([
              groupProvider.getGroupById(event.groupId),
              regionProvider.getRegionById(event.regionId),
            ]).timeout(
              const Duration(seconds: 10),
              onTimeout: () => [null, null],
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
                print('Error loading group/region data: ${snapshot.error}');
                return _buildEventCardContent(
                  context,
                  event,
                  formattedDate,
                  isUpcoming,
                  isPast,
                  null, // group
                  null, // region
                );
              }

              final group = snapshot.data?[0] as GroupModel?;
              final region = snapshot.data?[1] as RegionModel?;

              return _buildEventCardContent(
                context,
                event,
                formattedDate,
                isUpcoming,
                isPast,
                group,
                region,
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
    RegionModel? region,
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
              child: _buildInfoRow(
                Icons.location_on,
                'Region',
                region?.name ?? 'Unknown Region',
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
