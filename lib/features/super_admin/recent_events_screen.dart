import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../data/models/event_model.dart';
import '../../data/models/region_model.dart';
import '../../data/providers/region_provider.dart';
import '../events/overall_event_details.dart';
import '../../widgets/event_card.dart';

class RecentEventsScreen extends StatefulWidget {
  final List<dynamic> recentEvents;

  const RecentEventsScreen({super.key, required this.recentEvents});

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
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );
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
    final List<EventModel> events =
        widget.recentEvents.map((eventData) {
          // Check if this is a RecentAttendance object or already an EventModel
          if (eventData is Map<String, dynamic>) {
            // If it's already in EventModel format, convert directly
            if (eventData.containsKey('id') && eventData.containsKey('title')) {
              return EventModel.fromJson(eventData);
            }
            // Otherwise, assume it's RecentAttendance data and convert properly
            return EventModel(
              id: eventData['eventId'] ?? '',
              title: eventData['eventTitle'] ?? '',
              description: '', // Not available in recent attendance
              dateTime:
                  eventData['eventDate'] != null
                      ? DateTime.parse(eventData['eventDate'])
                      : DateTime.now(),
              location: '', // Not available in recent attendance
              groupId: eventData['groupId'],
              tag: eventData['tag'] ?? 'org', // Preserve tag if available
            );
          }
          // Fallback
          return EventModel.fromJson(eventData as Map<String, dynamic>);
        }).toList();

    // Remove duplicate events based on ID
    final Set<String> seenEventIds = {};
    final uniqueEvents =
        events.where((event) {
          if (seenEventIds.contains(event.id)) {
            return false; // Skip duplicate
          }
          seenEventIds.add(event.id);
          return true;
        }).toList();

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    final filteredEvents =
        searchQuery.isEmpty
            ? uniqueEvents
            : uniqueEvents.where((event) {
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
            child:
                filteredEvents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search recent events...',
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
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
