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

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  String selectedRegion = 'All';
  String selectedFilter = 'All'; // could be All / Upcoming / Past / Ongoing

  @override
  void initState() {
    super.initState();

    // Safe: Schedule provider fetch after the first frame
    Future.microtask(() {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.fetchOverallEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    final allEvents = eventProvider.events;

    // 🔹 Apply region filter
    final filteredByRegion = selectedRegion == 'All'
        ? allEvents
        : allEvents.where((e) => e.regionId == selectedRegion).toList();

    // 🔹 Apply time filter
    final now = DateTime.now();
    final filteredEvents = filteredByRegion.where((event) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Event Management')),
      body: eventProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          _buildFilters(eventProvider),
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(child: Text('No events found'))
                : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.dateTime} • ${event.regionId}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Region + Filter Dropdowns
  Widget _buildFilters(EventProvider eventProvider) {
    final regions = {'All', ...eventProvider.events.map((e) => e.regionId)};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: selectedRegion,
              isExpanded: true,
              items: regions.map((r) {
                return DropdownMenuItem(value: r, child: Text(r));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedRegion = value!);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                DropdownMenuItem(value: 'Past', child: Text('Past')),
              ],
              onChanged: (value) {
                setState(() => selectedFilter = value!);
              },
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
    final formattedDate =
    DateFormat('EEE, MMM d • h:mm a').format(event.dateTime);

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final regionProvider = Provider.of<RegionProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder(
            future: Future.wait([
              groupProvider.getGroupById(event.groupId),
              regionProvider.getRegionById(event.regionId),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              final group = snapshot.data?[0] as GroupModel?;
              final region = snapshot.data?[1] as RegionModel?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    event.title,
                    style: TextStyles.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Group name
                  Row(
                    children: [
                      const Icon(Icons.group,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        group?.name ?? 'Loading group...',
                        style: TextStyles.heading2.copyWith(
                          color:
                          Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Region name
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        region?.name ?? 'Loading region...',
                        style: TextStyles.bodyText?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyles.bodyText?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
