import 'dart:convert';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/services/event_services.dart';
import 'package:group_management_church_app/data/services/group_services.dart';
import 'package:group_management_church_app/data/services/http_client.dart';

/// Service for computing and applying member inactivity rules based on consecutive absences.
///
/// Rules:
/// - 6 consecutive events missed **without apology** → mark inactive
/// - 12 consecutive events missed (with or without apology) → mark inactive
class MemberActivityService {
  static const int _consecutiveWithoutApologyThreshold = 6;
  static const int _consecutiveWithApologyThreshold = 12;

  final EventServices _eventServices = EventServices();
  final GroupServices _groupServices = GroupServices();
  final HttpClient _httpClient = HttpClient();

  /// Returns user IDs that should be marked inactive based on their attendance history.
  /// Events are ordered from most recent to oldest; we count consecutive absences from the most recent.
  Future<List<String>> computeMembersToMarkInactive(String groupId) async {
    final pastEvents = await _eventServices.getPastEvents(groupId);
    pastEvents.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // most recent first

    if (pastEvents.isEmpty) return [];

    final memberIds = await _getGroupMemberIds(groupId);
    if (memberIds.isEmpty) return [];

    final Map<String, Map<String, AttendanceModel>> eventIdToAttendance = {};
    for (final event in pastEvents) {
      try {
        final records = await _eventServices.getEventAttendance(event.id);
        eventIdToAttendance[event.id] = {for (var r in records) r.userId: r};
      } catch (_) {
        // Skip events we can't load attendance for
      }
    }

    final toMarkInactive = <String>{};
    for (final memberId in memberIds) {
      var consecutiveTotal = 0;
      var consecutiveWithoutApology = 0;

      for (final event in pastEvents) {
        final attendanceMap = eventIdToAttendance[event.id];
        if (attendanceMap == null) continue;

        final record = attendanceMap[memberId];
        if (record == null) continue; // no record, skip (conservative)

        if (record.isPresent) {
          consecutiveTotal = 0;
          consecutiveWithoutApology = 0;
          continue;
        }

        // Absent
        consecutiveTotal++;
        final hasApology = record.apology != null &&
            record.apology.toString().trim().isNotEmpty;
        if (!hasApology) {
          consecutiveWithoutApology++;
        } else {
          consecutiveWithoutApology = 0;
        }

        if (consecutiveWithoutApology >= _consecutiveWithoutApologyThreshold) {
          toMarkInactive.add(memberId);
          break;
        }
        if (consecutiveTotal >= _consecutiveWithApologyThreshold) {
          toMarkInactive.add(memberId);
          break;
        }
      }
    }

    return toMarkInactive.toList();
  }

  Future<Set<String>> _getGroupMemberIds(String groupId) async {
    try {
      final members = await _groupServices.fetchGroupMembers(groupId);
      final ids = <String>{};
      for (final m in members) {
        if (m is! Map) continue;
        final id = m['id'] ?? m['user_id'] ?? m['userId'] ?? m['_id'];
        if (id != null && id.toString().isNotEmpty) {
          ids.add(id.toString());
        }
      }
      return ids;
    } catch (_) {
      return {};
    }
  }

  /// Calls the backend to mark the given members as inactive.
  /// Backend must implement this endpoint; if not available, this will fail silently.
  Future<void> markMembersInactive(String groupId, List<String> userIds) async {
    if (userIds.isEmpty) return;

    for (final userId in userIds) {
      try {
        final response = await _httpClient.put(
          await ApiEndpoints.markGroupMemberInactive(groupId, userId),
          body: jsonEncode({'is_active': false}),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // success
        }
      } catch (_) {
        // Backend may not have this endpoint yet; log but don't throw
      }
    }
  }

  /// Check group members and mark any that meet the inactivity rules.
  /// Call this after marking attendance (fire-and-forget).
  Future<void> checkAndMarkInactiveAfterAttendance(
    String groupId,
  ) async {
    try {
      final toMark = await computeMembersToMarkInactive(groupId);
      if (toMark.isNotEmpty) {
        await markMembersInactive(groupId, toMark);
      }
    } catch (_) {
      // Don't propagate; this runs in the background
    }
  }
}
