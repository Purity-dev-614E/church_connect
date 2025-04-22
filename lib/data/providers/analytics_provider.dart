import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/analytics_model.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';

class AnalyticsProvider extends ChangeNotifier {
  // Private fields
  final AnalyticsServices _analyticsService = AnalyticsServices();
  final AttendanceProvider _attendanceProvider = AttendanceProvider();
  final EventProvider _eventProvider = EventProvider();
  final GroupProvider _groupProvider = GroupProvider();
  final UserProvider _userProvider = UserProvider();
  
  // State management
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  
  // Date range for analytics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 180));
  DateTime _endDate = DateTime.now();
  
  // Group analytics data
  GroupDemographics? _groupDemographics;
  GroupAttendanceStats? _groupAttendanceStats;
  GroupGrowthAnalytics? _groupGrowthAnalytics;
  GroupComparisonResult? _groupComparisonData;
  GroupDashboardData? _groupDashboardData;

  // Attendance analytics data
  AttendanceData? _weeklyAttendance;
  AttendanceData? _monthlyAttendance;
  AttendanceData? _yearlyAttendance;
  AttendanceData? _periodAttendance;
  OverallAttendanceData? _overallAttendance;
  UserAttendanceTrends? _userAttendanceTrends;

  // Event analytics data
  EventParticipationStats? _eventParticipationStats;
  EventAttendanceComparison? _eventComparisonData;
  Map<String, dynamic> _eventAttendance = {}; // Keep as Map for custom processing

  // Member analytics data
  MemberParticipationStats? _memberParticipationStats;
  MemberRetentionStats? _memberRetentionStats;

  // Dashboard data
  DashboardSummary? _dashboardSummary;

  // Custom report data
  ReportData? _customReportData;
  String _exportUrl = '';

  // Enhanced analytics data - keep as Map<String, dynamic> for flexibility
  Map<String, dynamic>? _groupEngagementMetrics;
  Map<String, dynamic>? _groupActivityTimeline;
  Map<String, dynamic>? _groupAttendanceTrends;
  Map<String, dynamic>? _attendanceByEventType;
  Map<String, dynamic>? _upcomingEventsParticipationForecast;
  Map<String, dynamic>? _popularEvents;
  Map<String, dynamic>? _attendanceByEventCategory;
  Map<String, dynamic>? _memberEngagementScores;
  Map<String, dynamic>? _memberActivityLevels;
  Map<String, dynamic>? _attendanceCorrelationFactors;
  Map<String, dynamic>? _dashboardTrends;
  Map<String, dynamic>? _performanceMetrics;
  Map<String, dynamic>? _customDashboardData;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Group analytics getters
  GroupDemographics? get groupDemographics => _groupDemographics;
  GroupAttendanceStats? get groupAttendanceStats => _groupAttendanceStats;
  GroupGrowthAnalytics? get groupGrowthAnalytics => _groupGrowthAnalytics;
  GroupComparisonResult? get groupComparisonData => _groupComparisonData;
  GroupDashboardData? get groupDashboardData => _groupDashboardData;

  // Attendance analytics getters
  AttendanceData? get weeklyAttendance => _weeklyAttendance;
  AttendanceData? get monthlyAttendance => _monthlyAttendance;
  AttendanceData? get yearlyAttendance => _yearlyAttendance;
  AttendanceData? get periodAttendance => _periodAttendance;
  OverallAttendanceData? get overallAttendance => _overallAttendance;
  UserAttendanceTrends? get userAttendanceTrends => _userAttendanceTrends;

  // Event analytics getters
  EventParticipationStats? get eventParticipationStats => _eventParticipationStats;
  EventAttendanceComparison? get eventComparisonData => _eventComparisonData;
  Map<String, dynamic> get eventAttendance => _eventAttendance;

  // Member analytics getters
  MemberParticipationStats? get memberParticipationStats => _memberParticipationStats;
  MemberRetentionStats? get memberRetentionStats => _memberRetentionStats;

