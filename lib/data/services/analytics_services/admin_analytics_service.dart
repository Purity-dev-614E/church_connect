import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:http/http.dart' as http;

class AdminAnalyticsService {
  final String baseUrl;
  final Map<String, String> headers;

  AdminAnalyticsService({
    required this.baseUrl,
    required String token,
  }) : headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

  // Helper method to handle HTTP responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to complete request');
    }
  }

  // Group Analytics - Admin can only access their own group
  Future<Map<String, dynamic>> getGroupDemographics(
    String groupId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/groups/$groupId/demographics')
        .replace(queryParameters: queryParams);
        
    final response = await http.get(
      uri,
      headers: headers,
    );
    print(response);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getGroupAttendanceStats(
    String groupId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/groups/$groupId/attendance')
        .replace(queryParameters: queryParams);
        
    final response = await http.get(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getGroupGrowthAnalytics(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/growth'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Attendance Analytics - Admin can only access their own group's attendance
  Future<Map<String, dynamic>> getGroupAttendanceByPeriod(String groupId, String period) async {
    if (!['week', 'month', 'year'].contains(period)) {
      throw ArgumentError('Period must be one of: week, month, year');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/attendance/period/$period'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Event Analytics - Admin can only access their own group's events
  Future<Map<String, dynamic>> getEventParticipationStats(
    String eventId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/events/$eventId/participation')
        .replace(queryParameters: queryParams);
        
    final response = await http.get(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Member Analytics - Admin can only access members of their own group
  Future<Map<String, dynamic>> getGroupMemberParticipationStats(
    String groupId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/admin/analytics/groups/$groupId/members/participation')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getGroupMemberActivityStatus(String groupId) async {
    final token = await FlutterSecureStorage().read(key: AuthServices.accessTokenKey);
    final response = await http.get(
      Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/admin/analytics/groups/$groupId/members/activity-status'),
      headers: {
        'Content-Type': 'application',
        'Authorization': 'Bearer $token'
      },
    );
    print('Activity Status ${response.body}');
    return _handleResponse(response);
  }

  // Dashboard Analytics - Admin can only access their own group's dashboard
  Future<Map<String, dynamic>> getGroupDashboardData(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/dashboard'),
      headers: headers,
    );
    return _handleResponse(response);
  }
}