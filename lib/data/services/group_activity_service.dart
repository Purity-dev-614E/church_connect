import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/services/event_services.dart';

/// Service for computing group activity status based on event registration cadence.
///
/// A group is flagged as **inactive** if it has not registered an event within
/// 1.5 months (45 days) from the last event.
class GroupActivityService {
  /// Duration without an event before a group is considered inactive.
  static const Duration inactivityThreshold = Duration(days: 45);

  /// Cache duration - activity status is cached for 1 hour
  static const Duration _cacheDuration = Duration(hours: 1);

  final EventServices _eventServices = EventServices();
  final Map<String, _CachedResult> _cache = {};

  /// Returns true if the group is inactive: no event in the last 1.5 months from the most recent event.
  /// Groups with no events at all are also considered inactive.
  /// Results are cached for 1 hour to improve performance.
  Future<bool> isGroupInactive(String groupId) async {
    // Check cache first
    final cached = _cache[groupId];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheDuration) {
      return cached.isInactive;
    }

    // Calculate fresh result
    final pastEvents = await _eventServices.getPastEvents(groupId);
    if (pastEvents.isEmpty) {
      _cache[groupId] = _CachedResult(true, DateTime.now());
      return true;
    }

    pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final lastEvent = pastEvents.first;
    final now = DateTime.now();
    final daysSinceLastEvent = now.difference(lastEvent.dateTime).inDays;

    final isInactive = daysSinceLastEvent > inactivityThreshold.inDays;

    // Cache the result
    _cache[groupId] = _CachedResult(isInactive, DateTime.now());

    return isInactive;
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

  /// Clear the cache - useful for testing or when fresh data is needed
  void clearCache() {
    _cache.clear();
  }
}

/// Internal class to cache activity check results
class _CachedResult {
  final bool isInactive;
  final DateTime timestamp;

  _CachedResult(this.isInactive, this.timestamp);
}
