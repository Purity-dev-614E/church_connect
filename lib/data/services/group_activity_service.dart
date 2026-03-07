import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/services/event_services.dart';

/// Service for computing group activity status based on event registration cadence.
///
/// A group is flagged as **inactive** if it has not registered an event within
/// 1.5 months (45 days) from the last event.
class GroupActivityService {
  /// Duration without an event before a group is considered inactive.
  static const Duration inactivityThreshold = Duration(days: 45);

  final EventServices _eventServices = EventServices();

  /// Returns true if the group is inactive: no event in the last 1.5 months from the most recent event.
  /// Groups with no events at all are also considered inactive.
  Future<bool> isGroupInactive(String groupId) async {
    final pastEvents = await _eventServices.getPastEvents(groupId);
    if (pastEvents.isEmpty) return true;

    pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final lastEvent = pastEvents.first;
    final now = DateTime.now();
    final daysSinceLastEvent = now.difference(lastEvent.dateTime).inDays;

    return daysSinceLastEvent > inactivityThreshold.inDays;
  }

  /// Returns the last event date for the group, or null if no events.
  Future<DateTime?> getLastEventDate(String groupId) async {
    final pastEvents = await _eventServices.getPastEvents(groupId);
    if (pastEvents.isEmpty) return null;

    pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return pastEvents.first.dateTime;
  }

  /// Returns activity status for display: 'Active' or 'Inactive'.
  Future<Map<String, dynamic>> getGroupActivityStatus(String groupId) async {
    final isInactive = await isGroupInactive(groupId);
    final lastEvent = await getLastEventDate(groupId);
    return {
      'status': isInactive ? 'Inactive' : 'Active',
      'isInactive': isInactive,
      'lastEventDate': lastEvent,
    };
  }
}
