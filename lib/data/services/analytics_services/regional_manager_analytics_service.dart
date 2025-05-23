import 'dart:convert';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:group_management_church_app/data/services/http_client.dart';

import '../../models/regional_analytics_model.dart';

class RegionAnalyticsService {
  final String baseUrl;
  final HttpClient _httpClient = HttpClient();

  RegionAnalyticsService({
    required this.baseUrl,
  });

  // Helper method to validate UUID
  bool _isValidUuid(String id) {
    return Uuid.isValidUUID(fromString: id);
  }

  // Group-specific analytics for region
  Future<GroupDemographics> getGroupDemographicsForRegion(
    String groupId,
  ) async {
    if (!_isValidUuid(groupId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/group/$groupId/demographics'
      );

      if (response.statusCode == 200) {
        return GroupDemographics.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch group demographics: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching group demographics: $error');
    }
  }

  // Get region dashboard summary
  Future<DashboardSummary> getDashboardSummaryForRegion(String regionId) async {
    try {
      print('Fetching dashboard summary for region: $regionId');
      print('API Endpoint: ${ApiEndpoints.baseUrl}/regional-manager/analytics/dashboard/summary');
      
      final response = await _httpClient.get(
        '${ApiEndpoints.baseUrl}/regional-manager/analytics/dashboard/summary',
      );

      print('Dashboard Summary API Response Status: ${response.statusCode}');
      print('Dashboard Summary API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Parsed dashboard data: $data');
        
        // Ensure all required fields are present with proper types
        return DashboardSummary(
          userCount: data['userCount'] is int ? data['userCount'] : 0,
          groupCount: data['groupCount'] is int ? data['groupCount'] : 0,
          eventCount: data['eventCount'] is int ? data['eventCount'] : 0,
          attendanceCount: data['attendanceCount'] is int ? data['attendanceCount'] : null,
          recentEvents: data['recentEvents'] is List ? data['recentEvents'] : [],
        );
      } else {
        print('Error response from API: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch dashboard summary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      print('Error details: ${e.toString()}');
      if (e is Exception) {
        print('Exception type: ${e.runtimeType}');
      }
      // Return a default DashboardSummary with null attendanceCount
      return DashboardSummary(
        userCount: 0,
        groupCount: 0,
        eventCount: 0,
        attendanceCount: null,
        recentEvents: [],
      );
    }
  }

  // Get region attendance stats
  Future<RegionAttendanceStats> getRegionAttendanceStats(String regionId) async {
    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/$regionId/attendance'
      );

      if (response.statusCode == 200) {
        return RegionAttendanceStats.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch region attendance stats: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching region attendance stats: $error');
    }
  }

  // Get region growth analytics
  Future<RegionGrowthAnalytics> getRegionGrowthAnalytics(String regionId) async {
    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/$regionId/growth'
      );

      if (response.statusCode == 200) {
        return RegionGrowthAnalytics.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch region growth analytics: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching region growth analytics: $error');
    }
  }

  // Compare groups in region
  Future<GroupComparisonResult> compareGroupsInRegion(
    List<String> groupIds,
    String regionId,
  ) async {
    if (groupIds.isEmpty) {
      throw Exception('Group IDs list cannot be empty');
    }

    // Validate all UUIDs
    for (final id in groupIds) {
      if (!_isValidUuid(id)) {
        throw Exception('Invalid UUID format: $id');
      }
    }

    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      final response = await _httpClient.post(
        '$baseUrl/api/analytics/region/$regionId/compare-groups',
        body: {'groupIds': groupIds}
      );

      if (response.statusCode == 200) {
        return GroupComparisonResult.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to compare groups: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error comparing groups: $error');
    }
  }

  // Get event participation stats
  Future<EventParticipationStats> getEventParticipationStatsForRegion(
    String eventId,
  ) async {
    if (!_isValidUuid(eventId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/event/$eventId/participation'
      );

      if (response.statusCode == 200) {
        return EventParticipationStats.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch event participation stats: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching event participation stats: $error');
    }
  }

  // Compare event attendance in region
  Future<List<EventAttendanceComparison>> compareEventAttendanceInRegion(
    List<String> eventIds,
    String regionId,
  ) async {
    if (eventIds.isEmpty) {
      throw Exception('Event IDs list cannot be empty');
    }

    // Validate all UUIDs
    for (final id in eventIds) {
      if (!_isValidUuid(id)) {
        throw Exception('Invalid UUID format: $id');
      }
    }

    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      final response = await _httpClient.post(
        '$baseUrl/api/analytics/region/$regionId/compare-events',
        body: {'eventIds': eventIds}
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => EventAttendanceComparison.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to compare event attendance: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error comparing event attendance: $error');
    }
  }

  // Get user attendance trends
  Future<UserAttendanceTrends> getUserAttendanceTrendsForRegion(
    String userId,
    String regionId,
  ) async {
    if (!_isValidUuid(userId)) {
      throw Exception('Invalid user UUID format');
    }

    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/$regionId/user/$userId/attendance'
      );

      if (response.statusCode == 200) {
        return UserAttendanceTrends.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch user attendance trends: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching user attendance trends: $error');
    }
  }

