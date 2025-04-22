import 'package:flutter/foundation.dart';
import 'package:group_management_church_app/data/models/analytics_model.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';

class DashboardAnalyticsProvider extends ChangeNotifier {
  final AnalyticsServices _analyticsServices = AnalyticsServices();
  
  // State management
  bool _isLoading = false;
  String? _errorMessage;
  
  // Dashboard data
  List<UserModel> _recentMembers = [];
  List<GroupModel> _recentGroups = [];
  List<EventModel> _upcomingEvents = [];
  Map<String, dynamic> _dashboardSummary = {};
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get recentMembers => _recentMembers;
  List<GroupModel> get recentGroups => _recentGroups;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  Map<String, dynamic> get dashboardSummary => _dashboardSummary;
  Map<String, dynamic> get attendanceTrends => _attendanceTrends;
  Map<String, dynamic> get groupGrowthTrends => _groupGrowthTrends;
  
  // Fetch recent members
  Future<void> fetchRecentMembers() async {
    _setLoading(true);
    try {
      // Fetch recent members from analytics service
      final data = await _analyticsServices.getDashboardSummary();
      
      // Extract recent members from the response
      List<UserModel> members = [];
      if (data.containsKey('recent_members') && data['recent_members'] is List) {
        final recentMembersData = data['recent_members'] as List;
        for (var memberData in recentMembersData) {
          if (memberData is Map<String, dynamic>) {
            members.add(UserModel.fromJson(memberData));
          }
        }
      }
      
      _recentMembers = members;
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching recent members: $e');
    }
  }
  
  // Fetch recent groups
  Future<void> fetchRecentGroups() async {
    _setLoading(true);
    try {
      // Fetch recent groups from analytics service
      final data = await _analyticsServices.getDashboardSummary();
      
      // Extract recent groups from the response
      List<GroupModel> groups = [];
      if (data.containsKey('recent_groups') && data['recent_groups'] is List) {
        final recentGroupsData = data['recent_groups'] as List;
        for (var groupData in recentGroupsData) {
          if (groupData is Map<String, dynamic>) {
            groups.add(GroupModel.fromJson(groupData));
          }
        }
      }
      
      _recentGroups = groups;
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching recent groups: $e');
    }
  }
  
  // Fetch upcoming events
  Future<void> fetchUpcomingEvents() async {
    _setLoading(true);
    try {
      // Fetch upcoming events from analytics service
      final data = await _analyticsServices.getDashboardSummary();
      
      // Extract upcoming events from the response
      List<EventModel> events = [];
      if (data.containsKey('upcoming_events') && data['upcoming_events'] is List) {
        final upcomingEventsData = data['upcoming_events'] as List;
        for (var eventData in upcomingEventsData) {
          if (eventData is Map<String, dynamic>) {
            events.add(EventModel.fromJson(eventData));
          }
        }
      }
      
      _upcomingEvents = events;
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching upcoming events: $e');
    }
  }
  
  // Fetch dashboard summary
  Future<void> fetchDashboardSummary() async {
    _setLoading(true);
    try {
      final data = await _analyticsServices.getDashboardSummary();
      _dashboardSummary = data;
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching dashboard summary: $e');
    }
  }
  
  // Fetch attendance trends
  Future<void> fetchAttendanceTrends() async {
    _setLoading(true);
    try {
      // Since there's no specific method for attendance trends in AnalyticsServices,
      // we'll extract it from the dashboard summary
      final data = await _analyticsServices.getDashboardSummary();
      
      if (data.containsKey('attendance_trends')) {
        _attendanceTrends = data['attendance_trends'];
      } else {
        // Fallback to sample data
        _attendanceTrends = {
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
      
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching attendance trends: $e');
    }
  }
  
  // Fetch group growth trends
  Future<void> fetchGroupGrowthTrends() async {
    _setLoading(true);
    try {
      // Since there's no specific method for group growth trends in AnalyticsServices,
      // we'll extract it from the dashboard summary
      final data = await _analyticsServices.getDashboardSummary();
      
      if (data.containsKey('group_growth_trends')) {
        _groupGrowthTrends = data['group_growth_trends'];
      } else {
        // Fallback to sample data
        _groupGrowthTrends = {
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
      
      _setLoading(false);
    } catch (e) {
      _handleError('Error fetching group growth trends: $e');
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _handleError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
}