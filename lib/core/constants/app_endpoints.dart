import '../services/config_service.dart';

class ApiEndpoints {
  static ConfigService get _config => ConfigService.instance;

  // Production flag - now managed by ConfigService
  static bool get _isProduction => _config.currentEnvironment == 'production';

  static Future<String> get _apiUrl async {
    return await _config.getApiUrl();
  }

  static Future<String> get fullBaseUrl async =>
      _isProduction ? await _config.getApiUrl() : await _apiUrl;

  static Future<String> get baseUrl async => await fullBaseUrl;

  // Authentication Endpoints
  static Future<String> get auth async => '${await fullBaseUrl}/auth';
  static Future<String> get signup async => '${await auth}/signup';
  static Future<String> get login async => '${await auth}/login';
  static Future<String> get forgotPassword async =>
      '${await auth}/forgot-password';
  static Future<String> get refreshToken async => '${await auth}/refresh-token';

  // User Endpoints
  static Future<String> get users async => '${await fullBaseUrl}/users';
  static Future<String> get searchUsers async => '${await users}/search';
  static Future<String> getUserById(String id) async => '${await users}/$id';
  static Future<String> getUserByEmail(String email) async =>
      '${await users}/$email';
  static Future<String> updateUser(String id) async => '${await users}/$id';
  static Future<String> deleteUser(String id) async => '${await users}/$id';
  static Future<String> deleteUserCompletely(String id) async =>
      '${await users}/$id/complete';
  static Future<String> uploadUserImage(String id) async =>
      '${await users}/$id/uploadimage';

  // Region Endpoints
  static Future<String> get regions async => '${await fullBaseUrl}/regions';
  static Future<String> getRegionById(String id) async =>
      '${await regions}/$id';
  static Future<String> updateRegion(String id) async => '${await regions}/$id';
  static Future<String> deleteRegion(String id) async => '${await regions}/$id';
  static Future<String> getRegionUsers(String regionId) async =>
      '${await regions}/$regionId/users';
  static Future<String> getRegionGroups(String regionId) async =>
      '${await regions}/$regionId/groups';
  static Future<String> getRegionAnalytics(String regionId) async =>
      '${await regions}/$regionId/analytics';

  // Group Endpoints
  static Future<String> get groups async => '${await fullBaseUrl}/groups';
  static Future<String> get groupsAllForProfile async =>
      '${await groups}/all-for-profile';
  static Future<String> getGroupById(String id) async => '${await groups}/$id';
  static Future<String> get getGroupByName async => '${await groups}/name';
  static Future<String> updateGroup(String id) async => '${await groups}/$id';
  static Future<String> deleteGroup(String id) async => '${await groups}/$id';
  static Future<String> getGroupDemographics(String id) async =>
      '${await groups}/$id/groupDemographics';
  static Future<String> getGroupMembers(String id) async =>
      '${await groups}/$id/members';
  static Future<String> markGroupMemberInactive(
    String groupId,
    String userId,
  ) async => '${await groups}/$groupId/members/$userId/status';
  static Future<String> getmemberGroups(String userId) async =>
      '${await groups}/user/$userId';
  static Future<String> addGroupMember(String groupId, String userId) async =>
      '${await groups}/$groupId/members';
  static Future<String> removeGroupMember(
    String groupId,
    String userId,
  ) async => '${await groups}/$groupId/members/$userId';
  static Future<String> removeGroupMemberWithReason(
    String groupId,
    String userId,
  ) async => '${await groups}/$groupId/members/$userId/remove';
  static Future<String> getRemovedMembers(String groupId) async =>
      '${await groups}/$groupId/removed-members';
  static Future<String> restoreGroupMember(
    String groupId,
    String userId,
  ) async => '${await groups}/$groupId/members/$userId/restore';
  static Future<String> getGroupRemovalStats(String groupId) async =>
      '${await groups}/$groupId/removal-stats';
  static Future<String> getGroupRemovalPermissions(String groupId) async =>
      '${await groups}/$groupId/can-remove-members';
  static Future<String> getUserRemovalHistory(String userId) async =>
      '${await fullBaseUrl}/users/$userId/removal-history';
  static Future<String> get getAllRemovedMembers async =>
      '${await fullBaseUrl}/admin/removed-members';
  static Future<String> getRegionRemovedMembers(String regionId) async =>
      '${await regionalManagerAnalytics}/removed-members/$regionId';
  static Future<String> getGroupsByAdmin(String userId) async =>
      '${await groups}/admin/$userId/groups';
  static Future<String> get assignAdmin async => '${await groups}/assign-admin';
  static Future<String> getGroupAttendance(String id) async =>
      '${await groups}/$id/attendance';
  static Future<String> getOverallAttendanceByPeriod(String period) async =>
      '${await groups}/attendance/$period';
  static Future<String> getGroupsByRegion(String regionId) async =>
      '${await groups}/region/$regionId';

