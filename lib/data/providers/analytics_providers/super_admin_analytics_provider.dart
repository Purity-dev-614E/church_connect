import 'package:flutter/foundation.dart';
import 'package:group_management_church_app/core/auth/auth_wrapper.dart';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';

// Only import the models we're actually using
import '../../models/super_analytics_model.dart';
import '../../services/analytics_services/super_admin_analytics_service.dart';

// Parameter classes
class MemberParticipationParams {
  final String? startDate;
  final String? endDate;

  MemberParticipationParams({this.startDate, this.endDate});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberParticipationParams &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

class SuperAdminAnalyticsProvider extends ChangeNotifier {
  final SuperAdminAnalyticsService _analyticsService;
  
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  
  // Group analytics data
  final Map<String, GroupDemographics> _groupDemographics = {};
  final Map<String, GroupAttendanceStats> _groupAttendanceStats = {};
  final Map<String, GroupGrowthAnalytics> _groupGrowthAnalytics = {};
  final Map<String, GroupComparison> _compareGroupsData = {};
  
  // Attendance analytics data
  final Map<String, AttendanceByPeriod> _attendanceByPeriod = {};
  final Map<String, OverallAttendanceByPeriod> _overallAttendanceByPeriod = {};
  final Map<String, Map<String, dynamic>> _userAttendanceTrends = {};
  
  // Event analytics data
  final Map<String, EventParticipationStats> _eventParticipationStats = {};
  final Map<String, EventAttendanceComparison> _compareEventAttendance = {};
  
  // Member analytics data
  Map<String, dynamic> _memberParticipationStats = {};
  MemberActivityStatus? _memberActivityStatus;
  
  // Dashboard data
  DashboardSummary? _dashboardSummary;
  final Map<String, GroupDashboardData> _groupDashboardData = {};
  Map<String, dynamic> _combinedDashboard = {};
  
  // Additional data for super admin
  final Map<String, dynamic> _attendanceTrends = {};
  final Map<String, dynamic> _groupGrowthTrends = {};
  final List<dynamic> _recentGroups = [];
  final List<dynamic> _recentUsers = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardSummary => _dashboardSummary?.toMap();
  MemberActivityStatus? get memberActivityStatus => _memberActivityStatus;
  Map<String, dynamic> get attendanceTrends => _attendanceTrends;
  Map<String, dynamic> get groupGrowthTrends => _groupGrowthTrends;
  List<dynamic> get recentGroups => _recentGroups;
  List<dynamic> get recentUsers => _recentUsers;
  final AuthServices _authServices = AuthServices();
  
