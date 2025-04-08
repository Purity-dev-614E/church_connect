import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';

class AnalyticsProvider extends ChangeNotifier {
  // Private fields
  final AnalyticsServices _analyticsServices = AnalyticsServices();
  bool _isLoading = false;
  String? _errorMessage;

  // Group analytics data
  Map<String, dynamic> _groupDemographics = {};
  Map<String, dynamic> _groupAttendanceStats = {};
  Map<String, dynamic> _groupGrowthAnalytics = {};
  Map<String, dynamic> _groupComparisonData = {};
  Map<String, dynamic> _groupDashboardData = {};

  // Attendance analytics data
  Map<String, dynamic> _weeklyAttendance = {};
  Map<String, dynamic> _monthlyAttendance = {};
  Map<String, dynamic> _yearlyAttendance = {};
  Map<String, dynamic> _periodAttendance = {};
  Map<String, dynamic> _overallAttendance = {};
  Map<String, dynamic> _userAttendanceTrends = {};

  // Event analytics data
  Map<String, dynamic> _eventParticipationStats = {};
  Map<String, dynamic> _eventComparisonData = {};

  // Member analytics data
  Map<String, dynamic> _memberParticipationStats = {};
  Map<String, dynamic> _memberRetentionStats = {};

  // Dashboard data
  Map<String, dynamic> _dashboardSummary = {};

  // Custom report data
  Map<String, dynamic> _customReportData = {};
  String _exportUrl = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Group analytics getters
  Map<String, dynamic> get groupDemographics => _groupDemographics;
  Map<String, dynamic> get groupAttendanceStats => _groupAttendanceStats;
  Map<String, dynamic> get groupGrowthAnalytics => _groupGrowthAnalytics;
  Map<String, dynamic> get groupComparisonData => _groupComparisonData;
  Map<String, dynamic> get groupDashboardData => _groupDashboardData;

  // Attendance analytics getters
  Map<String, dynamic> get weeklyAttendance => _weeklyAttendance;
  Map<String, dynamic> get monthlyAttendance => _monthlyAttendance;
  Map<String, dynamic> get yearlyAttendance => _yearlyAttendance;
  Map<String, dynamic> get periodAttendance => _periodAttendance;
  Map<String, dynamic> get overallAttendance => _overallAttendance;
  Map<String, dynamic> get userAttendanceTrends => _userAttendanceTrends;

  // Event analytics getters
  Map<String, dynamic> get eventParticipationStats => _eventParticipationStats;
  Map<String, dynamic> get eventComparisonData => _eventComparisonData;

  // Member analytics getters
  Map<String, dynamic> get memberParticipationStats => _memberParticipationStats;
  Map<String, dynamic> get memberRetentionStats => _memberRetentionStats;

  // Dashboard getters
  Map<String, dynamic> get dashboardSummary => _dashboardSummary;

  // Custom report getters
  Map<String, dynamic> get customReportData => _customReportData;
  String get exportUrl => _exportUrl;

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

  // SECTION: Group Analytics

