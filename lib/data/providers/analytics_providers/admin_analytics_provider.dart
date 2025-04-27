import 'package:flutter/foundation.dart';

import '../../services/analytics_services/admin_analytics_service.dart';

// Parameter classes
class GroupPeriodParams {
  final String groupId;
  final String period;

  GroupPeriodParams({
    required this.groupId,
    required this.period,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupPeriodParams &&
        other.groupId == groupId &&
        other.period == period;
  }

  @override
  int get hashCode => groupId.hashCode ^ period.hashCode;
}

class GroupMemberParticipationParams {
  final String groupId;
  final String? startDate;
  final String? endDate;

  GroupMemberParticipationParams({
    required this.groupId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMemberParticipationParams &&
        other.groupId == groupId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => groupId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

class AdminAnalyticsProvider extends ChangeNotifier {
  final AdminAnalyticsService _analyticsService;
  
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  
  // Date range for analytics
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Group analytics data
  final Map<String, Map<String, dynamic>> _groupDemographics = {};
  final Map<String, Map<String, dynamic>> _groupAttendanceStats = {};
  final Map<String, Map<String, dynamic>> _groupGrowthAnalytics = {};
  final Map<String, Map<String, dynamic>> _groupAttendanceByPeriod = {};
  
  // Event analytics data
  final Map<String, Map<String, dynamic>> _eventParticipationStats = {};
  
  // Member analytics data
  final Map<String, Map<String, dynamic>> _groupMemberParticipationStats = {};
  final Map<String, Map<String, dynamic>> _groupMemberActivityStatus = {};
  
  // Dashboard data
  final Map<String, Map<String, dynamic>> _groupDashboardData = {};
  final Map<String, Map<String, dynamic>> _combinedDashboardData = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  AdminAnalyticsProvider({String baseUrl = 'YOUR_API_BASE_URL', String token = 'YOUR_AUTH_TOKEN'}) 
      : _analyticsService = AdminAnalyticsService(
          baseUrl: baseUrl,
          token: token,
        );
  
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
  
  // Date Range Methods
  void setDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }
  
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  
  // Group Analytics Methods
  Future<Map<String, dynamic>> getGroupDemographics(String groupId) async {
    _setLoading(true);
    try {
      // Use class-level date range if set
      String? startDateStr;
      String? endDateStr;
      
      if (_startDate != null) {
        startDateStr = _startDate!.toIso8601String();
      }
      
      if (_endDate != null) {
        endDateStr = _endDate!.toIso8601String();
      }
      
      final data = await _analyticsService.getGroupDemographics(
        groupId,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      final key = _startDate != null && _endDate != null 
          ? '$groupId-${_startDate!.toIso8601String()}-${_endDate!.toIso8601String()}'
          : groupId;
          
      _groupDemographics[key] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group demographics', error);
      _setLoading(false);
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getGroupAttendanceStats(String groupId) async {
    _setLoading(true);
    try {
      // Use class-level date range if set
      String? startDateStr;
      String? endDateStr;
      
      if (_startDate != null) {
        startDateStr = _startDate!.toIso8601String();
      }
      
      if (_endDate != null) {
        endDateStr = _endDate!.toIso8601String();
      }
      
      final data = await _analyticsService.getGroupAttendanceStats(
        groupId,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      final key = _startDate != null && _endDate != null 
          ? '$groupId-${_startDate!.toIso8601String()}-${_endDate!.toIso8601String()}'
          : groupId;
          
      _groupAttendanceStats[key] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group attendance stats', error);
      _setLoading(false);
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getGroupGrowthAnalytics(String groupId) async {
    _setLoading(true);
    try {
      final data = await _analyticsService.getGroupGrowthAnalytics(groupId);
      _groupGrowthAnalytics[groupId] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group growth analytics', error);
      _setLoading(false);
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getGroupAttendanceByPeriod(String groupId, String period) async {
    _setLoading(true);
    try {
      final data = await _analyticsService.getGroupAttendanceByPeriod(groupId, period);
      final key = '$groupId-$period';
      _groupAttendanceByPeriod[key] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group attendance by period', error);
      _setLoading(false);
      return {};
    }
  }
  
  // Event Analytics Methods
  Future<Map<String, dynamic>> getEventParticipationStats(String eventId) async {
    _setLoading(true);
    try {
      // Use class-level date range if set
      String? startDateStr;
      String? endDateStr;
      
      if (_startDate != null) {
        startDateStr = _startDate!.toIso8601String();
      }
      
      if (_endDate != null) {
        endDateStr = _endDate!.toIso8601String();
      }
      
      final data = await _analyticsService.getEventParticipationStats(
        eventId,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      final key = _startDate != null && _endDate != null 
          ? '$eventId-${_startDate!.toIso8601String()}-${_endDate!.toIso8601String()}'
          : eventId;
          
      _eventParticipationStats[key] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching event participation stats', error);
      _setLoading(false);
      return {};
    }
  }



  // Member Analytics Methods
  Future<Map<String, dynamic>> getGroupMemberParticipationStats(
    String groupId, {
    String? startDate,
    String? endDate,
  }) async {
    _setLoading(true);
    try {
      // Use provided dates or fall back to the class-level date range if set
      String? effectiveStartDate = startDate;
      String? effectiveEndDate = endDate;
      
      if (effectiveStartDate == null && _startDate != null) {
        effectiveStartDate = _startDate!.toIso8601String();
      }
      
      if (effectiveEndDate == null && _endDate != null) {
        effectiveEndDate = _endDate!.toIso8601String();
      }
      
      final data = await _analyticsService.getGroupMemberParticipationStats(
        groupId,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );
      final key = '$groupId-${effectiveStartDate ?? ''}-${effectiveEndDate ?? ''}';
      _groupMemberParticipationStats[key] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group member participation stats', error);
      _setLoading(false);
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getGroupMemberActivityStatus(String groupId) async {
    _setLoading(true);
    try {
      final data = await _analyticsService.getGroupMemberActivityStatus(groupId);
      _groupMemberActivityStatus[groupId] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group member activity status', error);
      _setLoading(false);
      return {};
    }
  }
  
  // Dashboard Analytics Methods
  Future<Map<String, dynamic>> getGroupDashboardData(String groupId) async {
    _setLoading(true);
    try {
      final data = await _analyticsService.getGroupDashboardData(groupId);
      _groupDashboardData[groupId] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group dashboard data', error);
      _setLoading(false);
      return {};
    }
  }
  
  // Combined Dashboard Data
  Future<Map<String, dynamic>> getCombinedGroupDashboard(String groupId) async {
    _setLoading(true);
    try {
      // Get dashboard data
      final dashboardData = await getGroupDashboardData(groupId);
      
      // Get member activity status
      final memberActivity = await getGroupMemberActivityStatus(groupId);
      
      // Combine the data
      final combinedData = {
        'dashboardData': dashboardData,
        'memberActivity': memberActivity,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _combinedDashboardData[groupId] = combinedData;
      _errorMessage = null;
      _setLoading(false);
      return combinedData;
    } catch (error) {
      _handleError('fetching combined group dashboard', error);
      _setLoading(false);
      return {};
    }
  }
}