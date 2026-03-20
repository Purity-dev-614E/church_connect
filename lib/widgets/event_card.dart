// lib/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../data/models/event_model.dart';
import 'package:provider/provider.dart';
import '../data/providers/group_provider.dart';
import '../data/providers/region_provider.dart';
import '../data/models/group_model.dart';
import '../data/models/region_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final Future<String> Function(String groupId)? getRegionNameFromGroup;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.getRegionNameFromGroup,
  });

  // Helper method for leadership events to get region name
  Future<String> _getRegionNameForLeadershipEvent(
    BuildContext context,
    String? regionId,
  ) async {
    if (regionId == null || regionId.isEmpty) {
      return 'All Regions';
    }

    try {
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );
      final regions = regionProvider.regions;
      final region = regions.firstWhere(
        (r) => r.id == regionId,
        orElse: () => RegionModel(id: regionId, name: 'Unknown Region'),
      );
      return region.name;
    } catch (e) {
      print('Error getting region name: $e');
      return 'Unknown Region';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEE, MMM d • h:mm a',
    ).format(event.dateTime);
    final isUpcoming = event.dateTime.isAfter(DateTime.now());
    final isPast = event.dateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              event.isLeadershipEvent
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      color: event.isLeadershipEvent ? Colors.amber.withOpacity(0.05) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              event.isLeadershipEvent
                  ? FutureBuilder<String>(
                    future: _getRegionNameForLeadershipEvent(
                      context,
                      event.regionalId,
                    ),
                    builder: (context, snapshot) {
                      return _buildEventCardContent(
                        context,
                        event,
                        formattedDate,
                        isUpcoming,
                        isPast,
                        null, // Leadership events don't have groups
                        snapshot.data ?? 'All Regions',
                      );
                    },
                  )
                  : FutureBuilder<GroupModel?>(
                    future:
                        getRegionNameFromGroup != null
                            ? null // Use getRegionNameFromGroup if provided
                            : Provider.of<GroupProvider>(context, listen: false)
                                .getGroupById(event.groupId!)
                                .timeout(
                                  const Duration(seconds: 10),
                                  onTimeout: () => null,
                                ),
                    builder: (context, snapshot) {
                      final groupName = snapshot.data?.name ?? 'Unknown Group';
                      return _buildEventCardContent(
                        context,
                        event,
                        formattedDate,
                        isUpcoming,
                        isPast,
                        groupName,
                        null, // Regular events don't have region info
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
    String? groupName,
    String? regionName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    event.isLeadershipEvent
                        ? Colors.amber.withOpacity(0.2)
                        : AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                event.isLeadershipEvent ? Icons.push_pin : Icons.event,
                color:
                    event.isLeadershipEvent
                        ? Colors.amber.shade700
                        : AppColors.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyles.heading2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.isLeadershipEvent) ...[
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Leadership Meeting',
                          style: TextStyles.bodyText.copyWith(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onBackground,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            const SizedBox(width: 6.0),
            Text(
              formattedDate,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                event.location,
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
        if (groupName != null) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  groupName,
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (regionName != null) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(Icons.public, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  regionName!,
                  style: TextStyles.bodyText.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