  // Event Endpoints
  static Future<String> get events async => '${await fullBaseUrl}/events';
  static Future<String> get leadershipEvents async =>
      '${await events}/leadership';
  static Future<String> createGroupEvent(String groupId) async =>
      '${await events}/group/$groupId';
  static Future<String> get createLeadershipEvent async =>
      '${await events}/leadership';
  static Future<String> getEventById(String id) async => '${await events}/$id';
  static Future<String> getEventParticipants(String id) async =>
      '${await events}/$id/participants';
  static Future<String> updateEvent(String id) async => '${await events}/$id';
  static Future<String> deleteEvent(String id) async => '${await events}/$id';
  static Future<String> getEventsByGroup(String groupId) async =>
      '${await events}/group/$groupId';
  static Future<String> getEventsByRegion(String regionId) async =>
      '${await events}/region/$regionId';

  // Attendance Endpoints
  static Future<String> get attendance async =>
      '${await fullBaseUrl}/attendance';
  static Future<String> createEventAttendance(String eventId) async =>
      '${await attendance}/event/$eventId';
  static Future<String> createLeadershipAttendance(String eventId) async =>
      '${await attendance}/leadership/$eventId';
  static Future<String> get getLeadershipAttendees async =>
      '${await attendance}/leadership-attendees';
  static Future<String> getAttendanceById(String id) async =>
      '${await attendance}/$id';
  static Future<String> updateAttendance(String id) async =>
      '${await attendance}/$id';
  static Future<String> deleteAttendance(String id) async =>
      '${await attendance}/$id';
  static Future<String> get getAttendanceByWeek async =>
      '${await attendance}/week';
  static Future<String> get getAttendanceByMonth async =>
      '${await attendance}/month';
  static Future<String> get getAttendanceByYear async =>
      '${await attendance}/year';
  static Future<String> getAttendedMembers(String eventId) async =>
      '${await attendance}/event/$eventId/attended-members';
  static Future<String> get getAttendanceStatus async =>
      '${await attendance}/status';
  static Future<String> getAttendanceByEvent(String eventId) async =>
      '${await attendance}/event/$eventId';
  static Future<String> getAttendanceByUser(String userId) async =>
      '${await attendance}/user/$userId';
  static Future<String> getAttendanceByPeriod(String period) async =>
      '${await attendance}/$period';
  static Future<String> getAttendanceByRegion(String regionId) async =>
      '${await attendance}/region/$regionId';
  static Future<String> getGroupAttendancePercentage(String groupId) async =>
      '${await attendance}/group/$groupId';

  // Analytics Endpoints
  // Base Analytics URLs
  static Future<String> get superAdminAnalytics async =>
      '${await fullBaseUrl}/super-admin/analytics';
  static Future<String> get regionalManagerAnalytics async =>
      '${await fullBaseUrl}/regional-manager/analytics';
  static Future<String> get adminAnalytics async =>
      '${await fullBaseUrl}/admin/analytics';

  // Super Admin Analytics Endpoints
  // Group Analytics
  static Future<String> getSuperAdminGroupDemographics(String groupId) async =>
      '${await superAdminAnalytics}/groups/$groupId/demographics';
  static Future<String> getSuperAdminGroupAttendance(String groupId) async =>
      '${await superAdminAnalytics}/groups/$groupId/attendance';
  static Future<String> getSuperAdminGroupGrowth(String groupId) async =>
      '${await superAdminAnalytics}/groups/$groupId/growth';
  static Future<String> get compareSuperAdminGroups async =>
      '${await superAdminAnalytics}/groups/compare';

  // Attendance Analytics
  static Future<String> getSuperAdminAttendanceByPeriod(String period) async =>
      '${await superAdminAnalytics}/attendance/period/$period';
  static Future<String> getSuperAdminOverallAttendanceByPeriod(
    String period,
  ) async => '${await superAdminAnalytics}/attendance/overall/$period';
  static Future<String> getSuperAdminUserAttendanceTrends(
    String userId,
  ) async => '${await superAdminAnalytics}/attendance/user/$userId';

  // Event Analytics
  static Future<String> getSuperAdminEventParticipation(String eventId) async =>
      '${await superAdminAnalytics}/events/$eventId/participation';
  static Future<String> get compareSuperAdminEventAttendance async =>
      '${await superAdminAnalytics}/events/compare-attendance';

