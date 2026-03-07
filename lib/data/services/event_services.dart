import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/core/utils/api_error_handler.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/participant_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/data/services/http_client.dart';

/// Service class for managing group-specific events and attendance
class EventServices {
  final AuthServices _authServices;
  final UserServices _userServices;
  final HttpClient _httpClient;

  EventServices({
    AuthServices? authServices,
    UserServices? userServices,
    HttpClient? httpClient,
  }) : _authServices = authServices ?? AuthServices(),
       _userServices = userServices ?? UserServices(),
       _httpClient = httpClient ?? HttpClient();

  // SECTION: Authentication and Authorization

  /// Get authentication token
  Future<String> _getToken() async {
    final token = await _authServices.getAccessToken();
    if (token == null) {
      throw Exception('Authentication token is null');
    }
    return token;
  }

  /// Get default HTTP headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Check if user has permission to manage events for a specific group
  Future<void> _checkGroupPermission(String groupId) async {
    final userRole = await _userServices.getUserRole();
    final userId = await _authServices.getUserId();

    if (userId == null) {
      throw Exception('User ID is null');
    }

    if (userRole == null) {
      throw Exception('User role is null');
    }

    // Root and super admin have permission for all groups (root bypasses RBAC)
    if (RoleUtils.isRoot(userRole) ||
        userRole == 'super_admin' ||
        userRole == 'super admin') {
      return;
    }

    // For regular admins, check if they are the admin of this group
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getGroupById(groupId),
      );

