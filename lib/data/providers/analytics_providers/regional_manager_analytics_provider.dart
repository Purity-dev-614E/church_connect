import 'package:flutter/foundation.dart';
import 'package:group_management_church_app/data/services/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../models/regional_analytics_model.dart';
import '../../services/analytics_services/regional_manager_analytics_service.dart';

// Parameter classes
class RegionPeriodParams {
  final String regionId;
  final String period;

  RegionPeriodParams({
    required this.regionId,
    required this.period,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegionPeriodParams &&
        other.regionId == regionId &&
        other.period == period;
  }

  @override
  int get hashCode => regionId.hashCode ^ period.hashCode;
}

class GroupComparisonParams {
  final List<String> groupIds;
  final String regionId;

  GroupComparisonParams({
    required this.groupIds,
    required this.regionId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupComparisonParams &&
        listEquals(other.groupIds, groupIds) &&
        other.regionId == regionId;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(groupIds), regionId);
}

class EventComparisonParams {
  final List<String> eventIds;
  final String regionId;

  EventComparisonParams({
    required this.eventIds,
    required this.regionId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventComparisonParams &&
        listEquals(other.eventIds, eventIds) &&
        other.regionId == regionId;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(eventIds), regionId);
}

class UserAttendanceParams {
  final String userId;
  final String regionId;

  UserAttendanceParams({
    required this.userId,
    required this.regionId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAttendanceParams &&
        other.userId == userId &&
        other.regionId == regionId;
  }

  @override
  int get hashCode => userId.hashCode ^ regionId.hashCode;
}

class RegionalManagerAnalyticsProvider extends ChangeNotifier {
  final RegionAnalyticsService _analyticsService;
  
  // State variables
  bool _isLoading = false;
  String? _error;
  
  // Group-specific analytics for region
  final Map<String, GroupDemographics> _groupDemographics = {};
  final Map<String, GroupAttendanceStats> _groupAttendanceStats = {};
  final Map<String, GroupGrowthAnalytics> _groupGrowthAnalytics = {};
  final Map<String, GroupComparisonResult> _groupComparisons = {};
  final Map<String, EventParticipationStats> _eventParticipationStats = {};
  final Map<String, List<EventAttendanceComparison>> _eventAttendanceComparisons = {};
  final Map<String, UserAttendanceTrends> _userAttendanceTrends = {};
  final Map<String, AttendanceByPeriod> _attendanceByPeriod = {};
  final Map<String, GroupDashboardData> _groupDashboardData = {};
  