  /// Fetch demographic information for a specific group
  Future<void> fetchGroupDemographics(String groupId) async {
    _setLoading(true);
    try {
      _groupDemographics = await _analyticsServices.getGroupDemographics(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group demographics', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch attendance statistics for a specific group
  Future<void> fetchGroupAttendanceStats(String groupId) async {
    _setLoading(true);
    try {
      _groupAttendanceStats = await _analyticsServices.getGroupAttendanceStats(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group attendance statistics', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch group growth analytics
  Future<void> fetchGroupGrowthAnalytics(String groupId) async {
    _setLoading(true);
    try {
      _groupGrowthAnalytics = await _analyticsServices.getGroupGrowthAnalytics(groupId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching group growth analytics', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Compare multiple groups
  Future<void> compareGroups(List<String> groupIds) async {
    _setLoading(true);
    try {
      _groupComparisonData = await _analyticsServices.compareGroups(groupIds);
      _errorMessage = null;
    } catch (error) {
      _handleError('comparing groups', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch group dashboard data
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

  // SECTION: Attendance Analytics

  /// Fetch weekly attendance statistics
  Future<void> fetchWeeklyAttendance() async {
    _setLoading(true);
    try {
      _weeklyAttendance = await _analyticsServices.getAttendanceByWeek();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching weekly attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch monthly attendance statistics
  Future<void> fetchMonthlyAttendance() async {
    _setLoading(true);
    try {
      _monthlyAttendance = await _analyticsServices.getAttendanceByMonth();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching monthly attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch yearly attendance statistics
  Future<void> fetchYearlyAttendance() async {
    _setLoading(true);
    try {
      _yearlyAttendance = await _analyticsServices.getAttendanceByYear();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching yearly attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch attendance statistics for a specific period
  Future<void> fetchPeriodAttendance(String period) async {
    _setLoading(true);
    try {
      _periodAttendance = await _analyticsServices.getAttendanceByPeriod(period);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching period attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch overall attendance statistics
  Future<void> fetchOverallAttendance(String period) async {
    _setLoading(true);
    try {
      _overallAttendance = await _analyticsServices.getOverallAttendanceByPeriod(period);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching overall attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user attendance trends
  Future<void> fetchUserAttendanceTrends(String userId) async {
    _setLoading(true);
    try {
      _userAttendanceTrends = await _analyticsServices.getUserAttendanceTrends(userId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching user attendance trends', error);
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Event Analytics

  /// Fetch event participation statistics
  Future<void> fetchEventParticipationStats(String eventId) async {
    _setLoading(true);
    try {
      _eventParticipationStats = await _analyticsServices.getEventParticipationStats(eventId);
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching event participation stats', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Compare event attendance
  Future<void> compareEventAttendance(List<String> eventIds) async {
    _setLoading(true);
    try {
      _eventComparisonData = await _analyticsServices.compareEventAttendance(eventIds);
      _errorMessage = null;
    } catch (error) {
      _handleError('comparing event attendance', error);
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Member Analytics

  /// Fetch member participation statistics
  Future<void> fetchMemberParticipationStats() async {
    _setLoading(true);
    try {
      _memberParticipationStats = await _analyticsServices.getMemberParticipationStats();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching member participation stats', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch member retention statistics
  Future<void> fetchMemberRetentionStats() async {
    _setLoading(true);
    try {
      _memberRetentionStats = await _analyticsServices.getMemberRetentionStats();
      _errorMessage = null;
    } catch (error) {
      _handleError('fetching member retention stats', error);
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Dashboard Analytics

  /// Fetch dashboard summary
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

  // SECTION: Custom Analytics

  /// Generate custom report
  Future<void> generateCustomReport({
    required String reportType,
    required Map<String, dynamic> parameters,
  }) async {
    _setLoading(true);
    try {
      _customReportData = await _analyticsServices.generateCustomReport(
        reportType: reportType,
        parameters: parameters,
      );
      _errorMessage = null;
    } catch (error) {
      _handleError('generating custom report', error);
    } finally {
      _setLoading(false);
    }
  }

  /// Export analytics data
  Future<void> exportAnalyticsData({
    required String dataType,
    required String format,
    required Map<String, dynamic> parameters,
  }) async {
    _setLoading(true);
    try {
      _exportUrl = await _analyticsServices.exportAnalyticsData(
        dataType: dataType,
        format: format,
        parameters: parameters,
      );
      _errorMessage = null;
    } catch (error) {
      _handleError('exporting analytics data', error);
    } finally {
      _setLoading(false);
    }
  }

  // SECTION: Local Analytics Processing

  /// Calculate attendance rate
  double calculateAttendanceRate(List<AttendanceModel> attendanceRecords) {
    return _analyticsServices.calculateAttendanceRate(attendanceRecords);
  }

  /// Calculate growth rate
  double calculateGrowthRate(int previousValue, int currentValue) {
    return _analyticsServices.calculateGrowthRate(previousValue, currentValue);
  }

  /// Generate attendance trend data
  Map<String, dynamic> generateAttendanceTrendData(
    List<AttendanceModel> attendanceRecords,
    List<EventModel> events
  ) {
    return _analyticsServices.generateAttendanceTrendData(attendanceRecords, events);
  }

  /// Refresh all analytics data for a group
  Future<void> refreshAllGroupAnalytics(String groupId) async {
    _setLoading(true);
    try {
      await Future.wait([
        fetchGroupDemographics(groupId),
        fetchGroupAttendanceStats(groupId),
        fetchGroupGrowthAnalytics(groupId),
        fetchGroupDashboardData(groupId),
      ]);
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
}