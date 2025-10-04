class ApiEndpoints {
  static const String baseUrl = 'https://safari-backend-fgl3.onrender.com/api';

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
  static String addGroupMember(String groupId, String userId) => '$groups/$groupId/members';
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
  static String getGroupAttendancePercentage(String groupId) => '$attendance/group/$groupId';

  // Analytics Endpoints
  // Base Analytics URLs
  static const String superAdminAnalytics = '$baseUrl/super-admin/analytics';
  static const String regionalManagerAnalytics = '$baseUrl/regional-manager/analytics';
  static const String adminAnalytics = '$baseUrl/admin/analytics';

// Super Admin Analytics Endpoints
// Group Analytics
  static String getSuperAdminGroupDemographics(String groupId) => '$superAdminAnalytics/groups/$groupId/demographics';
  static String getSuperAdminGroupAttendance(String groupId) => '$superAdminAnalytics/groups/$groupId/attendance';
  static String getSuperAdminGroupGrowth(String groupId) => '$superAdminAnalytics/groups/$groupId/growth';
  static const String compareSuperAdminGroups = '$superAdminAnalytics/groups/compare';

// Attendance Analytics
  static String getSuperAdminAttendanceByPeriod(String period) => '$superAdminAnalytics/attendance/period/$period';
  static String getSuperAdminOverallAttendanceByPeriod(String period) => '$superAdminAnalytics/attendance/overall/$period';
  static String getSuperAdminUserAttendanceTrends(String userId) => '$superAdminAnalytics/attendance/user/$userId';

// Event Analytics
  static String getSuperAdminEventParticipation(String eventId) => '$superAdminAnalytics/events/$eventId/participation';
  static const String compareSuperAdminEventAttendance = '$superAdminAnalytics/events/compare-attendance';

// Member Analytics
  static const String getSuperAdminMemberParticipation = '$superAdminAnalytics/members/participation';
  static const String getSuperAdminMemberActivityStatus = '$superAdminAnalytics/members/activity-status';

// Dashboard Analytics
  static const String getSuperAdminDashboardSummary = '$superAdminAnalytics/dashboard/summary';
  static String getSuperAdminGroupDashboardData(String groupId) => '$superAdminAnalytics/dashboard/group/$groupId';

// Regional Manager Analytics Endpoints
// Group Analytics
  static String getRegionalManagerGroupDemographics(String groupId) => '$regionalManagerAnalytics/groups/$groupId/demographics';
  static String getRegionalManagerGroupAttendance(String groupId) => '$regionalManagerAnalytics/groups/$groupId/attendance';
  static String getRegionalManagerGroupGrowth(String groupId) => '$regionalManagerAnalytics/groups/$groupId/growth';
  static const String compareRegionalManagerGroups = '$regionalManagerAnalytics/groups/compare';

// Attendance Analytics
  static String getRegionalManagerAttendanceByPeriod(String period) => '$regionalManagerAnalytics/attendance/period/$period';
  static String getRegionalManagerOverallAttendanceByPeriod(String period) => '$regionalManagerAnalytics/attendance/overall/$period';
  static String getRegionalManagerUserAttendanceTrends(String userId) => '$regionalManagerAnalytics/attendance/user/$userId';

// Event Analytics
  static String getRegionalManagerEventParticipation(String eventId) => '$regionalManagerAnalytics/events/$eventId/participation';
  static const String compareRegionalManagerEventAttendance = '$regionalManagerAnalytics/events/compare-attendance';

// Member Analytics
  static const String getRegionalManagerMemberParticipation = '$regionalManagerAnalytics/members/participation';
  static const String getRegionalManagerMemberActivityStatus = '$regionalManagerAnalytics/members/activity-status';

// Dashboard Analytics
  static const String getRegionalManagerDashboardSummary = '$regionalManagerAnalytics/dashboard/summary';
  static String getRegionalManagerGroupDashboardData(String groupId) => '$regionalManagerAnalytics/dashboard/group/$groupId';

// Admin (Group Admin) Analytics Endpoints
// Group Analytics
  static String getAdminGroupDemographics(String groupId) => '$adminAnalytics/groups/$groupId/demographics';
  static String getAdminGroupAttendance(String groupId) => '$adminAnalytics/groups/$groupId/attendance';
  static String getAdminGroupGrowth(String groupId) => '$adminAnalytics/groups/$groupId/growth';

// Attendance Analytics
  static String getAdminGroupAttendanceByPeriod(String groupId, String period) => '$adminAnalytics/groups/$groupId/attendance/period/$period';

// Event Analytics
  static String getAdminEventParticipation(String eventId) => '$adminAnalytics/events/$eventId/participation';

// Member Analytics
  static String getAdminGroupMemberParticipation(String groupId) => '$adminAnalytics/groups/$groupId/members/participation';
  static String getAdminGroupMemberActivityStatus(String groupId) => '$adminAnalytics/groups/$groupId/members/activity-status';

// Dashboard Analytics
  static String getAdminGroupDashboardData(String groupId) => '$adminAnalytics/groups/$groupId/dashboard';


}