  // Region-specific analytics
  final Map<String, RegionDemographics> _regionDemographics = {};
  final Map<String, RegionAttendanceStats> _regionAttendanceStats = {};
  final Map<String, RegionGrowthAnalytics> _regionGrowthAnalytics = {};
  final Map<String, AttendanceByPeriodStats> _attendanceByPeriodStats = {};
  final Map<String, DashboardSummary> _dashboardSummary = {};
  final Map<String, MemberActivityStatus> _memberActivityStatus = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  RegionalManagerAnalyticsProvider({http.Client? client}) 
      : _analyticsService = RegionAnalyticsService(
        baseUrl: 'https://safari-backend-production-bf65.up.railway.app/api'
          );
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _handleError(String operation, dynamic error) {
    _error = 'Error $operation: $error';
    debugPrint(_error!);
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Group-specific analytics methods for region
  Future<GroupDemographics> getGroupDemographicsForRegion(String groupId) async {
    _setLoading(true);
    try {
      if (_groupDemographics.containsKey(groupId)) {
        _setLoading(false);
        return _groupDemographics[groupId]!;
      }
      
      final data = await _analyticsService.getGroupDemographicsForRegion(groupId);
      _groupDemographics[groupId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group demographics for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<GroupAttendanceStats?> getGroupAttendanceStatsForRegion(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Fetching group attendance stats for group: $groupId');
      if (_groupAttendanceStats.containsKey(groupId)) {
        _setLoading(false);
        return _groupAttendanceStats[groupId]!;
      }
      
      final data = await _analyticsService.getGroupAttendanceStatsForRegion(groupId);
      _groupAttendanceStats[groupId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      print('Error in getGroupAttendanceStatsForRegion: $error');
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<GroupGrowthAnalytics> getGroupGrowthAnalyticsForRegion(String groupId) async {
    _setLoading(true);
    try {
      if (_groupGrowthAnalytics.containsKey(groupId)) {
        _setLoading(false);
        return _groupGrowthAnalytics[groupId]!;
      }
      
      final data = await _analyticsService.getGroupGrowthAnalyticsForRegion(groupId);
      _groupGrowthAnalytics[groupId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group growth analytics for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<GroupComparisonResult> compareGroupsInRegion(List<String> groupIds, String regionId) async {
    _setLoading(true);
    try {
      final key = '${regionId}_${groupIds.join('_')}';
      
      if (_groupComparisons.containsKey(key)) {
        _setLoading(false);
        return _groupComparisons[key]!;
      }
      
      final data = await _analyticsService.compareGroupsInRegion(groupIds, regionId);
      _groupComparisons[key] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('comparing groups in region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<EventParticipationStats> getEventParticipationStatsForRegion(String eventId) async {
    _setLoading(true);
    try {
      if (_eventParticipationStats.containsKey(eventId)) {
        _setLoading(false);
        return _eventParticipationStats[eventId]!;
      }
      
      final data = await _analyticsService.getEventParticipationStatsForRegion(eventId);
      _eventParticipationStats[eventId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching event participation stats for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<List<EventAttendanceComparison>> compareEventAttendanceInRegion(
      List<String> eventIds, String regionId) async {
    _setLoading(true);
    try {
      final key = '${regionId}_${eventIds.join('_')}';
      
      if (_eventAttendanceComparisons.containsKey(key)) {
        _setLoading(false);
        return _eventAttendanceComparisons[key]!;
      }
      
      final data = await _analyticsService.compareEventAttendanceInRegion(eventIds, regionId);
      _eventAttendanceComparisons[key] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('comparing event attendance in region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<UserAttendanceTrends> getUserAttendanceTrendsForRegion(String userId, String regionId) async {
    _setLoading(true);
    try {
      final key = '${regionId}_$userId';
      
      if (_userAttendanceTrends.containsKey(key)) {
        _setLoading(false);
        return _userAttendanceTrends[key]!;
      }
      
      final data = await _analyticsService.getUserAttendanceTrendsForRegion(userId, regionId);
      _userAttendanceTrends[key] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching user attendance trends for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<AttendanceByPeriod?> getOverallAttendanceByPeriodForRegion(
    String period,
    String regionId,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Fetching overall attendance for region: $regionId, period: $period');
      final key = '${regionId}_$period';
      
      if (_attendanceByPeriod.containsKey(key)) {
        _setLoading(false);
        return _attendanceByPeriod[key]!;
      }
      
      final data = await _analyticsService.getOverallAttendanceByPeriodForRegion(
        period,
        regionId,
      );
      _attendanceByPeriod[key] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (e) {
      print('Error in getOverallAttendanceByPeriodForRegion: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<GroupDashboardData> getGroupDashboardDataForRegion(String groupId) async {
    _setLoading(true);
    try {
      if (_groupDashboardData.containsKey(groupId)) {
        _setLoading(false);
        return _groupDashboardData[groupId]!;
      }
      
      final data = await _analyticsService.getGroupDashboardDataForRegion(groupId);
      _groupDashboardData[groupId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching group dashboard data for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  // Region-specific analytics methods
  Future<RegionDemographics> getRegionDemographics(String regionId) async {
    _setLoading(true);
    try {
      if (_regionDemographics.containsKey(regionId)) {
        _setLoading(false);
        return _regionDemographics[regionId]!;
      }
      
      final data = await _analyticsService.getRegionDemographics(regionId);
      _regionDemographics[regionId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching region demographics', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<RegionAttendanceStats> getRegionAttendanceStats(String regionId) async {
    _setLoading(true);
    try {
      if (_regionAttendanceStats.containsKey(regionId)) {
        _setLoading(false);
        return _regionAttendanceStats[regionId]!;
      }
      
      final data = await _analyticsService.getRegionAttendanceStats(regionId);
      _regionAttendanceStats[regionId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching region attendance stats', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<RegionGrowthAnalytics> getRegionGrowthAnalytics(String regionId) async {
    _setLoading(true);
    try {
      if (_regionGrowthAnalytics.containsKey(regionId)) {
        _setLoading(false);
        return _regionGrowthAnalytics[regionId]!;
      }
      
      final data = await _analyticsService.getRegionGrowthAnalytics(regionId);
      _regionGrowthAnalytics[regionId] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching region growth analytics', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<AttendanceByPeriodStats> getAttendanceByPeriodForRegion(String period, String regionId) async {
    _setLoading(true);
    try {
      final key = '${regionId}_$period';
      
      if (_attendanceByPeriodStats.containsKey(key)) {
        _setLoading(false);
        return _attendanceByPeriodStats[key]!;
      }
      
      final data = await _analyticsService.getAttendanceByPeriodForRegion(period, regionId);
      _attendanceByPeriodStats[key] = data;
      _error = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching attendance by period for region', error);
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<DashboardSummary?> getDashboardSummaryForRegion(String regionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Fetching dashboard summary for region: $regionId');
      final response = await _analyticsService.getDashboardSummaryForRegion(regionId);
      
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('Error in getDashboardSummaryForRegion: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  Future<MemberActivityStatus?> getActivityStatus(String regionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Fetching activity status for region: $regionId');
      if (_memberActivityStatus.containsKey(regionId)) {
        _setLoading(false);
        return _memberActivityStatus[regionId]!;
      }
      
      try {
        final data = await _analyticsService.getMemberActivityStatusForRegion(regionId);
        _memberActivityStatus[regionId] = data;
        _error = null;
        _setLoading(false);
        notifyListeners();
        return data;
      } catch (e) {
        print('Error fetching activity status, using default values: $e');
        // Return default values when API fails
        final defaultStatus = MemberActivityStatus(
          userStats: [],
          statusSummary: StatusSummary(
            active: 0,
            inactive: 0,
            total: 0,
          ),
        );
        _memberActivityStatus[regionId] = defaultStatus;
        _setLoading(false);
        notifyListeners();
        return defaultStatus;
      }
    } catch (e) {
      print('Error in getActivityStatus: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Helper methods for the frontend
  Future<Map<String, List<double>>> getRegionalAttendanceTrend(String regionId, String period) async {
    try {
      final regionGrowth = await getRegionGrowthAnalytics(regionId);
      final Map<String, List<double>> trends = {};
      
      // Convert monthly growth data to a format suitable for charts
      final List<double> growthData = [];
      regionGrowth.monthlyGrowth.forEach((month, count) {
        growthData.add(count.toDouble());
      });
      
      trends['Growth'] = growthData;
      return trends;
    } catch (error) {
      _handleError('getting regional attendance trend', error);
      return {};
    }
  }
  
  Future<Map<String, double>> getGroupAttendance(String regionId) async {
    try {
      final regionAttendance = await getRegionAttendanceStats(regionId);
      final Map<String, double> groupAttendance = {};
      
      // Extract group attendance data from event stats
      for (var eventStat in regionAttendance.eventStats) {
        groupAttendance[eventStat.eventTitle] = eventStat.attendanceRate;
      }
      
      return groupAttendance;
    } catch (error) {
      _handleError('getting group attendance', error);
      return {};
    }
  }
  
  Future<Map<String, List<double>>> getEventAttendanceTimeline(String regionId) async {
    try {
      final attendanceStats = await getAttendanceByPeriodForRegion('month', regionId);
      final Map<String, List<double>> eventTimeline = {};
      
      // Extract daily attendance data
      for (var dailyStat in attendanceStats.dailyStats) {
        eventTimeline[dailyStat.date] = [dailyStat.attendanceRate];
      }
      
      return eventTimeline;
    } catch (error) {
      _handleError('getting event attendance timeline', error);
      return {};
    }
  }
  
  Future<Map<String, Map<String, int>>> getRegionalDemographics(String regionId) async {
    try {
      final demographics = await getRegionDemographics(regionId);
      final Map<String, Map<String, int>> result = {};
      
      // Process gender distribution data
      for (var item in demographics.genderDistribution) {
        result[item.category] = {'Male': 0, 'Female': 0};
        
        if (item.category == 'Male') {
          result[item.category]?['Male'] = item.count;
        } else if (item.category == 'Female') {
          result[item.category]?['Female'] = item.count;
        }
      }
      
      return result;
    } catch (error) {
      _handleError('getting regional demographics', error);
      return {};
    }
  }
}