  // Member Analytics
  static Future<String> get getSuperAdminMemberParticipation async =>
      '${await superAdminAnalytics}/members/participation';
  static Future<String> get getSuperAdminMemberActivityStatus async =>
      '${await superAdminAnalytics}/members/activity-status';

  // Dashboard Analytics
  static Future<String> get getSuperAdminDashboardSummary async =>
      '${await superAdminAnalytics}/dashboard/summary';
  static Future<String> getSuperAdminGroupDashboardData(String groupId) async =>
      '${await superAdminAnalytics}/dashboard/group/$groupId';

  // Database Analytics
  static Future<String> get getSuperAdminDatabaseStats async =>
      '${await superAdminAnalytics}/database-stats';

  // Regional Manager Analytics Endpoints
  // Group Analytics
  static Future<String> getRegionalManagerGroupDemographics(
    String groupId,
  ) async => '${await regionalManagerAnalytics}/groups/$groupId/demographics';
  static Future<String> getRegionalManagerGroupAttendance(
    String groupId,
  ) async => '${await regionalManagerAnalytics}/groups/$groupId/attendance';
  static Future<String> getRegionalManagerGroupGrowth(String groupId) async =>
      '${await regionalManagerAnalytics}/groups/$groupId/growth';
  static Future<String> get compareRegionalManagerGroups async =>
      '${await regionalManagerAnalytics}/groups/compare';

  // Attendance Analytics
  static Future<String> getRegionalManagerAttendanceByPeriod(
    String period,
  ) async => '${await regionalManagerAnalytics}/attendance/period/$period';
  static Future<String> getRegionalManagerOverallAttendanceByPeriod(
    String period,
  ) async => '${await regionalManagerAnalytics}/attendance/overall/$period';
  static Future<String> getRegionalManagerUserAttendanceTrends(
    String userId,
  ) async => '${await regionalManagerAnalytics}/attendance/user/$userId';

  // Event Analytics
  static Future<String> getRegionalManagerEventParticipation(
    String eventId,
  ) async => '${await regionalManagerAnalytics}/events/$eventId/participation';
  static Future<String> get compareRegionalManagerEventAttendance async =>
      '${await regionalManagerAnalytics}/events/compare-attendance';

  // Member Analytics
  static Future<String> get getRegionalManagerMemberParticipation async =>
      '${await regionalManagerAnalytics}/members/participation';
  static Future<String> get getRegionalManagerMemberActivityStatus async =>
      '${await regionalManagerAnalytics}/members/activity-status';

  // Dashboard Analytics
  static Future<String> get getRegionalManagerDashboardSummary async =>
      '${await regionalManagerAnalytics}/dashboard/summary';
  static Future<String> getRegionalManagerGroupDashboardData(
    String groupId,
  ) async => '${await regionalManagerAnalytics}/dashboard/group/$groupId';

  // Database Analytics
  static Future<String> get getRegionalManagerDatabaseStats async =>
      '${await regionalManagerAnalytics}/database-stats';

  // Admin (Group Admin) Analytics Endpoints
  // Group Analytics
  static Future<String> getAdminGroupDemographics(String groupId) async =>
      '${await adminAnalytics}/groups/$groupId/demographics';
  static Future<String> getAdminGroupAttendance(String groupId) async =>
      '${await adminAnalytics}/groups/$groupId/attendance';
  static Future<String> getAdminGroupGrowth(String groupId) async =>
      '${await adminAnalytics}/groups/$groupId/growth';

  // Attendance Analytics
  static Future<String> getAdminGroupAttendanceByPeriod(
    String groupId,
    String period,
  ) async =>
      '${await adminAnalytics}/groups/$groupId/attendance/period/$period';

  // Event Analytics
  static Future<String> getAdminEventParticipation(String eventId) async =>
      '${await adminAnalytics}/events/$eventId/participation';

  // Member Analytics
  static Future<String> getAdminGroupMemberParticipation(
    String groupId,
  ) async => '${await adminAnalytics}/groups/$groupId/members/participation';
  static Future<String> getAdminGroupMemberActivityStatus(
    String groupId,
  ) async => '${await adminAnalytics}/groups/$groupId/members/activity-status';

  // Dashboard Analytics
  static Future<String> getAdminGroupDashboardData(String groupId) async =>
      '${await adminAnalytics}/groups/$groupId/dashboard';

  // Database Analytics
  static Future<String> get getAdminDatabaseStats async =>
      '${await adminAnalytics}/database-stats';
}
