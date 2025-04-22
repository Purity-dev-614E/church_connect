class ApiEndpoints {
  static const String baseUrl = 'https://safari-backend-production-bf65.up.railway.app/api';

  // Authentication Endpoints
  static const String auth = '$baseUrl/auth';
  static const String signup = '$auth/signup';
  static const String login = '$auth/login';
  static const String forgotPassword = '$auth/forgot-password';
  static const String refreshToken = '$auth/refresh-token';

  // User Endpoints
  static const String users = '$baseUrl/users';
  static const String searchUsers = '$users/search';
  static String getUserById(String id) => '$users/$id';
  static String getUserByEmail(String email) => '$users/$email';
  static String updateUser(String id) => '$users/$id';
  static String deleteUser(String id) => '$users/$id';
  static String uploadUserImage(String id) => '$users/$id/uploadimage';

  // Region Endpoints
  static const String regions = '$baseUrl/regions';
  static String getRegionById(String id) => '$regions/$id';
  static String updateRegion(String id) => '$regions/$id';
  static String deleteRegion(String id) => '$regions/$id';
  static String getRegionUsers(String regionId) => '$regions/$regionId/users';
  static String getRegionGroups(String regionId) => '$regions/$regionId/groups';
  static String getRegionAnalytics(String regionId) => '$regions/$regionId/analytics';

  // Group Endpoints
  static const String groups = '$baseUrl/groups';
  static String getGroupById(String id) => '$groups/$id';
  static const String getGroupByName = '$groups/name';
  static String updateGroup(String id) => '$groups/$id';
  static String deleteGroup(String id) => '$groups/$id';
  static String getGroupDemographics(String id) => '$groups/$id/groupDemographics';
  static String getGroupMembers(String id) => '$groups/$id/members';
  static String getmemberGroups(String userId) => '$groups/user/$userId';
  static String addGroupMember(String id, String groupId) => '$groups/$id/members';
  static String removeGroupMember(String groupId, String userId) => '$groups/$groupId/members/$userId';
  static String getGroupsByAdmin(String userId) => '$groups/admin/$userId/groups';
  static String assignAdmin = '$groups/assign-admin';
  static String getGroupAttendance(String id) => '$groups/$id/attendance';
  static String getOverallAttendanceByPeriod(String period) => '$groups/attendance/$period';
  static String getGroupsByRegion(String regionId) => '$groups/region/$regionId';

  // Event Endpoints
  static const String events = '$baseUrl/events';
  static String createGroupEvent(String groupId) => '$events/group/$groupId';
  static String getEventById(String id) => '$events/$id';
  static String updateEvent(String id) => '$events/$id';
  static String deleteEvent(String id) => '$events/$id';
  static String getEventsByGroup(String groupId) => '$events/group/$groupId';
  static String getEventsByRegion(String regionId) => '$events/region/$regionId';

  // Attendance Endpoints
  static const String attendance = '$baseUrl/attendance';
  static String createEventAttendance(String eventId) => '$attendance/event/$eventId';
  static String getAttendanceById(String id) => '$attendance/$id';
  static String updateAttendance(String id) => '$attendance/$id';
  static String deleteAttendance(String id) => '$attendance/$id';
  static const String getAttendanceByWeek = '$attendance/week';
  static const String getAttendanceByMonth = '$attendance/month';
  static const String getAttendanceByYear = '$attendance/year';
  static String getAttendedMembers(String eventId) => '$attendance/event/$eventId/attended-members';
  static const String getAttendanceStatus = '$attendance/status';
  static String getAttendanceByEvent(String eventId) => '$attendance/event/$eventId';
  static String getAttendanceByUser(String userId) => '$attendance/user/$userId';
  static String getAttendanceByPeriod(String period) => '$attendance/$period';
  static String getAttendanceByRegion(String regionId) => '$attendance/region/$regionId';

  // Analytics Endpoints
  static const String analytics = '$baseUrl/analytics';
  
  // Group Analytics
  static String getGroupEngagement(String groupId) => '$analytics/groups/$groupId/engagement';
  static String getGroupActivityTimeline(String groupId) => '$analytics/groups/$groupId/activity-timeline';
  static String getGroupAttendanceTrends(String groupId) => '$analytics/groups/$groupId/attendance-trends';
  static String getGroupGrowth(String groupId) => '$analytics/groups/$groupId/growth';
  static String compareGroups(List<String> groupIds) => '$analytics/groups/compare';
  
  // Region Analytics
  static String getRegionEngagement(String regionId) => '$analytics/regions/$regionId/engagement';
  static String getRegionGrowth(String regionId) => '$analytics/regions/$regionId/growth';
  static String getRegionAttendanceTrends(String regionId) => '$analytics/regions/$regionId/attendance-trends';
  static String compareRegions(List<String> regionIds) => '$analytics/regions/compare';
  
  // Event Analytics
  static String getAttendanceByEventType(String eventType) => '$analytics/events/type/$eventType';
  static const String getUpcomingEventsParticipationForecast = '$analytics/events/forecast';
  static const String getPopularEvents = '$analytics/events/popular';
  static const String getAttendanceByEventCategory = '$analytics/events/categories';
  static String compareEventAttendance(List<String> eventIds) => '$analytics/events/compare-attendance';
  
  // Member Analytics
  static const String getMemberEngagementScores = '$analytics/members/engagement';
  static const String getMemberActivityLevels = '$analytics/members/activity';
  static const String getMemberParticipationStats = '$analytics/members/participation';
  static const String getMemberRetentionStats = '$analytics/members/retention';
  
  // Dashboard Analytics
  static const String getDashboardSummary = '$analytics/dashboard/summary';
  static const String getDashboardTrends = '$analytics/dashboard/trends';
  static const String getPerformanceMetrics = '$analytics/dashboard/performance-metrics';
  static String getCustomDashboardData(String timeframe) => '$analytics/dashboard/custom/$timeframe';
  static String getRegionDashboardSummary(String regionId) => '$analytics/dashboard/region/$regionId/summary';
  
  // Correlation Analytics
  static const String getAttendanceCorrelationFactors = '$analytics/correlation/attendance-correlation';
  
  // Export Endpoints
  static const String exportAttendanceReport = '$analytics/export/attendance';
  static const String exportMemberReport = '$analytics/export/member-report';
  static String exportGroupReport(String groupId) => '$analytics/export/group-report/$groupId';
  static String exportCustomReport(String reportType) => '$analytics/export/custom/$reportType';
  static String exportRegionReport(String regionId) => '$analytics/export/region-report/$regionId';
  static const String exportAnalyticsData = '$analytics/export/analytics-data';
}