  SuperAdminAnalyticsProvider({
    String baseUrl = ApiEndpoints.baseUrl,
  })
      : _analyticsService = SuperAdminAnalyticsService(
          baseUrl: ApiEndpoints.baseUrl,
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
  
  // Group Analytics Methods
  Future<GroupDemographics> getGroupDemographics(String groupId) async {
    _setLoading(true);
    try {
      final demographics = await _analyticsService.getGroupDemographics(groupId);
      _groupDemographics[groupId] = demographics;
      _errorMessage = null;
      _setLoading(false);
      return demographics;
    } catch (error) {
      _handleError('fetching group demographics', error);
      _setLoading(false);
      return GroupDemographics(
        genderDistribution: [],
        roleDistribution: [],
      );
    }
  }
  
  Future<GroupAttendanceStats> getGroupAttendanceStats(String groupId) async {
    _setLoading(true);
    try {
      final stats = await _analyticsService.getGroupAttendanceStats(groupId);
      _groupAttendanceStats[groupId] = stats;
      _errorMessage = null;
      _setLoading(false);
      return stats;
    } catch (error) {
      _handleError('fetching group attendance stats', error);
      _setLoading(false);
      return GroupAttendanceStats(
        eventStats: [],
        overallStats: OverallAttendanceStats(
          totalEvents: 0,
          totalMembers: 0,
          presentMembers: 0,
          attendanceRate: 0.0,
        ),
      );
    }
  }
  
  Future<GroupGrowthAnalytics> getGroupGrowthAnalytics(String groupId) async {
    _setLoading(true);
    try {
      final analytics = await _analyticsService.getGroupGrowthAnalytics(groupId);
      _groupGrowthAnalytics[groupId] = analytics;
      _errorMessage = null;
      _setLoading(false);
      return analytics;
    } catch (error) {
      _handleError('fetching group growth analytics', error);
      _setLoading(false);
      return GroupGrowthAnalytics(
        monthlyGrowth: {},
        cumulativeGrowth: [],
      );
    }
  }
  
  Future<GroupComparison> compareGroups(List<String> groupIds) async {
    _setLoading(true);
    try {
      final comparison = await _analyticsService.compareGroups(groupIds);
      final key = groupIds.join('-');
      _compareGroupsData[key] = comparison;
      _errorMessage = null;
      _setLoading(false);
      return comparison;
    } catch (error) {
      _handleError('comparing groups', error);
      _setLoading(false);
      return GroupComparison(
        memberCounts: [],
        attendanceRates: [],
      );
    }
  }
  
  // Attendance Analytics Methods
  Future<AttendanceByPeriod> getAttendanceByPeriod(String period) async {
    _setLoading(true);
    try {
      final attendance = await _analyticsService.getAttendanceByPeriod(period);
      _attendanceByPeriod[period] = attendance;
      _errorMessage = null;
      _setLoading(false);
      return attendance;
    } catch (error) {
      _handleError('fetching attendance by period', error);
      _setLoading(false);
      return AttendanceByPeriod(
        eventStats: [],
        dailyStats: [],
      );
    }
  }
  
  Future<OverallAttendanceByPeriod> getOverallAttendanceByPeriod(String period) async {
    _setLoading(true);
    try {
      final attendance = await _analyticsService.getOverallAttendanceByPeriod(period);
      _overallAttendanceByPeriod[period] = attendance;
      _errorMessage = null;
      _setLoading(false);
      return attendance;
    } catch (error) {
      _handleError('fetching overall attendance by period', error);
      _setLoading(false);
      return OverallAttendanceByPeriod(
        groupStats: [],
        overallStats: OverallAttendanceStat(
          eventCount: 0,
          totalPossible: 0,
          presentCount: 0,
          attendanceRate: 0.0,
        ),
      );
    }
  }
  
  // This method is missing in the service, so we'll implement a stub
  Future<Map<String, dynamic>> getUserAttendanceTrends(String userId) async {
    _setLoading(true);
    try {
      // Since this method is missing in the service, we'll return a placeholder
      // In a real implementation, you would add this method to the service
      final data = {
        'userId': userId,
        'attendanceRate': 0.0,
        'trends': [],
        'message': 'This is a placeholder. Method not implemented in service.',
      };
      _userAttendanceTrends[userId] = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching user attendance trends', error);
      _setLoading(false);
      return {};
    }
  }
  
  // Event Analytics Methods
  Future<EventParticipationStats> getEventParticipationStats(String eventId) async {
    _setLoading(true);
    try {
      final stats = await _analyticsService.getEventParticipationStats(eventId);
      _eventParticipationStats[eventId] = stats;
      _errorMessage = null;
      _setLoading(false);
      return stats;
    } catch (error) {
      _handleError('fetching event participation stats', error);
      _setLoading(false);
      return EventParticipationStats(
        eventId: eventId,
        eventTitle: '',
        eventDate: DateTime.now(),
        groupId: '',
        groupName: '',
        totalParticipants: 0,
        presentCount: 0,
        attendanceRate: 0.0,
        participants: [],
      );
    }
  }
  
  Future<EventAttendanceComparison> compareEventAttendance(List<String> eventIds) async {
    _setLoading(true);
    try {
      final comparison = await _analyticsService.compareEventAttendance(eventIds);
      final key = eventIds.join('-');
      _compareEventAttendance[key] = comparison;
      _errorMessage = null;
      _setLoading(false);
      return comparison;
    } catch (error) {
      _handleError('comparing event attendance', error);
      _setLoading(false);
      return EventAttendanceComparison(
        events: [],
      );
    }
  }
  
  // Member Analytics Methods
  // This method is missing in the service, so we'll implement a stub
  Future<Map<String, dynamic>> getMemberParticipationStats({
    String? startDate,
    String? endDate,
  }) async {
    _setLoading(true);
    try {
      // Since this method is missing in the service, we'll return a placeholder
      // In a real implementation, you would add this method to the service
      final data = {
        'startDate': startDate,
        'endDate': endDate,
        'participationRate': 0.0,
        'members': [],
        'message': 'This is a placeholder. Method not implemented in service.',
      };
      _memberParticipationStats = data;
      _errorMessage = null;
      _setLoading(false);
      return data;
    } catch (error) {
      _handleError('fetching member participation stats', error);
      _setLoading(false);
      return {};
    }
  }
  
  Future<MemberActivityStatus> getMemberActivityStatus() async {
    _setLoading(true);
    try {
      final status = await _analyticsService.getMemberActivityStatus();
      _memberActivityStatus = status;
      _errorMessage = null;
      _setLoading(false);
      return status;
    } catch (error) {
      _handleError('fetching member activity status', error);
      _setLoading(false);
      return MemberActivityStatus(
        members: [],
        counts: ActivityStatusCount(
          active: 0,
          inactive: 0,
          total: 0,
        ),
      );
    }
  }
  
  // Dashboard Analytics Methods
  Future<Map<String, dynamic>> getDashboardSummary() async {
    _setLoading(true);
    try {
      final summary = await _analyticsService.getDashboardSummary();
      _dashboardSummary = summary;
      _errorMessage = null;
      _setLoading(false);
      
      // Convert DashboardSummary to Map<String, dynamic>
      return summary.toMap();
    } catch (error) {
      _handleError('fetching dashboard summary', error);
      _setLoading(false);
      
      // Return a default Map<String, dynamic> instead of DashboardSummary
      return {
        'totalUsers': 0,
        'totalGroups': 0,
        'totalEvents': 0,
        'recentEvents': [],
        'upcomingEvents': [],
      };
    }
  }
  
  Future<GroupDashboardData> getGroupDashboardData(String groupId) async {
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
      return GroupDashboardData(
        groupId: groupId,
        groupName: '',
        createdAt: DateTime.now(),
        memberStats: GroupMemberStat(
          totalMembers: 0,
          activeMembers: 0,
          activeRate: 0.0,
        ),
        recentAttendance: [],
        upcomingEvents: [],
      );
    }
  }
  
  // Combined Dashboard Data
  Future<Map<String, dynamic>> getCombinedDashboard() async {
    _setLoading(true);
    try {
      // Get dashboard summary as Map<String, dynamic>
      final summary = await getDashboardSummary();
      
      // Combine the data
      final combinedData = {
        'summary': summary,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _combinedDashboard = combinedData;
      _errorMessage = null;
      _setLoading(false);
      return combinedData;
    } catch (error) {
      _handleError('fetching combined dashboard', error);
      _setLoading(false);
      return {};
    }
  }
}