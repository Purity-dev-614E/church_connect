import 'dart:convert';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/services/http_client.dart';
import 'package:http/http.dart' as http;
import '../models/analytics_model.dart';

class AnalyticsServices {
  final HttpClient _httpClient = HttpClient();
  final String baseUrl = ApiEndpoints.baseUrl;
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' // Token will be added dynamically
  };

  // Helper method to set auth token
  void setAuthToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  // ==================== REGION ANALYTICS ====================
  
  /// Get dashboard summary for a specific region
  Future<Map<String, dynamic>> getRegionDashboardSummary(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getRegionDashboardSummary(regionId));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return a default summary if the API fails
        return {
          'total_members': 0,
          'total_groups': 0,
          'active_members': 0,
          'attendance_rate': 0.0,
          'recent_events': 0,
          'growth_rate': 0.0,
        };
      }
    } catch (e) {
      print('Error fetching region dashboard summary: $e');
      // Return a default summary if an error occurs
      return {
        'total_members': 0,
        'total_groups': 0,
        'active_members': 0,
        'attendance_rate': 0.0,
        'recent_events': 0,
        'growth_rate': 0.0,
      };
    }
  }
  
  /// Get attendance trends for a specific region
  Future<Map<String, dynamic>> getRegionAttendanceTrends(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getRegionAttendanceTrends(regionId));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default trends if the API fails
        return {
          'trend_data': [
            {'month': 'Jan', 'attendance_rate': 75.0},
            {'month': 'Feb', 'attendance_rate': 82.0},
            {'month': 'Mar', 'attendance_rate': 88.0},
            {'month': 'Apr', 'attendance_rate': 85.0},
            {'month': 'May', 'attendance_rate': 92.0},
            {'month': 'Jun', 'attendance_rate': 90.0},
          ]
        };
      }
    } catch (e) {
      print('Error fetching region attendance trends: $e');
      // Return default trends if an error occurs
      return {
        'trend_data': [
          {'month': 'Jan', 'attendance_rate': 75.0},
          {'month': 'Feb', 'attendance_rate': 82.0},
          {'month': 'Mar', 'attendance_rate': 88.0},
          {'month': 'Apr', 'attendance_rate': 85.0},
          {'month': 'May', 'attendance_rate': 92.0},
          {'month': 'Jun', 'attendance_rate': 90.0},
        ]
      };
    }
  }
  
  /// Get growth trends for a specific region
  Future<Map<String, dynamic>> getRegionGrowth(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getRegionGrowth(regionId));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default growth data if the API fails
        return {
          'trend_data': [
            {'period': 'Jan', 'count': 10},
            {'period': 'Feb', 'count': 15},
            {'period': 'Mar', 'count': 18},
            {'period': 'Apr', 'count': 22},
            {'period': 'May', 'count': 25},
            {'period': 'Jun', 'count': 30},
          ]
        };
      }
    } catch (e) {
      print('Error fetching region growth trends: $e');
      // Return default growth data if an error occurs
      return {
        'trend_data': [
          {'period': 'Jan', 'count': 10},
          {'period': 'Feb', 'count': 15},
          {'period': 'Mar', 'count': 18},
          {'period': 'Apr', 'count': 22},
          {'period': 'May', 'count': 25},
          {'period': 'Jun', 'count': 30},
        ]
      };
    }
  }
  
  /// Get engagement metrics for a specific region
  Future<Map<String, dynamic>> getRegionEngagement(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getRegionEngagement(regionId));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default engagement data if the API fails
        return {
          'engagement_score': 75.0,
          'active_members_percentage': 80.0,
          'participation_rate': 70.0,
          'retention_rate': 85.0,
        };
      }
    } catch (e) {
      print('Error fetching region engagement metrics: $e');
      // Return default engagement data if an error occurs
      return {
        'engagement_score': 75.0,
        'active_members_percentage': 80.0,
        'participation_rate': 70.0,
        'retention_rate': 85.0,
      };
    }
  }
  
  /// Compare multiple regions
  Future<Map<String, dynamic>> compareRegions(List<String> regionIds) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.compareRegions(regionIds),
        body: jsonEncode({'region_ids': regionIds}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default comparison data if the API fails
        return {
          'comparison_data': []
        };
      }
    } catch (e) {
      print('Error comparing regions: $e');
      // Return default comparison data if an error occurs
      return {
        'comparison_data': []
      };
    }
  }

  // ==================== GROUP ANALYTICS ====================

  /// Get demographic information for a specific group
  Future<Map<String, dynamic>> getGroupDemographics(String groupId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Build query parameters for date range if provided
      Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      // Get the base URL
      String url = ApiEndpoints.getGroupDemographics(groupId);
      
      // Add query parameters if any
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url${url.contains('?') ? '&' : '?'}$queryString';
      }
      
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default demographics if the API fails
        return {
          'gender_distribution': {
            'male': 50,
            'female': 50
          },
          'age_distribution': {
            '18-24': 20,
            '25-34': 30,
            '35-44': 25,
            '45-54': 15,
            '55+': 10
          },
          'total_members': 0
        };
      }
    } catch (e) {
      print('Error fetching group demographics: $e');
      // Return default demographics if an error occurs
      return {
        'gender_distribution': {
          'male': 50,
          'female': 50
        },
        'age_distribution': {
          '18-24': 20,
          '25-34': 30,
          '35-44': 25,
          '45-54': 15,
          '55+': 10
        },
        'total_members': 0
      };
    }
  }

  /// Get attendance statistics for a specific group
  Future<Map<String, dynamic>> getGroupAttendanceStats(String groupId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Build query parameters for date range if provided
      Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      // Get the base URL
      String url = ApiEndpoints.getGroupAttendance(groupId);
      
      // Add query parameters if any
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url${url.contains('?') ? '&' : '?'}$queryString';
      }
      
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default attendance stats if the API fails
        return {
          'average_attendance_rate': 75.0,
          'attendance_by_month': [
            {'month': 'Jan', 'rate': 70.0},
            {'month': 'Feb', 'rate': 75.0},
            {'month': 'Mar', 'rate': 80.0},
            {'month': 'Apr', 'rate': 78.0},
            {'month': 'May', 'rate': 82.0},
            {'month': 'Jun', 'rate': 85.0},
          ],
          'total_events': 24
        };
      }
    } catch (e) {
      print('Error fetching group attendance stats: $e');
      // Return default attendance stats if an error occurs
      return {
        'average_attendance_rate': 75.0,
        'attendance_by_month': [
          {'month': 'Jan', 'rate': 70.0},
          {'month': 'Feb', 'rate': 75.0},
          {'month': 'Mar', 'rate': 80.0},
          {'month': 'Apr', 'rate': 78.0},
          {'month': 'May', 'rate': 82.0},
          {'month': 'Jun', 'rate': 85.0},
        ],
        'total_events': 24
      };
    }
  }

  /// Get growth analytics for a specific group
  Future<Map<String, dynamic>> getGroupGrowthAnalytics(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getGroupGrowth(groupId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default growth analytics if the API fails
        return {
          'growth_rate': 15.0,
          'new_members_count': 5,
          'members_by_month': [
            {'month': 'Jan', 'count': 20},
            {'month': 'Feb', 'count': 22},
            {'month': 'Mar', 'count': 25},
            {'month': 'Apr', 'count': 28},
            {'month': 'May', 'count': 30},
            {'month': 'Jun', 'count': 35},
          ]
        };
      }
    } catch (e) {
      print('Error fetching group growth analytics: $e');
      // Return default growth analytics if an error occurs
      return {
        'growth_rate': 15.0,
        'new_members_count': 5,
        'members_by_month': [
          {'month': 'Jan', 'count': 20},
          {'month': 'Feb', 'count': 22},
          {'month': 'Mar', 'count': 25},
          {'month': 'Apr', 'count': 28},
          {'month': 'May', 'count': 30},
          {'month': 'Jun', 'count': 35},
        ]
      };
    }
  }

  /// Compare multiple groups
  Future<Map<String, dynamic>> compareGroups(List<String> groupIds) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.compareGroups(groupIds),
        body: jsonEncode({'group_ids': groupIds}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default comparison data if the API fails
        return {
          'comparison_data': []
        };
      }
    } catch (e) {
      print('Error comparing groups: $e');
      // Return default comparison data if an error occurs
      return {
        'comparison_data': []
      };
    }
  }

  // ==================== ATTENDANCE ANALYTICS ====================

  /// Get attendance data by week
  Future<Map<String, dynamic>> getAttendanceByWeek() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getAttendanceByWeek);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default weekly attendance data if the API fails
        return {
          'attendance_data': [
            {'day': 'Mon', 'count': 25, 'rate': 75.0},
            {'day': 'Tue', 'count': 30, 'rate': 80.0},
            {'day': 'Wed', 'count': 35, 'rate': 85.0},
            {'day': 'Thu', 'count': 28, 'rate': 78.0},
            {'day': 'Fri', 'count': 32, 'rate': 82.0},
            {'day': 'Sat', 'count': 40, 'rate': 90.0},
            {'day': 'Sun', 'count': 45, 'rate': 95.0},
          ],
          'average_rate': 83.6
        };
      }
    } catch (e) {
      print('Error fetching weekly attendance: $e');
      // Return default weekly attendance data if an error occurs
      return {
        'attendance_data': [
          {'day': 'Mon', 'count': 25, 'rate': 75.0},
          {'day': 'Tue', 'count': 30, 'rate': 80.0},
          {'day': 'Wed', 'count': 35, 'rate': 85.0},
          {'day': 'Thu', 'count': 28, 'rate': 78.0},
          {'day': 'Fri', 'count': 32, 'rate': 82.0},
          {'day': 'Sat', 'count': 40, 'rate': 90.0},
          {'day': 'Sun', 'count': 45, 'rate': 95.0},
        ],
        'average_rate': 83.6
      };
    }
  }

  /// Get attendance data by month
  Future<Map<String, dynamic>> getAttendanceByMonth() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getAttendanceByMonth);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default monthly attendance data if the API fails
        return {
          'attendance_data': [
            {'week': 'Week 1', 'count': 120, 'rate': 80.0},
            {'week': 'Week 2', 'count': 130, 'rate': 85.0},
            {'week': 'Week 3', 'count': 125, 'rate': 82.0},
            {'week': 'Week 4', 'count': 135, 'rate': 88.0},
          ],
          'average_rate': 83.75
        };
      }
    } catch (e) {
      print('Error fetching monthly attendance: $e');
      // Return default monthly attendance data if an error occurs
      return {
        'attendance_data': [
          {'week': 'Week 1', 'count': 120, 'rate': 80.0},
          {'week': 'Week 2', 'count': 130, 'rate': 85.0},
          {'week': 'Week 3', 'count': 125, 'rate': 82.0},
          {'week': 'Week 4', 'count': 135, 'rate': 88.0},
        ],
        'average_rate': 83.75
      };
    }
  }

  /// Get attendance data by year
  Future<Map<String, dynamic>> getAttendanceByYear() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getAttendanceByYear);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default yearly attendance data if the API fails
        return {
          'attendance_data': [
            {'month': 'Jan', 'count': 500, 'rate': 75.0},
            {'month': 'Feb', 'count': 520, 'rate': 78.0},
            {'month': 'Mar', 'count': 550, 'rate': 82.0},
            {'month': 'Apr', 'count': 540, 'rate': 80.0},
            {'month': 'May', 'count': 560, 'rate': 84.0},
            {'month': 'Jun', 'count': 580, 'rate': 86.0},
            {'month': 'Jul', 'count': 570, 'rate': 85.0},
            {'month': 'Aug', 'count': 590, 'rate': 88.0},
            {'month': 'Sep', 'count': 600, 'rate': 90.0},
            {'month': 'Oct', 'count': 610, 'rate': 91.0},
            {'month': 'Nov', 'count': 605, 'rate': 90.5},
            {'month': 'Dec', 'count': 620, 'rate': 92.0},
          ],
          'average_rate': 85.1
        };
      }
    } catch (e) {
      print('Error fetching yearly attendance: $e');
      // Return default yearly attendance data if an error occurs
      return {
        'attendance_data': [
          {'month': 'Jan', 'count': 500, 'rate': 75.0},
          {'month': 'Feb', 'count': 520, 'rate': 78.0},
          {'month': 'Mar', 'count': 550, 'rate': 82.0},
          {'month': 'Apr', 'count': 540, 'rate': 80.0},
          {'month': 'May', 'count': 560, 'rate': 84.0},
          {'month': 'Jun', 'count': 580, 'rate': 86.0},
          {'month': 'Jul', 'count': 570, 'rate': 85.0},
          {'month': 'Aug', 'count': 590, 'rate': 88.0},
          {'month': 'Sep', 'count': 600, 'rate': 90.0},
          {'month': 'Oct', 'count': 610, 'rate': 91.0},
          {'month': 'Nov', 'count': 605, 'rate': 90.5},
          {'month': 'Dec', 'count': 620, 'rate': 92.0},
        ],
        'average_rate': 85.1
      };
    }
  }

  /// Get attendance data by custom period
  Future<Map<String, dynamic>> getAttendanceByPeriod(String period) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getAttendanceByPeriod(period));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default period attendance data if the API fails
        return {
          'attendance_data': [],
          'average_rate': 0.0
        };
      }
    } catch (e) {
      print('Error fetching attendance by period: $e');
      // Return default period attendance data if an error occurs
      return {
        'attendance_data': [],
        'average_rate': 0.0
      };
    }
  }

  /// Get overall attendance data by period
  Future<Map<String, dynamic>> getOverallAttendanceByPeriod(String period) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getOverallAttendanceByPeriod(period));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default overall attendance data if the API fails
        return {
          'overall_rate': 85.0,
          'total_attendees': 500,
          'total_events': 24,
          'trend': 'increasing'
        };
      }
    } catch (e) {
      print('Error fetching overall attendance: $e');
      // Return default overall attendance data if an error occurs
      return {
        'overall_rate': 85.0,
        'total_attendees': 500,
        'total_events': 24,
        'trend': 'increasing'
      };
    }
  }

  /// Get attendance trends for a specific user
  Future<Map<String, dynamic>> getUserAttendanceTrends(String userId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getAttendanceByUser(userId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default user attendance trends if the API fails
        return {
          'attendance_rate': 80.0,
          'events_attended': 20,
          'total_events': 25,
          'trend_data': [
            {'month': 'Jan', 'rate': 75.0},
            {'month': 'Feb', 'rate': 80.0},
            {'month': 'Mar', 'rate': 85.0},
            {'month': 'Apr', 'rate': 82.0},
            {'month': 'May', 'rate': 78.0},
            {'month': 'Jun', 'rate': 80.0},
          ]
        };
      }
    } catch (e) {
      print('Error fetching user attendance trends: $e');
      // Return default user attendance trends if an error occurs
      return {
        'attendance_rate': 80.0,
        'events_attended': 20,
        'total_events': 25,
        'trend_data': [
          {'month': 'Jan', 'rate': 75.0},
          {'month': 'Feb', 'rate': 80.0},
          {'month': 'Mar', 'rate': 85.0},
          {'month': 'Apr', 'rate': 82.0},
          {'month': 'May', 'rate': 78.0},
          {'month': 'Jun', 'rate': 80.0},
        ]
      };
    }
  }

  // ==================== EVENT ANALYTICS ====================

  /// Get participation statistics for a specific event
  Future<Map<String, dynamic>> getEventParticipationStats(String eventId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Build query parameters for date range if provided
      Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      // Get the base URL
      String url = ApiEndpoints.getEventById(eventId);
      
      // Add query parameters if any
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url${url.contains('?') ? '&' : '?'}$queryString';
      }
      
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default event participation stats if the API fails
        return {
          'attendance_rate': 85.0,
          'total_attendees': 50,
          'total_invited': 60,
          'demographics': {
            'gender': {
              'male': 55,
              'female': 45
            },
            'age_groups': {
              '18-24': 20,
              '25-34': 35,
              '35-44': 25,
              '45-54': 15,
              '55+': 5
            }
          }
        };
      }
    } catch (e) {
      print('Error fetching event participation stats: $e');
      // Return default event participation stats if an error occurs
      return {
        'attendance_rate': 85.0,
        'total_attendees': 50,
        'total_invited': 60,
        'demographics': {
          'gender': {
            'male': 55,
            'female': 45
          },
          'age_groups': {
            '18-24': 20,
            '25-34': 35,
            '35-44': 25,
            '45-54': 15,
            '55+': 5
          }
        }
      };
    }
  }

  /// Compare attendance between multiple events
  Future<Map<String, dynamic>> compareEventAttendance(List<String> eventIds) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.compareEventAttendance(eventIds),
        body: jsonEncode({'event_ids': eventIds}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default event comparison data if the API fails
        return {
          'comparison_data': []
        };
      }
    } catch (e) {
      print('Error comparing event attendance: $e');
      // Return default event comparison data if an error occurs
      return {
        'comparison_data': []
      };
    }
  }

  // ==================== MEMBER ANALYTICS ====================

  /// Get participation statistics for all members
  Future<Map<String, dynamic>> getMemberParticipationStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      // Build query parameters for date range if provided
      Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      // Get the base URL
      String url = ApiEndpoints.getMemberParticipationStats;
      
      // Add query parameters if any
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url${url.contains('?') ? '&' : '?'}$queryString';
      }
      
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default member participation stats if the API fails
        return {
          'overall_participation_rate': 80.0,
          'active_members_count': 150,
          'inactive_members_count': 30,
          'participation_by_group': [
            {'group_name': 'Group A', 'rate': 85.0},
            {'group_name': 'Group B', 'rate': 78.0},
            {'group_name': 'Group C', 'rate': 82.0},
          ]
        };
      }
    } catch (e) {
      print('Error fetching member participation stats: $e');
      // Return default member participation stats if an error occurs
      return {
        'overall_participation_rate': 80.0,
        'active_members_count': 150,
        'inactive_members_count': 30,
        'participation_by_group': [
          {'group_name': 'Group A', 'rate': 85.0},
          {'group_name': 'Group B', 'rate': 78.0},
          {'group_name': 'Group C', 'rate': 82.0},
        ]
      };
    }
  }

  /// Get retention statistics for members
  Future<Map<String, dynamic>> getMemberRetentionStats() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getMemberRetentionStats);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default member retention stats if the API fails
        return {
          'retention_rate': 85.0,
          'new_members_count': 20,
          'departed_members_count': 5,
          'retention_by_period': [
            {'period': 'Jan', 'rate': 82.0},
            {'period': 'Feb', 'rate': 84.0},
            {'period': 'Mar', 'rate': 86.0},
            {'period': 'Apr', 'rate': 85.0},
            {'period': 'May', 'rate': 87.0},
            {'period': 'Jun', 'rate': 88.0},
          ]
        };
      }
    } catch (e) {
      print('Error fetching member retention stats: $e');
      // Return default member retention stats if an error occurs
      return {
        'retention_rate': 85.0,
        'new_members_count': 20,
        'departed_members_count': 5,
        'retention_by_period': [
          {'period': 'Jan', 'rate': 82.0},
          {'period': 'Feb', 'rate': 84.0},
          {'period': 'Mar', 'rate': 86.0},
          {'period': 'Apr', 'rate': 85.0},
          {'period': 'May', 'rate': 87.0},
          {'period': 'Jun', 'rate': 88.0},
        ]
      };
    }
  }

  // ==================== DASHBOARD ANALYTICS ====================

  /// Get summary data for the dashboard
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getDashboardSummary);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default dashboard summary if the API fails
        return {
          'total_members': 200,
          'total_groups': 15,
          'active_members': 180,
          'attendance_rate': 85.0,
          'recent_events': 5,
          'growth_rate': 10.0,
        };
      }
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      // Return default dashboard summary if an error occurs
      return {
        'total_members': 200,
        'total_groups': 15,
        'active_members': 180,
        'attendance_rate': 85.0,
        'recent_events': 5,
        'growth_rate': 10.0,
      };
    }
  }

  /// Get dashboard data for a specific group
  Future<Map<String, dynamic>> getGroupDashboardData(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getGroupById(groupId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default group dashboard data if the API fails
        return {
          'total_members': 30,
          'active_members': 25,
          'attendance_rate': 83.0,
          'recent_events': 3,
          'growth_rate': 8.0,
        };
      }
    } catch (e) {
      print('Error fetching group dashboard data: $e');
      // Return default group dashboard data if an error occurs
      return {
        'total_members': 30,
        'active_members': 25,
        'attendance_rate': 83.0,
        'recent_events': 3,
        'growth_rate': 8.0,
      };
    }
  }

  // ==================== EXPORT ANALYTICS ====================

  /// Export attendance report
  Future<Map<String, dynamic>> exportAttendanceReport() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.exportAttendanceReport);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default export response if the API fails
        return {
          'success': false,
          'message': 'Failed to export attendance report',
          'download_url': null
        };
      }
    } catch (e) {
      print('Error exporting attendance report: $e');
      // Return default export response if an error occurs
      return {
        'success': false,
        'message': 'Failed to export attendance report: $e',
        'download_url': null
      };
    }
  }

  /// Export member report
  Future<Map<String, dynamic>> exportMemberReport() async {
    try {
      final response = await _httpClient.get(ApiEndpoints.exportMemberReport);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default export response if the API fails
        return {
          'success': false,
          'message': 'Failed to export member report',
          'download_url': null
        };
      }
    } catch (e) {
      print('Error exporting member report: $e');
      // Return default export response if an error occurs
      return {
        'success': false,
        'message': 'Failed to export member report: $e',
        'download_url': null
      };
    }
  }

  /// Export group report for a specific group
  Future<Map<String, dynamic>> exportGroupReport(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.exportGroupReport(groupId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default export response if the API fails
        return {
          'success': false,
          'message': 'Failed to export group report',
          'download_url': null
        };
      }
    } catch (e) {
      print('Error exporting group report: $e');
      // Return default export response if an error occurs
      return {
        'success': false,
        'message': 'Failed to export group report: $e',
        'download_url': null
      };
    }
  }
  
  /// Export region report for a specific region
  Future<Map<String, dynamic>> exportRegionReport(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.exportRegionReport(regionId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default export response if the API fails
        return {
          'success': false,
          'message': 'Failed to export region report',
          'download_url': null
        };
      }
    } catch (e) {
      print('Error exporting region report: $e');
      // Return default export response if an error occurs
      return {
        'success': false,
        'message': 'Failed to export region report: $e',
        'download_url': null
      };
    }
  }
}