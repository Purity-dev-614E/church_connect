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

  // Helper method to get both group and region information efficiently
  Future<Map<String, String>> _getEventLocationInfo(
    BuildContext context,
  ) async {
    final Map<String, String> result = {};

    // Fetch group and region info in parallel for better performance
    final futures = <Future<void>>[];

    // Get group name if groupId exists
    if (event.groupId != null && event.groupId!.isNotEmpty) {
      futures.add(_getGroupNameAsync(context, result));
    }

    // Get region name if regionalId exists
    if (event.regionalId != null && event.regionalId!.isNotEmpty) {
      futures.add(_getRegionNameAsync(context, result));
    }

    // Wait for all futures to complete
    await Future.wait(futures);

    return result;
  }

  // Async helper for group name
  Future<void> _getGroupNameAsync(
    BuildContext context,
    Map<String, String> result,
  ) async {
    try {
      // Always get the group name directly from GroupProvider for consistency
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Try to find the group in the cached list first (faster)
      final cachedGroups = groupProvider.groups;
      final cachedGroup = cachedGroups.firstWhere(
        (group) => group.id == event.groupId,
        orElse:
            () => GroupModel(
              id: '',
              name: 'Unknown Group',
              region_id: '',
              group_admin: '',
            ),
      );

      if (cachedGroup.name != 'Unknown Group') {
        result['groupName'] = cachedGroup.name;
        // Also get region info from the group if available
        if (cachedGroup.region_id?.isNotEmpty == true) {
          result['regionName'] = await _getRegionNameById(
            context,
            cachedGroup.region_id!,
          );
        }
        return;
      }

      // If not found in cache, try to fetch it with shorter timeout for better UX
      final group = await groupProvider
          .getGroupById(event.groupId!)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (group != null) {
        result['groupName'] = group.name;
        // Also get region info from the group if available
        if (group.region_id?.isNotEmpty == true) {
          result['regionName'] = await _getRegionNameById(
            context,
            group.region_id!,
          );
        }
      } else {
        result['groupName'] = 'Unknown Group';
      }
    } catch (e) {
      print('Error getting group name for event ${event.id}: $e');
      result['groupName'] = 'Unknown Group';
    }
  }

  // Helper method to get region name by ID
  Future<String> _getRegionNameById(
    BuildContext context,
    String regionId,
  ) async {
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

  // Async helper for region name
  Future<void> _getRegionNameAsync(
    BuildContext context,
    Map<String, String> result,
  ) async {
    try {
      final regionProvider = Provider.of<RegionProvider>(
        context,
        listen: false,
      );
      final regions = regionProvider.regions;
      final region = regions.firstWhere(
        (r) => r.id == event.regionalId,
        orElse:
            () => RegionModel(id: event.regionalId!, name: 'Unknown Region'),
      );
      result['regionName'] = region.name;
    } catch (e) {
      print('Error getting region name: $e');
      result['regionName'] = 'Unknown Region';
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
          child: FutureBuilder<Map<String, String>>(
            future: _getEventLocationInfo(context),
            builder: (context, snapshot) {
              final groupName =
                  snapshot.data?['groupName'] ??
                  (event.groupId?.isNotEmpty == true ? 'Unknown Group' : null);
              final regionName =
                  snapshot.data?['regionName'] ??
                  (event.regionalId?.isNotEmpty == true
                      ? 'Unknown Region'
                      : null);

              return _buildEventCardContent(
                context,
                event,
                formattedDate,
                isUpcoming,
                isPast,
                groupName,
                regionName,
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to format location info as "group A, region A"
  String _formatLocationInfo(String? groupName, String? regionName) {
    final parts = <String>[];

    if (groupName != null && groupName.isNotEmpty) {
      parts.add(groupName);
    }

    if (regionName != null && regionName.isNotEmpty) {
      parts.add(regionName);
    }

    return parts.join(', ');
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
        // Display combined location info (group and region) in single line
        if (groupName != null || regionName != null) ...[
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
                  _formatLocationInfo(groupName, regionName),
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
      ],
    );
  }
}