      if (response.statusCode == 200) {
        final groupData = jsonDecode(response.body);
        if (groupData['admin_id'] != userId) {
          throw Exception(
            'You do not have permission to manage events for this group',
          );
        }
      } else {
        throw Exception('Failed to verify group permissions');
      }
    } catch (e) {
      throw Exception('Failed to verify group permissions: $e');
    }
  }

  // SECTION: Event Management

  /// Check if user has permission to create leadership events
  Future<void> _checkLeadershipPermission() async {
    final userRole = await _userServices.getUserRole();

    if (userRole == null) {
      throw Exception('User role is null');
    }

    // Allow root, super admin, and regional leadership to create leadership events
    if (!RoleUtils.isRoot(userRole) &&
        !RoleUtils.isSuperAdmin(userRole) &&
        !RoleUtils.isRegionalLeadership(userRole)) {
      throw Exception(
        'Only super admin, root, and regional managers can create leadership events',
      );
    }
  }

  /// Handle group event specific error messages
  String _handleGroupEventError(int statusCode, dynamic errorData) {
    switch (statusCode) {
      case 400:
        final error = errorData['error']?.toString() ?? '';
        if (error.contains(
          'Leadership events must be created using the /api/events/leadership endpoint',
        )) {
          return 'Please select "Leadership Event" type to create this event';
        }
        if (error.contains('This endpoint only accepts leadership events')) {
          return 'Leadership events cannot be created as group events';
        }
        return 'Invalid event data';
      case 404:
        return 'Group not found - please select a valid group';
      case 403:
        return 'Access denied - insufficient permissions';
      default:
        return 'Failed to create event: HTTP status $statusCode';
    }
  }

  /// Create a new leadership event
  ///
  /// Returns the created [EventModel] with all details
  /// Leadership events automatically have group_id set to null by the backend
  Future<EventModel> createLeadershipEvent({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    String? regionId,
  }) async {
    try {
      // Check if user has permission to create leadership events
      await _checkLeadershipPermission();

      final body = <String, dynamic>{
        'title': title,
        'description': description,
        // Send UTC to avoid server timezone reinterpretation
        'date': dateTime.toUtc().toIso8601String(),
        'location': location,
        'tag': 'leadership',
        // Do not include group_id - backend will set it to null
        // Include region_id if provided (for regional managers)
        if (regionId != null) 'region_id': regionId,
      };

      final response = await _httpClient.post(
        ApiEndpoints.createLeadershipEvent,
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = ApiErrorHandler.getErrorMessage(
          response.statusCode,
          errorData,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create leadership event: $e');
    }
  }

  /// Create a new event for a specific group
  ///
  /// Returns the created [EventModel] with all details
  Future<EventModel> createEvent({
    String? groupId, // Make nullable for leadership events
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    String tag = 'org',
  }) async {
    try {
      // Use different endpoint for leadership events
      final endpoint =
          (tag == 'leadership')
              ? ApiEndpoints.createLeadershipEvent
              : ApiEndpoints.createGroupEvent(groupId ?? '');

      final response = await _httpClient.post(
        endpoint,
        body: {
          'title': title,
          'description': description,
          // Send UTC to avoid server timezone reinterpretation
          'date': dateTime.toUtc().toIso8601String(),
          'location': location,
          if (groupId != null) 'group_id': groupId, // Only include if not null
          'tag': tag,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = _handleGroupEventError(
          response.statusCode,
          errorData,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  /// Get all events for a specific group
  ///
  /// Returns a list of [EventModel] objects for the specified group
  Future<List<EventModel>> getEventsByGroup(String groupId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getEventsByGroup(groupId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((event) => EventModel.fromJson(event)).toList();
      } else {
        throw Exception(
          'Failed to fetch group events: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch group events: $e');
    }
  }

  /// Get a specific event by ID
  ///
  /// Returns the [EventModel] for the specified event ID
  Future<EventModel> getEventById(String eventId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getEventById(eventId),
      );

      if (response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to fetch event: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  /// Update an existing event
  ///
  /// Returns the updated [EventModel] with all details
  Future<EventModel> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String groupId,
  }) async {
    try {
      final existing = await getEventById(eventId);
      if (existing.isAttendanceLocked) {
        throw Exception(
          'Event cannot be edited after 24 hours from the event start time.',
        );
      }

      final response = await _httpClient.put(
        ApiEndpoints.updateEvent(eventId),
        body: {
          'title': title,
          'description': description,
          // Send UTC to avoid server timezone reinterpretation
          'date': dateTime.toUtc().toIso8601String(),
          'location': location,
          'group_id': groupId,
        },
      );

      if (response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to update event: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete an event
  ///
  /// Returns true if deletion was successful
  Future<bool> deleteEvent(String eventId, String groupId) async {
    try {
      final event = await getEventById(eventId);
      if (event.isAttendanceLocked) {
        throw Exception(
          'Event cannot be deleted after 24 hours from the event start time.',
        );
      }

      final response = await _httpClient.delete(
        ApiEndpoints.deleteEvent(eventId),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to delete event: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // SECTION: Event Filtering

  /// Get upcoming events for a group
  ///
  /// Returns a list of [EventModel] objects for future events
  Future<List<EventModel>> getUpcomingEvents(String groupId) async {
    try {
      final allEvents = await getEventsByGroup(groupId);
      final now = DateTime.now();

      return allEvents.where((event) => event.dateTime.isAfter(now)).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  /// Get past events for a group
  ///
  /// Returns a list of [EventModel] objects for past events
  Future<List<EventModel>> getPastEvents(String groupId) async {
    try {
      final allEvents = await getEventsByGroup(groupId);
      final now = DateTime.now();

      return allEvents.where((event) => event.dateTime.isBefore(now)).toList();
    } catch (e) {
      throw Exception('Failed to fetch past events: $e');
    }
  }

  /// Get events for a specific date range
  ///
  /// Returns a list of [EventModel] objects within the specified date range
  Future<List<EventModel>> getEventsByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allEvents = await getEventsByGroup(groupId);

      return allEvents
          .where(
            (event) =>
                event.dateTime.isAfter(startDate) &&
                event.dateTime.isBefore(endDate),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events by date range: $e');
    }
  }

  //getall events
  Future<List<EventModel>> getAllEvents(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.events);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((event) => EventModel.fromJson(event)).toList();
      } else {
        throw Exception(
          'Failed to fetch all events: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch all events: $e');
    }
  }

  // SECTION: Attendance Management

  /// Create attendance records for an event
  ///
  /// Takes an event ID and a list of member IDs who attended
  /// Returns true if attendance was successfully recorded
  Future<bool> createEventAttendance(
    String eventId,
    List<String> attendedMemberIds,
  ) async {
    try {
      final event = await getEventById(eventId);
      if (event.isAttendanceLocked) {
        throw Exception(
          'Attendance cannot be changed after 24 hours from the event start time.',
        );
      }

      final response = await _httpClient.post(
        ApiEndpoints.createEventAttendance(eventId),
        body: {'event_id': eventId, 'attended_members': attendedMemberIds},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to create attendance: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create attendance: $e');
    }
  }

  /// Get members who attended an event
  ///
  /// Returns a list of user data for members who attended the event
  Future<List<UserModel>> getAttendedMembers(String eventId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getAttendedMembers(eventId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => UserModel.fromJson(user)).toList();
      } else {
        throw Exception(
          'Failed to fetch attended members: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch attended members: $e');
    }
    return [];
  }

  /// Get attendance details for an event
  /// Returns attendance statistics and details for the specified event
  Future<List<AttendanceModel>> getEventAttendance(String eventId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getAttendanceByEvent(eventId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Map the dynamic list to a list of AttendanceModel
        return data.map((item) => AttendanceModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to fetch event attendance: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch event attendance: $e');
    }
  }

  /// Get attendance statistics for a group
  ///
  /// Returns overall attendance statistics for all events in the group
  Future<Map<String, dynamic>> getGroupAttendance(String groupId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getGroupAttendance(groupId),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 500) {
        // Handle server error gracefully
        print(
          'Server error (500) when fetching group attendance for group $groupId',
        );
        // Return default attendance data to prevent app crash
        return {
          'totalMembers': 0,
          'averageAttendance': 0.0,
          'attendanceRate': 0.0,
          'error': 'Server error occurred while fetching attendance data',
        };
      } else {
        throw Exception(
          'Failed to fetch group attendance: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getGroupAttendance: $e');
      // Return default data on any error to prevent app crash
      return {
        'totalMembers': 0,
        'averageAttendance': 0.0,
        'attendanceRate': 0.0,
        'error': 'Failed to fetch attendance data',
      };
    }
  }

  /// Mark attendance for an individual member
  ///
  /// Records attendance for a single user with optional details
  Future<bool> markAttendance(
    String eventId,
    String userId,
    bool present, {
    String? topic,
    String? aob,
    String? apology,
  }) async {
    try {
      final event = await getEventById(eventId);
      if (event.isAttendanceLocked) {
        throw Exception(
          'Attendance cannot be changed after 24 hours from the event start time.',
        );
      }

      final body = buildAttendancePayload(
        eventId: eventId,
        userId: userId,
        present: present,
        topic: topic,
        aob: aob,
        apology: apology,
      );

      final response = await _httpClient.post(
        ApiEndpoints.createEventAttendance(eventId),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Failed to mark attendance: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  @visibleForTesting
  Map<String, dynamic> buildAttendancePayload({
    required String eventId,
    required String userId,
    required bool present,
    String? topic,
    String? aob,
    String? apology,
  }) {
    final payload = {
      'event_id': eventId,
      'user_id': userId,
      'present': present,
    };

    if (present) {
      if (topic != null) payload['topic'] = topic;
      if (aob != null) payload['aob'] = aob;
    } else {
      if (apology != null) payload['apology'] = apology;
    }

    return payload;
  }

  /// Get attendance records for a specific user
  ///
  /// Returns a list of attendance records with event details for the specified user
  Future<List<Map<String, dynamic>>> getUserAttendanceRecords(
    String userId,
  ) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getAttendanceByUser(userId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Fetch event details for each attendance record
        List<Map<String, dynamic>> attendanceWithEvents = [];

        for (var record in data) {
          try {
            final eventId = record['event_Id'] ?? '';
            if (eventId.isNotEmpty) {
              final eventDetails = await getEventById(eventId);
              attendanceWithEvents.add({
                'attendance': record,
                'event': eventDetails.toJson(),
              });
            } else {
              attendanceWithEvents.add({'attendance': record, 'event': null});
            }
          } catch (e) {
            print('Error fetching event details: $e');
            attendanceWithEvents.add({'attendance': record, 'event': null});
          }
        }

        return attendanceWithEvents;
      } else {
        throw Exception(
          'Failed to fetch user attendance records: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch user attendance records: $e');
    }
  }

  /// Get events by region
  Future<List<EventModel>> getEventsByRegion(String regionId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getEventsByRegion(regionId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((event) => EventModel.fromJson(event)).toList();
      } else if (response.statusCode == 404) {
        // No events found for this region
        return [];
      } else {
        throw Exception(
          'Failed to fetch region events: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching events by region: $e');

      // Fallback: Try to get all events and filter by region
      try {
        final allEvents = await getOverallEvents();
        return allEvents.where((event) => event.regionId == regionId).toList();
      } catch (fallbackError) {
        throw Exception(
          'Failed to fetch region events: $e, Fallback error: $fallbackError',
        );
      }
    }
  }

  /// Get all events
  Future<List<EventModel>> getOverallEvents() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.events);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((event) => EventModel.fromJson(event)).toList();
      } else {
        throw Exception(
          'Failed to fetch all events: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch all events: $e');
    }
  }

  /// Get leadership events
  Future<List<EventModel>> getLeadershipEvents() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.leadershipEvents);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((event) => EventModel.fromJson(event)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = ApiErrorHandler.getErrorMessage(
          response.statusCode,
          errorData,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to fetch leadership events: $e');
    }
  }

  /// Get leadership event participants
  Future<List<Participant>> getLeadershipEventParticipants(
    String eventId, {
    String? targetAudience,
  }) async {
    try {
      String url = ApiEndpoints.getEventParticipants(eventId);
      if (targetAudience != null) {
        url += '?target_audience=$targetAudience';
      }

      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((participant) => Participant.fromJson(participant))
            .toList();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = ApiErrorHandler.getParticipantErrorMessage(
          response.statusCode,
          errorData,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to load participants: $e');
    }
  }

  /// Mark attendance for leadership events
  Future<bool> markLeadershipAttendance({
    required String eventId,
    required String userId,
    required bool present,
    String? notes,
  }) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.createLeadershipAttendance(eventId),
        body: json.encode({
          'user_id': userId,
          'present': present,
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = ApiErrorHandler.getAttendanceErrorMessage(
          response.statusCode,
          errorData,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }
}
