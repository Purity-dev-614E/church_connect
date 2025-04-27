import 'dart:convert';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:http/http.dart' as http;
import '../../models/super_analytics_model.dart';
import '../user_services.dart';
import '../http_client.dart';

class SuperAdminAnalyticsService {
  String baseUrl = ApiEndpoints.baseUrl;
  final AuthServices _authServices = AuthServices();
  final HttpClient _httpClient = HttpClient();

  SuperAdminAnalyticsService({
    required this.baseUrl,
  });

  // Helper method to create headers with authentication and token refresh
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authServices.getAccessToken();
    if (token == null) {
      throw Exception('Authentication token is null');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper method to handle HTTP response and refresh token if needed
  Future<http.Response> _handleRequest(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      
      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401) {
        print('Token expired, attempting to refresh...');
        final refreshed = await _authServices.refreshToken();
        
        if (refreshed) {
          print('Token refreshed successfully, retrying request...');
          return await requestFunction();
        } else {
          print('Token refresh failed');
          throw Exception('Authentication failed. Please login again.');
        }
      }
      
      // Handle other errors
      if (response.statusCode >= 400) {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
      
      return response;
    } catch (e) {
      print('HTTP request error: $e');
      rethrow;
    }
  }

  // Group Analytics

  /// Get demographic breakdown of a group
  Future<GroupDemographics> getGroupDemographics(String groupId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/groups/$groupId/demographics');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return GroupDemographics.fromJson(data);
  }

  /// Get attendance statistics for a group
  Future<GroupAttendanceStats> getGroupAttendanceStats(String groupId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/groups/$groupId/attendance');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return GroupAttendanceStats.fromJson(data);
  }

  /// Get growth analytics for a group
  Future<GroupGrowthAnalytics> getGroupGrowthAnalytics(String groupId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/groups/$groupId/growth');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return GroupGrowthAnalytics.fromJson(data);
  }

  /// Compare multiple groups
  Future<GroupComparison> compareGroups(List<String> groupIds) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/groups/compare');
    
    final response = await _handleRequest(() async {
      return await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({'groupIds': groupIds}),
      );
    });

    final data = json.decode(response.body);
    return GroupComparison.fromJson(data);
  }

  // Attendance Analytics

  /// Get attendance statistics for a specific period (week, month, year)
  Future<AttendanceByPeriod> getAttendanceByPeriod(String period) async {
    if (!['week', 'month', 'year'].contains(period)) {
      throw ArgumentError('Period must be one of: week, month, year');
    }

    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/attendance/period/$period');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return AttendanceByPeriod.fromJson(data);
  }

  /// Get overall attendance statistics for a specific period
  Future<OverallAttendanceByPeriod> getOverallAttendanceByPeriod(String period) async {
    if (!['week', 'month', 'year'].contains(period)) {
      throw ArgumentError('Period must be one of: week, month, year');
    }

    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/attendance/overall/$period');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return OverallAttendanceByPeriod.fromJson(data);
  }

  /// Get attendance trends for a specific user
  Future<Map<String, dynamic>> getUserAttendanceTrends(String userId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/users/$userId/attendance-trends');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return data;
  }

  // Event Analytics

  /// Get participation statistics for an event
  Future<EventParticipationStats> getEventParticipationStats(String eventId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/events/$eventId/participation');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return EventParticipationStats.fromJson(data);
  }

  /// Compare attendance across multiple events
  Future<EventAttendanceComparison> compareEventAttendance(List<String> eventIds) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/events/compare-attendance');
    
    final response = await _handleRequest(() async {
      return await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({'eventIds': eventIds}),
      );
    });

    final data = json.decode(response.body);
    return EventAttendanceComparison.fromJson(data);
  }

  // Member Analytics

  /// Get participation statistics for members
  Future<Map<String, dynamic>> getMemberParticipationStats({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final uri = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/members/participation-stats')
        .replace(queryParameters: queryParams);
    
    final response = await _handleRequest(() async {
      return await http.get(uri, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return data;
  }

  /// Get activity status for all members
  Future<MemberActivityStatus> getMemberActivityStatus() async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/apisuper-admin/analytics/members/activity-status');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return MemberActivityStatus.fromJson(data);
  }

  // Dashboard Analytics

  /// Get overall dashboard summary
  Future<DashboardSummary> getDashboardSummary() async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/dashboard/summary');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return DashboardSummary.fromJson(data);
  }

  /// Get dashboard data for a specific group
  Future<GroupDashboardData> getGroupDashboardData(String groupId) async {
    final url = Uri.parse('https://safari-backend-production-bf65.up.railway.app/api/super-admin/analytics/dashboard/group/$groupId');
    
    final response = await _handleRequest(() async {
      return await http.get(url, headers: await _getHeaders());
    });

    final data = json.decode(response.body);
    return GroupDashboardData.fromJson(data);
  }
}