  // Dashboard getters
  DashboardSummary? get dashboardSummary => _dashboardSummary;

  // Custom report getters
  ReportData? get customReportData => _customReportData;
  String get exportUrl => _exportUrl;

  // Enhanced analytics getters
  Map<String, dynamic>? get groupEngagementMetrics => _groupEngagementMetrics;
  Map<String, dynamic>? get groupActivityTimeline => _groupActivityTimeline;
  Map<String, dynamic>? get groupAttendanceTrends => _groupAttendanceTrends;
  Map<String, dynamic>? get attendanceByEventType => _attendanceByEventType;
  Map<String, dynamic>? get upcomingEventsParticipationForecast => _upcomingEventsParticipationForecast;
  Map<String, dynamic>? get popularEvents => _popularEvents;
  Map<String, dynamic>? get attendanceByEventCategory => _attendanceByEventCategory;
  Map<String, dynamic>? get memberEngagementScores => _memberEngagementScores;
  Map<String, dynamic>? get memberActivityLevels => _memberActivityLevels;
  Map<String, dynamic>? get attendanceCorrelationFactors => _attendanceCorrelationFactors;
  Map<String, dynamic>? get dashboardTrends => _dashboardTrends;
  Map<String, dynamic>? get performanceMetrics => _performanceMetrics;
  Map<String, dynamic>? get customDashboardData => _customDashboardData;

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
  
