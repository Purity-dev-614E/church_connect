import 'dart:convert';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:http/http.dart' as http;

/// Service class for analytics and reporting functionality
class AnalyticsServices {
  final AuthServices _authServices = AuthServices();
  final UserServices _userServices = UserServices();
  
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
      "Authorization": "Bearer $token"
    };
  }

  /// Check if user has permission to access analytics
  Future<void> _checkAnalyticsPermission() async {
    final userRole = await _userServices.getUserRole();
    
    if (userRole == null) {
      throw Exception('User role is null');
    }
    
    // Only super_admin and admin can access analytics
    // Note: roles are stored with underscores in the database
    if (userRole != 'super_admin' && userRole != 'super admin' && userRole != 'admin') {
      throw Exception('User does not have permission to access analytics');
    }
  }
  
  // SECTION: Group Analytics
  
  /// Get demographic information for a specific group
  /// 
  /// Returns detailed demographic breakdown of the group members
  Future<Map<String, dynamic>> getGroupDemographics(String groupId) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getGroupDemographics(groupId)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch group demographics: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch group demographics: $e');
    }
  }
  
  /// Get attendance statistics for a specific group
  /// 
  /// Returns detailed attendance data for the group
  Future<Map<String, dynamic>> getGroupAttendanceStats(String groupId) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getGroupAttendance(groupId)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch group attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch group attendance: $e');
    }
  }
  
  /// Get group growth over time
  /// 
  /// Returns data showing how group membership has changed over time
  Future<Map<String, dynamic>> getGroupGrowthAnalytics(String groupId) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getGroupById(groupId)}/growth'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch group growth data: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch group growth data: $e');
    }
  }
  
  /// Compare multiple groups by various metrics
  /// 
  /// Returns comparative data for the specified groups
  Future<Map<String, dynamic>> compareGroups(List<String> groupIds) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.groups}/compare'),
        headers: await _getHeaders(),
        body: jsonEncode({'group_ids': groupIds}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to compare groups: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to compare groups: $e');
    }
  }
  
  // SECTION: Attendance Analytics
  
  /// Get attendance statistics by week
  /// 
  /// Returns attendance data aggregated by week
  Future<Map<String, dynamic>> getAttendanceByWeek() async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByWeek),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch weekly attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weekly attendance: $e');
    }
  }
  
  /// Get attendance statistics by month
  /// 
  /// Returns attendance data aggregated by month
  Future<Map<String, dynamic>> getAttendanceByMonth() async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByMonth),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch monthly attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch monthly attendance: $e');
    }
  }
  
  /// Get attendance statistics by year
  /// 
  /// Returns attendance data aggregated by year
  Future<Map<String, dynamic>> getAttendanceByYear() async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByYear),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch yearly attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch yearly attendance: $e');
    }
  }
  
  /// Get attendance statistics for a specific period
  /// 
  /// Period can be 'week', 'month', 'year', or a custom range
  Future<Map<String, dynamic>> getAttendanceByPeriod(String period) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByPeriod(period)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch attendance by period: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch attendance by period: $e');
    }
  }
  
  /// Get overall attendance statistics by period across all groups
  /// 
  /// Returns aggregated attendance data for all groups
  Future<Map<String, dynamic>> getOverallAttendanceByPeriod(String period) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getOverallAttendanceByPeriod(period)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch overall attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch overall attendance: $e');
    }
  }
  
  /// Get attendance trends for a specific user
  /// 
  /// Returns historical attendance data for a specific user
  Future<Map<String, dynamic>> getUserAttendanceTrends(String userId) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByUser(userId)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch user attendance trends: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user attendance trends: $e');
    }
  }
  
  // SECTION: Event Analytics
  
  /// Get event participation statistics
  /// 
  /// Returns data about event participation rates
  Future<Map<String, dynamic>> getEventParticipationStats(String eventId) async {
    try {
      await _checkAnalyticsPermission();
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.getAttendanceByEvent(eventId)),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch event participation stats: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch event participation stats: $e');
    }
  }
  
  /// Compare event attendance across multiple events
  /// 
  /// Returns comparative attendance data for the specified events
  Future<Map<String, dynamic>> compareEventAttendance(List<String> eventIds) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.events}/compare-attendance'),
        headers: await _getHeaders(),
        body: jsonEncode({'event_ids': eventIds}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to compare event attendance: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to compare event attendance: $e');
    }
  }
  
  // SECTION: Member Analytics
  
  /// Get member participation statistics
  /// 
  /// Returns data about which members are most active
  Future<Map<String, dynamic>> getMemberParticipationStats() async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.get(
        Uri.parse('${ApiEndpoints.users}/participation-stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch member participation stats: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch member participation stats: $e');
    }
  }
  
  /// Get member retention statistics
  /// 
  /// Returns data about member retention over time
  Future<Map<String, dynamic>> getMemberRetentionStats() async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.get(
        Uri.parse('${ApiEndpoints.users}/retention-stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch member retention stats: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch member retention stats: $e');
    }
  }
  
  // SECTION: Custom Analytics
  
  /// Generate a custom analytics report
  /// 
  /// Allows for custom parameters to generate specialized reports
  Future<Map<String, dynamic>> generateCustomReport({
    required String reportType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/analytics/custom-report'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'report_type': reportType,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate custom report: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate custom report: $e');
    }
  }
  
  /// Export analytics data to a specific format
  /// 
  /// Formats can include 'csv', 'pdf', 'excel'
  Future<String> exportAnalyticsData({
    required String dataType,
    required String format,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/analytics/export'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'data_type': dataType,
          'format': format,
          'parameters': parameters,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['download_url'] ?? '';
      } else {
        throw Exception('Failed to export analytics data: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to export analytics data: $e');
    }
  }
  
  // SECTION: Dashboard Analytics
  
  /// Get summary statistics for dashboard display
  /// 
  /// Returns key metrics for dashboard visualization
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/analytics/dashboard-summary'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard summary: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard summary: $e');
    }
  }
  
  /// Get group-specific dashboard data
  /// 
  /// Returns key metrics for a specific group's dashboard
  Future<Map<String, dynamic>> getGroupDashboardData(String groupId) async {
    try {
      await _checkAnalyticsPermission();
      
      // This endpoint is hypothetical - you may need to implement it on the backend
      final response = await http.get(
        Uri.parse('${ApiEndpoints.getGroupById(groupId)}/dashboard-data'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch group dashboard data: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch group dashboard data: $e');
    }
  }
  
  // SECTION: Local Analytics Processing
  
  /// Calculate attendance rate for a group
  /// 
  /// Processes local data to calculate attendance percentage
  double calculateAttendanceRate(List<AttendanceModel> attendanceRecords) {
    if (attendanceRecords.isEmpty) return 0.0;
    
    final presentCount = attendanceRecords.where((record) => record.isPresent).length;
    return (presentCount / attendanceRecords.length) * 100;
  }
  
  /// Calculate growth rate between two periods
  /// 
  /// Returns percentage growth between previous and current values
  double calculateGrowthRate(int previousValue, int currentValue) {
    if (previousValue == 0) return currentValue > 0 ? 100.0 : 0.0;
    
    return ((currentValue - previousValue) / previousValue) * 100;
  }
  
  /// Generate attendance trend data from raw attendance records
  /// 
  /// Processes attendance data into a format suitable for trend visualization
  Map<String, dynamic> generateAttendanceTrendData(List<AttendanceModel> attendanceRecords, List<EventModel> events) {
    // Group events by month
    final Map<String, List<EventModel>> eventsByMonth = {};
    for (final event in events) {
      final monthKey = '${event.dateTime.year}-${event.dateTime.month.toString().padLeft(2, '0')}';
      if (!eventsByMonth.containsKey(monthKey)) {
        eventsByMonth[monthKey] = [];
      }
      eventsByMonth[monthKey]!.add(event);
    }
    
    // Calculate attendance rates by month
    final Map<String, double> attendanceRatesByMonth = {};
    for (final entry in eventsByMonth.entries) {
      final monthKey = entry.key;
      final monthEvents = entry.value;
      
      final List<AttendanceModel> monthAttendance = [];
      for (final event in monthEvents) {
        final eventAttendance = attendanceRecords.where((record) => record.eventId == event.id).toList();
        monthAttendance.addAll(eventAttendance);
      }
      
      attendanceRatesByMonth[monthKey] = calculateAttendanceRate(monthAttendance);
    }
    
    // Format data for visualization
    final List<Map<String, dynamic>> trendData = [];
    for (final entry in attendanceRatesByMonth.entries) {
      trendData.add({
        'period': entry.key,
        'attendance_rate': entry.value,
      });
    }
    
    return {
      'trend_data': trendData,
      'average_rate': trendData.isEmpty ? 0.0 : 
        trendData.map((item) => item['attendance_rate'] as double).reduce((a, b) => a + b) / trendData.length,
    };
  }
}