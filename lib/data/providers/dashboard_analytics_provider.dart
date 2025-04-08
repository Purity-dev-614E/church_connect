import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';
import 'package:group_management_church_app/data/services/event_services.dart';
import 'package:group_management_church_app/data/services/group_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';

/// A specialized provider for dashboard analytics that combines data from multiple services
class DashboardAnalyticsProvider extends ChangeNotifier {
  // Services
  final AnalyticsServices _analyticsServices = AnalyticsServices();
  final GroupServices _groupServices = GroupServices();
  final EventServices _eventServices = EventServices();
  final UserServices _userServices = UserServices();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  
  // Dashboard data
  Map<String, dynamic> _dashboardSummary = {};
  Map<String, dynamic> _groupDashboardData = {};
  List<GroupModel> _recentGroups = [];
  List<EventModel> _upcomingEvents = [];
  List<UserModel> _recentMembers = [];
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get dashboardSummary => _dashboardSummary;
  Map<String, dynamic> get groupDashboardData => _groupDashboardData;
  List<GroupModel> get recentGroups => _recentGroups;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<UserModel> get recentMembers => _recentMembers;
  Map<String, dynamic> get attendanceTrends => _attendanceTrends;
  Map<String, dynamic> get groupGrowthTrends => _groupGrowthTrends;
  
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
  
  // SECTION: Dashboard Data Fetching
  
  /// Fetch the main dashboard summary
  Future<void> fetchDashboardSummary() async {
    _setLoading(true);
    try {
      _dashboardSummary = await _analyticsServices.getDashboardSummary();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching dashboard summary', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch dashboard data for a specific group
  Future<void> fetchGroupDashboardData(String groupId) async {
    _setLoading(true);
    try {
      _groupDashboardData = await _analyticsServices.getGroupDashboardData(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group dashboard data', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch recent groups (last 5 created)
  Future<void> fetchRecentGroups() async {
    _setLoading(true);
    try {
      final allGroups = await _groupServices.fetchAllGroups();
      // Sort by most recently created (assuming id or some timestamp field)
      allGroups.sort((a, b) => b.id.compareTo(a.id));
      _recentGroups = allGroups.take(5).toList();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching recent groups', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch upcoming events across all groups
  Future<void> fetchUpcomingEvents() async {
    _setLoading(true);
    try {
      final allGroups = await _groupServices.fetchAllGroups();
      List<EventModel> allUpcomingEvents = [];
      
      for (final group in allGroups) {
        final groupEvents = await _eventServices.getUpcomingEvents(group.id);
        allUpcomingEvents.addAll(groupEvents);
      }
      
      // Sort by date (closest first)
      allUpcomingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _upcomingEvents = allUpcomingEvents.take(5).toList();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching upcoming events', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch recently added members
  Future<void> fetchRecentMembers() async {
    _setLoading(true);
    try {
      final allMembers = await _userServices.fetchAllUsers();
      // Sort by most recently added (assuming id or some timestamp field)
      allMembers.sort((a, b) => b.id.compareTo(a.id));
      _recentMembers = allMembers.take(5).toList();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching recent members', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch attendance trends for dashboard display
  Future<void> fetchAttendanceTrends() async {
    _setLoading(true);
    try {
      // Get monthly attendance data
      final monthlyData = await _analyticsServices.getAttendanceByMonth();
      _attendanceTrends = monthlyData;
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching attendance trends', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch group growth trends for dashboard display
  Future<void> fetchGroupGrowthTrends() async {
    _setLoading(true);
    try {
      // This is a placeholder - you might need to implement this endpoint
      // or calculate it from other data
      final allGroups = await _groupServices.fetchAllGroups();
      
      // For now, we'll create a simple structure with group counts
      _groupGrowthTrends = {
        'total_groups': allGroups.length,
        'active_groups': allGroups.length, // Assuming all are active
        'trend_data': [
          // This would normally come from the backend with historical data
          {'period': '2023-01', 'count': allGroups.length - 5},
          {'period': '2023-02', 'count': allGroups.length - 4},
          {'period': '2023-03', 'count': allGroups.length - 3},
          {'period': '2023-04', 'count': allGroups.length - 2},
          {'period': '2023-05', 'count': allGroups.length - 1},
          {'period': '2023-06', 'count': allGroups.length},
        ]
      };
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group growth trends', error);
    } finally {
      _setLoading(false);
    }
  }
  
  // SECTION: Combined Dashboard Data
  
  /// Fetch all dashboard data at once
  Future<void> fetchAllDashboardData() async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchDashboardSummary(),
        fetchRecentGroups(),
        fetchUpcomingEvents(),
        fetchRecentMembers(),
        fetchAttendanceTrends(),
        fetchGroupGrowthTrends(),
      ]);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching all dashboard data', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Fetch all data for a specific group's dashboard
  Future<void> fetchAllGroupDashboardData(String groupId) async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchGroupDashboardData(groupId),
        fetchUpcomingEvents(), // This could be filtered for the group
        fetchAttendanceTrends(), // This could be filtered for the group
      ]);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching all group dashboard data', error);
    } finally {
      _setLoading(false);
    }
  }
  
  // SECTION: Analytics Calculations
  
  /// Calculate attendance rate for dashboard display
  double calculateOverallAttendanceRate() {
    try {
      // This would normally use data from the backend
      // For now, we'll return a placeholder or calculate from available data
      if (_dashboardSummary.containsKey('overall_attendance_rate')) {
        return _dashboardSummary['overall_attendance_rate'] ?? 0.0;
      }
      return 0.0;
    } catch (error) {
      _handleError('calculating overall attendance rate', error);
      return 0.0;
    }
  }
  
  /// Calculate group growth rate for dashboard display
  double calculateGroupGrowthRate() {
    try {
      // This would normally use data from the backend
      // For now, we'll return a placeholder or calculate from available data
      if (_dashboardSummary.containsKey('group_growth_rate')) {
        return _dashboardSummary['group_growth_rate'] ?? 0.0;
      }
      
      // Or calculate from trend data if available
      if (_groupGrowthTrends.containsKey('trend_data')) {
        final trendData = _groupGrowthTrends['trend_data'] as List;
        if (trendData.length >= 2) {
          final currentValue = trendData.last['count'] as int;
          final previousValue = trendData[trendData.length - 2]['count'] as int;
          return _analyticsServices.calculateGrowthRate(previousValue, currentValue);
        }
      }
      
      return 0.0;
    } catch (error) {
      _handleError('calculating group growth rate', error);
      return 0.0;
    }
  }
  
  /// Calculate member growth rate for dashboard display
  double calculateMemberGrowthRate() {
    try {
      // This would normally use data from the backend
      // For now, we'll return a placeholder or calculate from available data
      if (_dashboardSummary.containsKey('member_growth_rate')) {
        return _dashboardSummary['member_growth_rate'] ?? 0.0;
      }
      return 0.0;
    } catch (error) {
      _handleError('calculating member growth rate', error);
      return 0.0;
    }
  }
}