  /// Set the date range for analytics queries
  void setDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }
  
  /// Clear all analytics data
  void clearAllData() {
    _groupDemographics = null;
    _groupAttendanceStats = null;
    _groupGrowthAnalytics = null;
    _groupComparisonData = null;
    _groupDashboardData = null;
    _weeklyAttendance = null;
    _monthlyAttendance = null;
    _yearlyAttendance = null;
    _periodAttendance = null;
    _overallAttendance = null;
    _userAttendanceTrends = null;
    _eventParticipationStats = null;
    _eventComparisonData = null;
    _eventAttendance = {};
    _memberParticipationStats = null;
    _memberRetentionStats = null;
    _dashboardSummary = null;
    _customReportData = null;
    _exportUrl = '';
    _groupEngagementMetrics = null;
    _groupActivityTimeline = null;
    _groupAttendanceTrends = null;
    _attendanceByEventType = null;
    _upcomingEventsParticipationForecast = null;
    _popularEvents = null;
    _attendanceByEventCategory = null;
    _memberEngagementScores = null;
    _memberActivityLevels = null;
    _attendanceCorrelationFactors = null;
    _dashboardTrends = null;
    _performanceMetrics = null;
    _customDashboardData = null;
    
    // Clear service cache if method exists
    if (_analyticsService is AnalyticsServices) {
      // Check if clearCache method exists
      try {
        // Use reflection to check if method exists
        final clearCacheMethod = _analyticsService.runtimeType.toString().contains('clearCache');
        if (clearCacheMethod) {
          // Call the method using dynamic to avoid compile-time errors
          (_analyticsService as dynamic).clearCache();
        }
      } catch (e) {
        debugPrint('Error clearing cache: $e');
      }
    }
    
    notifyListeners();
  }
  
  /// Generic method to handle API requests with deduplication
  Future<T> _fetchData<T>(
    String requestKey,
    Future<T> Function() apiCall,
    void Function(T) updateState,
    {bool forceRefresh = false}
  ) async {
    // If we're already loading this data and not forcing a refresh, return the existing request
    if (!forceRefresh && _pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey]!.future as T;
    }
    
    // Create a new completer for this request
    final completer = Completer<T>();
    _pendingRequests[requestKey] = completer;
    
    try {
      // Add date range parameters to the request key to ensure cache invalidation when date range changes
      final dateRangeKey = '${requestKey}_${_startDate.toIso8601String()}_${_endDate.toIso8601String()}';
      
      final response = await apiCall();
      
      // Update state
      updateState(response);
      
      // Complete the pending request
      completer.complete(response);
      _pendingRequests.remove(requestKey);
      
      return response;
    } catch (error) {
      // Handle error
      _handleError('fetching $requestKey', error);
      
      // Complete the pending request with error
      completer.completeError(error);
      _pendingRequests.remove(requestKey);
      
      // Rethrow the error to be handled by the caller
      throw error;
    }
  }
  
  /// Convert API response to Map<String, dynamic> with enhanced handling of different formats
  Map<String, dynamic> _convertToMap(dynamic response) {
    if (response == null) {
      return {};
    }
    
    // If it's already a Map<String, dynamic>, return it
    if (response is Map<String, dynamic>) {
      return response;
    }
    
    // If it's a Map but not <String, dynamic>, convert it
    if (response is Map) {
      try {
        Map<String, dynamic> convertedMap = {};
        response.forEach((key, value) {
          convertedMap[key.toString()] = value;
        });
        return convertedMap;
      } catch (e) {
        debugPrint('Error converting map: $e');
        return {'error': e.toString()};
      }
    }
    
    // If it's a List, convert it to a map with appropriate structure
    if (response is List) {
      try {
        // If it's a list of maps, try to find a common key to use as map keys
        if (response.isNotEmpty && response.first is Map) {
          final firstItem = response.first as Map;
          String? idField;
          
          // Try to find an ID field
          for (var possibleIdField in ['id', '_id', 'uid', 'key', 'name']) {
            if (firstItem.containsKey(possibleIdField)) {
              idField = possibleIdField;
              break;
            }
          }
          
          // If we found an ID field, use it to create a map
          if (idField != null) {
            Map<String, dynamic> itemsMap = {};
            for (var item in response) {
              if (item is Map && item.containsKey(idField)) {
                String key = item[idField].toString();
                itemsMap[key] = item;
              }
            }
            
            return {
              'items': response,
              'itemsMap': itemsMap,
              'count': response.length,
              'hasData': response.isNotEmpty
            };
          }
        }
        
        // Default list conversion
        return {
          'items': response,
          'count': response.length,
          'hasData': response.isNotEmpty
        };
      } catch (e) {
        debugPrint('Error converting list: $e');
        return {
          'error': e.toString(),
          'items': response,
          'count': response.length
        };
      }
    }
    
    // If it's a string, try to parse it as JSON
    if (response is String) {
      try {
        final decoded = jsonDecode(response);
        return _convertToMap(decoded);
      } catch (e) {
        debugPrint('Error parsing JSON string: $e');
        return {'value': response};
      }
    }
    
    // For primitive types, wrap them in a map
    if (response is num || response is bool) {
      return {'value': response};
    }
    
    // If all else fails, return an empty map with error
    return {'error': 'Unable to convert response to map'};
  }

  // SECTION: Group Analytics

  /// Fetch demographic information for a specific group
  Future<GroupDemographics> fetchGroupDemographics(String groupId) async {
    return _fetchData<GroupDemographics>(
      'group_demographics_$groupId',
      () async {
        final response = await _analyticsService.getGroupDemographics(
          groupId, 
          startDate: _startDate, 
          endDate: _endDate
        );
        return GroupDemographics.fromJson(response);
      },
      (response) {
        _groupDemographics = response;
        notifyListeners();
      }
    );
  }

  /// Fetch attendance statistics for a specific group
  Future<GroupAttendanceStats> fetchGroupAttendanceStats(String groupId) async {
    return _fetchData<GroupAttendanceStats>(
      'group_attendance_stats_$groupId',
      () async {
        final response = await _analyticsService.getGroupAttendanceStats(
          groupId,
          startDate: _startDate,
          endDate: _endDate
        );
        return GroupAttendanceStats.fromJson(response);
      },
      (response) {
        _groupAttendanceStats = response;
        notifyListeners();
      }
    );
  }

  /// Fetch group growth analytics
  Future<GroupGrowthAnalytics> fetchGroupGrowthAnalytics(String groupId) async {
    return _fetchData<GroupGrowthAnalytics>(
      'group_growth_analytics_$groupId',
      () async {
        final response = await _analyticsService.getGroupGrowthAnalytics(groupId);
        return GroupGrowthAnalytics.fromJson(response);
      },
      (response) {
        _groupGrowthAnalytics = response;
        notifyListeners();
      }
    );
  }

  /// Compare multiple groups
  Future<GroupComparisonResult> compareGroups(List<String> groupIds) async {
    final groupIdsString = groupIds.join('_');
    return _fetchData<GroupComparisonResult>(
      'compare_groups_$groupIdsString',
      () async {
        final response = await _analyticsService.compareGroups(groupIds);
        return GroupComparisonResult.fromJson(response);
      },
      (response) {
        _groupComparisonData = response;
        notifyListeners();
      }
    );
  }

  /// Fetch group dashboard data
  Future<GroupDashboardData> fetchGroupDashboardData(String groupId) async {
    return _fetchData<GroupDashboardData>(
      'group_dashboard_data_$groupId',
      () async {
        final response = await _analyticsService.getGroupDashboardData(groupId);
        return GroupDashboardData.fromJson(response);
      },
      (response) {
        _groupDashboardData = response;
        notifyListeners();
      }
    );
  }
  
  // /// Fetch group engagement metrics
  // Future<Map<String, dynamic>> fetchGroupEngagementMetrics(String groupId) async {
  //   try {
  //     final response = await _analyticsService.getGroupEngagementMetrics(groupId);
  //     _groupEngagementMetrics = _convertToMap(response);
  //     notifyListeners();
  //     return _groupEngagementMetrics ?? {};
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     return {
  //       'error': e.toString(),
  //       'items': [],
  //       'count': 0,
  //       'hasData': false
  //     };
  //   }
  // }
  //
  // /// Fetch group activity timeline
  // Future<void> fetchGroupActivityTimeline(String groupId) async {
  //   try {
  //     final response = await _analyticsService.getGroupActivityTimeline(groupId);
  //     _groupActivityTimeline = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   }
  // }
  //
  // /// Fetch group attendance trends
  // Future<Map<String, dynamic>> fetchGroupAttendanceTrends(String groupId) async {
  //   try {
  //     final response = await _analyticsService.getGroupAttendanceTrends(groupId);
  //     _groupAttendanceTrends = _convertToMap(response);
  //     notifyListeners();
  //     return _groupAttendanceTrends ?? {};
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //     return {};
  //   }
  // }

  // SECTION: Attendance Analytics

  /// Fetch weekly attendance statistics
  Future<AttendanceData> fetchWeeklyAttendance() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getAttendanceByWeek();
      final result = AttendanceData.fromJson(response);
      _weeklyAttendance = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching weekly attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch monthly attendance statistics
  Future<AttendanceData> fetchMonthlyAttendance() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getAttendanceByMonth();
      final result = AttendanceData.fromJson(response);
      _monthlyAttendance = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching monthly attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch yearly attendance statistics
  Future<AttendanceData> fetchYearlyAttendance() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getAttendanceByYear();
      final result = AttendanceData.fromJson(response);
      _yearlyAttendance = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching yearly attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch attendance statistics for a specific period
  Future<AttendanceData> fetchPeriodAttendance(String period) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getAttendanceByPeriod(period);
      final result = AttendanceData.fromJson(response);
      _periodAttendance = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching period attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch overall attendance statistics
  Future<OverallAttendanceData> fetchOverallAttendance(String period) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getOverallAttendanceByPeriod(period);
      final result = OverallAttendanceData.fromJson(response);
      _overallAttendance = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching overall attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user attendance trends
  Future<UserAttendanceTrends> fetchUserAttendanceTrends(String userId) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getUserAttendanceTrends(userId);
      final result = UserAttendanceTrends.fromJson(response);
      _userAttendanceTrends = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching user attendance trends', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Event Analytics

  /// Fetch event participation statistics
  Future<EventParticipationStats> fetchEventParticipationStats(String eventId) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getEventParticipationStats(
        eventId,
        startDate: _startDate,
        endDate: _endDate
      );
      final result = EventParticipationStats.fromJson(response);
      _eventParticipationStats = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching event participation stats', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Compare event attendance
  Future<EventAttendanceComparison> compareEventAttendance(List<String> eventIds) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.compareEventAttendance(eventIds);
      final result = EventAttendanceComparison.fromJson(response);
      _eventComparisonData = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('comparing event attendance', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Member Analytics

  /// Fetch member participation statistics
  Future<MemberParticipationStats> fetchMemberParticipationStats() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getMemberParticipationStats(
        startDate: _startDate,
        endDate: _endDate
      );
      final result = MemberParticipationStats.fromJson(response);
      _memberParticipationStats = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching member participation stats', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch member retention statistics
  Future<MemberRetentionStats> fetchMemberRetentionStats() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getMemberRetentionStats();
      final result = MemberRetentionStats.fromJson(response);
      _memberRetentionStats = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching member retention stats', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Dashboard Analytics

  /// Fetch dashboard summary
  Future<DashboardSummary> fetchDashboardSummary() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.getDashboardSummary();
      final result = DashboardSummary.fromJson(response);
      _dashboardSummary = result;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('fetching dashboard summary', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Custom Analytics

  /// Export attendance report
  Future<ReportData> exportAttendanceReport() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.exportAttendanceReport();
      final result = ReportData.fromJson(response);
      _customReportData = result;
      _exportUrl = result.downloadUrl;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('exporting attendance report', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Export member report
  Future<ReportData> exportMemberReport() async {
    _setLoading(true);
    try {
      final response = await _analyticsService.exportMemberReport();
      final result = ReportData.fromJson(response);
      _customReportData = result;
      _exportUrl = result.downloadUrl;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('exporting member report', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Export group report
  Future<ReportData> exportGroupReport(String groupId) async {
    _setLoading(true);
    try {
      final response = await _analyticsService.exportGroupReport(groupId);
      final result = ReportData.fromJson(response);
      _customReportData = result;
      _exportUrl = result.downloadUrl;
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (error) {
      _handleError('exporting group report', error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Local Analytics Processing

  /// Calculate attendance rate
  double calculateAttendanceRate(List<AttendanceModel> attendanceRecords) {
    if (attendanceRecords.isEmpty) return 0.0;
    
    // Simple calculation: number of attendances / total possible attendances
    int totalEvents = attendanceRecords.map((a) => a.eventId).toSet().length;
    if (totalEvents == 0) return 0.0;
    
    return attendanceRecords.length / totalEvents;
  }

  /// Calculate growth rate
  double calculateGrowthRate(int previousValue, int currentValue) {
    if (previousValue == 0) return currentValue > 0 ? 1.0 : 0.0;
    
    return (currentValue - previousValue) / previousValue;
  }

  /// Refresh all analytics data for a group
  Future<void> refreshAllGroupAnalytics(String groupId) async {
    _setLoading(true);
    try {
      // Create a list of futures to execute in parallel
      final futures = [
        fetchGroupDemographics(groupId),
        fetchGroupAttendanceStats(groupId),
        fetchGroupGrowthAnalytics(groupId),
        fetchGroupDashboardData(groupId),
      ];
      
      // Execute all futures in parallel
      await Future.wait(futures);
      
      _errorMessage = null;
    } catch (error) {
      _handleError('refreshing group analytics', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all attendance analytics
  Future<void> refreshAllAttendanceAnalytics() async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchWeeklyAttendance(),
        fetchMonthlyAttendance(),
        fetchYearlyAttendance(),
      ]);
      _errorMessage = null;
    } catch (error) {
      _handleError('refreshing attendance analytics', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh dashboard analytics
  Future<void> refreshDashboardAnalytics() async {
    _setLoading(true);
    try {
      await fetchDashboardSummary();
      _errorMessage = null;
    } catch (error) {
      _handleError('refreshing dashboard analytics', error);
    } finally {
      _setLoading(false);
    }
  }
  //
  // // Enhanced analytics methods
  // Future<void> fetchAttendanceByEventType(String eventType) async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getAttendanceByEventType(eventType);
  //     _attendanceByEventType = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchUpcomingEventsParticipationForecast() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getUpcomingEventsParticipationForecast();
  //     _upcomingEventsParticipationForecast = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchPopularEvents() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getPopularEvents();
  //     _popularEvents = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchAttendanceByEventCategory() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getAttendanceByEventCategory();
  //     _attendanceByEventCategory = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchMemberEngagementScores() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getMemberEngagementScores();
  //     _memberEngagementScores = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchMemberActivityLevels() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getMemberActivityLevels();
  //     _memberActivityLevels = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchAttendanceCorrelationFactors() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getAttendanceCorrelationFactors();
  //     _attendanceCorrelationFactors = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchDashboardTrends() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getDashboardTrends();
  //     _dashboardTrends = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchPerformanceMetrics() async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getPerformanceMetrics();
  //     _performanceMetrics = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }
  //
  // Future<void> fetchCustomDashboardData(String timeframe) async {
  //   _setLoading(true);
  //   try {
  //     final response = await _analyticsService.getCustomDashboardData(timeframe);
  //     _customDashboardData = _convertToMap(response);
  //     notifyListeners();
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Method to fetch all analytics data for a group
  Future<void> fetchAllGroupAnalytics(String groupId) async {
    _setLoading(true);
    try {
      // Create a list of futures to execute in parallel
      final futures = [
        fetchGroupDemographics(groupId),
        fetchGroupAttendanceStats(groupId),
        fetchGroupGrowthAnalytics(groupId),
        fetchGroupDashboardData(groupId),
        // fetchGroupEngagementMetrics(groupId),
        // fetchGroupAttendanceTrends(groupId),
        // fetchGroupActivityTimeline(groupId),
      ];
      
      // Execute all futures in parallel
      await Future.wait(futures);
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Method to fetch all dashboard data
  // Future<void> fetchAllDashboardData() async {
  //   _setLoading(true);
  //   try {
  //     await Future.wait([
  //       fetchDashboardSummary(),
  //       fetchDashboardTrends(),
  //       fetchPerformanceMetrics(),
  //       fetchPopularEvents(),
  //       fetchAttendanceByEventCategory(),
  //       fetchMemberEngagementScores(),
  //       fetchMemberActivityLevels(),
  //       fetchAttendanceCorrelationFactors(),
  //     ]);
  //     _errorMessage = null;
  //   } catch (e) {
  //     _errorMessage = e.toString();
  //     notifyListeners();
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Method to clear all analytics data
  void clearAnalyticsData() {
    _groupEngagementMetrics = null;
    _groupActivityTimeline = null;
    _groupAttendanceTrends = null;
    _attendanceByEventType = null;
    _upcomingEventsParticipationForecast = null;
    _popularEvents = null;
    _attendanceByEventCategory = null;
    _memberEngagementScores = null;
    _memberActivityLevels = null;
    _attendanceCorrelationFactors = null;
    _dashboardTrends = null;
    _performanceMetrics = null;
    _customDashboardData = null;
    notifyListeners();
  }

  // Add new method to handle event attendance
  Future<void> fetchEventAttendance(String eventId) async {
    _setLoading(true);
    try {
      final response = await _attendanceProvider.fetchEventAttendance(eventId);
      
      // Since response is a List<AttendanceModel>, convert it to a map structure
      _eventAttendance = {
        'items': response,
        'count': response.length,
        'hasData': response.isNotEmpty,
        'attendanceRate': response.isNotEmpty ? response.length / 100 : 0.0,
        'totalAttendees': response.length
      };
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching event attendance', error);
      _eventAttendance = {
        'error': error.toString(),
        'items': [],
        'count': 0,
        'hasData': false
      };
    } finally {
      _setLoading(false);
    }
  }
}