  // Get overall attendance by period
  Future<AttendanceByPeriod> getOverallAttendanceByPeriodForRegion(
    String period,
    String regionId,
  ) async {
    if (!['week', 'month', 'year'].contains(period)) {
      throw Exception('Invalid period. Must be week, month, or year');
    }

    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      print('Fetching overall attendance by period for region: $regionId');
      print('Period: $period');
      print('API Endpoint: $baseUrl/regional-manager/analytics/attendance/overall/$period');
      
      final response = await _httpClient.get(
        '${ApiEndpoints.baseUrl}/regional-manager/analytics/attendance/overall/$period'
      );

      print('Overall Attendance API Response Status: ${response.statusCode}');
      print('Overall Attendance API Response Headers: ${response.headers}');
      print('Overall Attendance API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return AttendanceByPeriod.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch overall attendance: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (error) {
      print('Error fetching overall attendance: $error');
      print('Error details: ${error.toString()}');
      if (error is Exception) {
        print('Exception type: ${error.runtimeType}');
      }
      throw Exception('Error fetching overall attendance: $error');
    }
  }

  Future<GroupAttendanceStats> getGroupAttendanceStatsForRegion(
    String groupId,
  ) async {
    if (!_isValidUuid(groupId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '${ApiEndpoints.baseUrl}/regional-manager/analytics/groups/$groupId/attendance',
      );

      if (response.statusCode == 200) {
        return GroupAttendanceStats.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch group attendance stats: ${response.statusCode}'
        );
      }
    } catch (error) {
      print('Error fetching group attendance stats for region: $error');
      throw Exception('Failed to fetch group attendance stats: $error');
    }
  }

  Future<GroupGrowthAnalytics> getGroupGrowthAnalyticsForRegion(
    String groupId,
  ) async {
    if (!_isValidUuid(groupId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/group/$groupId/growth'
      );

      if (response.statusCode == 200) {
        return GroupGrowthAnalytics.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch group growth analytics: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching group growth analytics: $error');
    }
  }

  Future<GroupDashboardData> getGroupDashboardDataForRegion(
    String groupId,
  ) async {
    if (!_isValidUuid(groupId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/group/$groupId/dashboard'
      );

      if (response.statusCode == 200) {
        return GroupDashboardData.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch group dashboard data: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching group dashboard data: $error');
    }
  }

  // Region-specific analytics
  Future<RegionDemographics> getRegionDemographics(String regionId) async {
    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      final response = await _httpClient.get(
        '$baseUrl/api/analytics/region/$regionId/demographics'
      );

      if (response.statusCode == 200) {
        return RegionDemographics.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch region demographics: ${response.statusCode}'
        );
      }
    } catch (error) {
      throw Exception('Error fetching region demographics: $error');
    }
  }

  Future<AttendanceByPeriodStats> getAttendanceByPeriodForRegion(
    String period,
    String regionId,
  ) async {
    if (!['week', 'month', 'year'].contains(period)) {
      throw Exception('Invalid period. Must be week, month, or year');
    }

    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid region UUID format');
    }

    try {
      print('Fetching attendance by period for region: $regionId');
      print('Period: $period');
      print('API Endpoint: $baseUrl/analytics/region/$regionId/attendance-by-period/$period');
      
      final response = await _httpClient.get(
        '$baseUrl/analytics/region/$regionId/attendance-by-period/$period'
      );

      print('Attendance API Response Status: ${response.statusCode}');
      print('Attendance API Response Headers: ${response.headers}');
      print('Attendance API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return AttendanceByPeriodStats.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch attendance by period: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (error) {
      print('Error fetching attendance by period: $error');
      print('Error details: ${error.toString()}');
      if (error is Exception) {
        print('Exception type: ${error.runtimeType}');
      }
      throw Exception('Error fetching attendance by period: $error');
    }
  }

  Future<MemberActivityStatus> getMemberActivityStatusForRegion(
    String regionId,
  ) async {
    if (!_isValidUuid(regionId)) {
      throw Exception('Invalid UUID format');
    }

    try {
      print('Fetching member activity status for region: $regionId');
      print('API Endpoint: $baseUrl/analytics/region/$regionId/member-activity');
      
      final response = await _httpClient.get(
        '${ApiEndpoints.baseUrl}/regional-manager/analytics/members/activity-status',
      );

      print('Member Activity API Response Status: ${response.statusCode}');
      print('Member Activity API Response Headers: ${response.headers}');
      print('Member Activity API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return MemberActivityStatus.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to fetch member activity status: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (error) {
      print('Error fetching member activity status: $error');
      print('Error details: ${error.toString()}');
      if (error is Exception) {
        print('Exception type: ${error.runtimeType}');
      }
      throw Exception('Error fetching member activity status: $error');
    }
  }
}
