import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/event_services.dart';

class EventProvider extends ChangeNotifier {
  // Private fields
  final EventServices _eventServices = EventServices();
  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  List<UserModel> _attendedMembers = [];
  Map<String, dynamic> _eventAttendance = {};
  Map<String, dynamic> _groupAttendance = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentGroupId;

  // Getters
  List<EventModel> get events => _events;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get pastEvents => _pastEvents;
  List<UserModel> get attendedMembers => _attendedMembers;
  Map<String, dynamic> get eventAttendance => _eventAttendance;
  Map<String, dynamic> get groupAttendance => _groupAttendance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentGroupId => _currentGroupId;

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(String operation, dynamic error) {
    _errorMessage = 'Error $operation: $error';
    debugPrint(_errorMessage);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setCurrentGroup(String groupId) {
    _currentGroupId = groupId;
    notifyListeners();
  }

  // SECTION: Event Management

  /// Fetch all events for a specific group
  Future<void> fetchEventsByGroup(String groupId) async {
    _setLoading(true);
    try {
      _events = await _eventServices.getEventsByGroup(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching events', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch a specific event by ID
  Future<EventModel?> fetchEventById(String eventId) async {
    _setLoading(true);
    try {
      final event = await _eventServices.getEventById(eventId);
      _errorMessage = null;
      return event;
    } catch (error) {
      _handleError('fetching event details', error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new event
  Future<EventModel?> createEvent({
    required String groupId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
  }) async {
    _setLoading(true);
    try {
      final event = await _eventServices.createEvent(
        groupId: groupId,
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
      );
      await fetchEventsByGroup(groupId);
      _errorMessage = null;
      return event;
    } catch (error) {
      _handleError('creating event', error);
      _setLoading(false); // Set loading to false here since fetchEventsByGroup won't be called
      return null;
    }
  }

  /// Update an existing event
  Future<EventModel?> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String groupId,
  }) async {
    _setLoading(true);
    try {
      final event = await _eventServices.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
        groupId: groupId,
      );
      await fetchEventsByGroup(groupId);
      _errorMessage = null;
      return event;
    } catch (error) {
      _handleError('updating event', error);
      _setLoading(false);
      return null;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId, String groupId) async {
    _setLoading(true);
    try {
      final result = await _eventServices.deleteEvent(eventId, groupId);
      if (result) {
        await fetchEventsByGroup(groupId);
      }
      _errorMessage = null;
      return result;
    } catch (error) {
      _handleError('deleting event', error);
      _setLoading(false);
      return false;
    }
  }

  // SECTION: Event Filtering

  /// Get all events for a group (non-state changing)
  Future<List<EventModel>> getGroupEvents(String groupId) async {
    try {
      return await _eventServices.getEventsByGroup(groupId);
    } catch (error) {
      _handleError('getting group events', error);
      return [];
    }
  }

  /// Fetch upcoming events for a group
  Future<void> fetchUpcomingEvents(String groupId) async {
    _setLoading(true);
    try {
      _upcomingEvents = await _eventServices.getUpcomingEvents(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching upcoming events', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch past events for a group
  Future<void> fetchPastEvents(String groupId) async {
    _setLoading(true);
    try {
      _pastEvents = await _eventServices.getPastEvents(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching past events', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch events for a specific date range
  Future<List<EventModel>> fetchEventsByDateRange(
    String groupId,
    DateTime startDate,
    DateTime endDate
  ) async {
    _setLoading(true);
    try {
      final events = await _eventServices.getEventsByDateRange(
        groupId,
        startDate,
        endDate
      );
      _errorMessage = null;
      return events;
    } catch (error) {
      _handleError('fetching events by date range', error);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Attendance Management

  /// Create attendance records for an event
  Future<bool> createEventAttendance(
    String eventId,
    List<String> attendedMemberIds
  ) async {
    _setLoading(true);
    try {
      final result = await _eventServices.createEventAttendance(
        eventId,
        attendedMemberIds
      );
      _errorMessage = null;
      return result;
    } catch (error) {
      _handleError('creating attendance records', error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch members who attended an event
  Future<void> fetchAttendedMembers(String eventId) async {
    _setLoading(true);
    try {
      _attendedMembers = await _eventServices.getAttendedMembers(eventId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching attended members', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch attendance details for an event
  Future<void> fetchEventAttendance(String eventId) async {
    _setLoading(true);
    try {
      _eventAttendance = await _eventServices.getEventAttendance(eventId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching event attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch attendance statistics for a group
  Future<void> fetchGroupAttendance(String groupId) async {
    _setLoading(true);
    try {
      _groupAttendance = await _eventServices.getGroupAttendance(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Mark attendance for an individual member
  Future<bool> markAttendance({
    required String eventId,
    required String userId,
    required bool present,
    String? topic,
    String? aob,
    String? apology,
  }) async {
    _setLoading(true);
    try {
      final result = await _eventServices.markAttendance(
        eventId,
        userId,
        present,
        topic: topic,
        aob: aob,
        apology: apology,
      );
      if (result) {
        await fetchAttendedMembers(eventId);
        await fetchEventAttendance(eventId);
      }
      _errorMessage = null;
      return result;
    } catch (error) {
      _handleError('marking attendance', error);
      _setLoading(false);
      return false;
    }
  }

  /// Refresh all event data for the current group
  Future<void> refreshAllEventData() async {
    if (_currentGroupId == null) {
      _handleError('refreshing data', 'No group selected');
      return;
    }

    _setLoading(true);
    try {
      await Future.wait([
        fetchEventsByGroup(_currentGroupId!),
        fetchUpcomingEvents(_currentGroupId!),
        fetchPastEvents(_currentGroupId!),
        fetchGroupAttendance(_currentGroupId!),
      ]);
      _errorMessage = null;
    } catch (error) {
      _handleError('refreshing event data', error);
    } finally {
      _setLoading(false);
    }
  }
}