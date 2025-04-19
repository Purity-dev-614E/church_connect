import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/event_services.dart';

class AttendanceProvider extends ChangeNotifier {
  // Private fields
  final EventServices _eventServices = EventServices();
  List<UserModel> _attendedMembers = [];
  List<UserModel> _absentMembers = [];
  Map<String, dynamic> _eventAttendance = {};
  Map<String, dynamic> _groupAttendance = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentEventId;

  // Getters
  List<UserModel> get attendedMembers => _attendedMembers;
  List<UserModel> get absentMembers => _absentMembers;
  Map<String, dynamic> get eventAttendance => _eventAttendance;
  Map<String, dynamic> get groupAttendance => _groupAttendance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentEventId => _currentEventId;

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

  void setCurrentEvent(String eventId) {
    _currentEventId = eventId;
    notifyListeners();
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
      if (result) {
        await fetchAttendedMembers(eventId);
        await fetchEventAttendance(eventId);
      }
      _errorMessage = null;
      return result;
    } catch (error) {
      _handleError('creating attendance records', error);
      _setLoading(false);
      return false;
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

  /// Calculate and set absent members based on all group members and attended members
  void calculateAbsentMembers(List<UserModel> allGroupMembers) {
    final Set<String> attendedIds = _attendedMembers.map((user) => user.id).toSet();
    _absentMembers = allGroupMembers
        .where((member) => !attendedIds.contains(member.id))
        .toList();
    notifyListeners();
  }

  /// Fetch attendance details for an event
 Future<List<AttendanceModel>> fetchEventAttendance(String eventId) async {
   _setLoading(true);
   try {
     final attendanceData = await _eventServices.getEventAttendance(eventId);
     _eventAttendance = attendanceData;
     _errorMessage = null;

     // Transform the response into a list of AttendanceModel
     List<AttendanceModel> attendanceList = [];
     
     try {
       // Handle different response formats
       if (attendanceData is List) {
         // If it's already a list, map each item to AttendanceModel
         attendanceList = (attendanceData as List).map((item) {
           if (item is Map<String, dynamic>) {
             return AttendanceModel.fromJson(item);
           } else {
             // Skip non-map items
             throw Exception('Invalid attendance item format');
           }
         }).where((model) => model != null).toList();
       } else if (attendanceData is Map) {
         // Check for common response structures
         if (attendanceData.containsKey('attendance') && attendanceData['attendance'] is List) {
           // Format: { "attendance": [...] }
           attendanceList = (attendanceData['attendance'] as List).map((item) {
             if (item is Map<String, dynamic>) {
               return AttendanceModel.fromJson(item);
             } else {
               throw Exception('Invalid attendance item format');
             }
           }).where((model) => model != null).toList();
         } else if (attendanceData.containsKey('records') && attendanceData['records'] is List) {
           // Format: { "records": [...] }
           attendanceList = (attendanceData['records'] as List).map((item) {
             if (item is Map<String, dynamic>) {
               return AttendanceModel.fromJson(item);
             } else {
               throw Exception('Invalid attendance item format');
             }
           }).where((model) => model != null).toList();
         } else if (attendanceData.containsKey('data') && attendanceData['data'] is List) {
           // Format: { "data": [...] }
           attendanceList = (attendanceData['data'] as List).map((item) {
             if (item is Map<String, dynamic>) {
               return AttendanceModel.fromJson(item);
             } else {
               throw Exception('Invalid attendance item format');
             }
           }).where((model) => model != null).toList();
         } else if (attendanceData.containsKey('items') && attendanceData['items'] is List) {
           // Format: { "items": [...] }
           attendanceList = (attendanceData['items'] as List).map((item) {
             if (item is Map<String, dynamic>) {
               return AttendanceModel.fromJson(item);
             } else {
               throw Exception('Invalid attendance item format');
             }
           }).where((model) => model != null).toList();
         } else if (attendanceData.containsKey('results') && attendanceData['results'] is List) {
           // Format: { "results": [...] }
           attendanceList = (attendanceData['results'] as List).map((item) {
             if (item is Map<String, dynamic>) {
               return AttendanceModel.fromJson(item);
             } else {
               throw Exception('Invalid attendance item format');
             }
           }).where((model) => model != null).toList();
         } else {
           // Try to find any list in the map
           bool foundList = false;
           for (var key in attendanceData.keys) {
             if (attendanceData[key] is List && (attendanceData[key] as List).isNotEmpty) {
               attendanceList = (attendanceData[key] as List).map((item) {
                 if (item is Map<String, dynamic>) {
                   return AttendanceModel.fromJson(item);
                 } else {
                   return null;
                 }
               }).where((model) => model != null).cast<AttendanceModel>().toList();
               foundList = true;
               break;
             }
           }
           
           // If no list was found, try to convert each entry in the map
           if (!foundList) {
             attendanceList = attendanceData.entries.map((entry) {
               if (entry.value is Map<String, dynamic>) {
                 try {
                   Map<String, dynamic> attendanceMap = entry.value as Map<String, dynamic>;
                   // Add the key as id if not present
                   if (!attendanceMap.containsKey('id')) {
                     attendanceMap['id'] = entry.key;
                   }
                   return AttendanceModel.fromMap(attendanceMap);
                 } catch (e) {
                   print('Error parsing attendance entry: $e');
                   return null;
                 }
               } else {
                 // Create a default model if the structure is unexpected
                 return AttendanceModel(
                   id: entry.key,
                   userId: '',
                   eventId: eventId,
                   isPresent: false
                 );
               }
             }).where((model) => model != null).cast<AttendanceModel>().toList();
           }
         }
       }
     } catch (e) {
       print('Error processing attendance data: $e');
       // Return empty list on parsing error
       return [];
     }

     return attendanceList;
   } catch (error) {
     _handleError('fetching event attendance', error);
     return [];
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

  /// Mark multiple members as present or absent
  Future<bool> markBulkAttendance({
    required String eventId,
    required List<String> userIds,
    required bool present,
  }) async {
    _setLoading(true);
    try {
      bool allSuccessful = true;
      
      for (final userId in userIds) {
        final success = await _eventServices.markAttendance(
          eventId,
          userId,
          present,
        );
        
        if (!success) {
          allSuccessful = false;
        }
      }
      
      // Refresh attendance data
      await fetchAttendedMembers(eventId);
      await fetchEventAttendance(eventId);
      
      _errorMessage = null;
      return allSuccessful;
    } catch (error) {
      _handleError('marking bulk attendance', error);
      _setLoading(false);
      return false;
    }
  }

  /// Get attendance rate for a specific member across all events in a group
  double getMemberAttendanceRate(String userId, List<String> allEventIds) {
    if (allEventIds.isEmpty) return 0.0;
    
    try {
      int attendedCount = 0;
      
      for (final eventId in allEventIds) {
        final attended = _eventAttendance[eventId]?['attended_members'] ?? [];
        if (attended.contains(userId)) {
          attendedCount++;
        }
      }
      
      return attendedCount / allEventIds.length;
    } catch (error) {
      _handleError('calculating member attendance rate', error);
      return 0.0;
    }
  }

  /// Refresh all attendance data for the current event
  Future<void> refreshAllAttendanceData(String groupId) async {
    if (_currentEventId == null) {
      _handleError('refreshing data', 'No event selected');
      return;
    }

    _setLoading(true);
    try {
      await Future.wait([
        fetchAttendedMembers(_currentEventId!),
        fetchEventAttendance(_currentEventId!),
        fetchGroupAttendance(groupId),
      ]);
      _errorMessage = null;
    } catch (error) {
      _handleError('refreshing attendance data', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Get attendance records for a specific user with event details
  Future<List<Map<String, dynamic>>> getUserAttendanceRecords(String userId) async {
    _setLoading(true);
    try {
      final records = await _eventServices.getUserAttendanceRecords(userId);
      _errorMessage = null;
      return records;
    } catch (error) {
      _handleError('fetching user attendance records', error);
      return [];
    } finally {
      _setLoading(false);
    }
  }
}