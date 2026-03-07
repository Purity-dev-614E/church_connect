class ApiEndpoints {
  //   [ PRODUCTION FLAG]
  static const bool _isProduction = true;

  static const String _serverBaseUrl =
      'https://safari-backend-fgl3.onrender.com';
  static const String baseUrl = '/api';
  static String get fullBaseUrl =>
      _isProduction ? baseUrl : '$_serverBaseUrl$baseUrl';

  // Authentication Endpoints
  static String get auth => '$fullBaseUrl/auth';
  static String get signup => '$auth/signup';
  static String get login => '$auth/login';
  static String get forgotPassword => '$auth/forgot-password';
  static String get refreshToken => '$auth/refresh-token';

  // User Endpoints
  static String get users => '$fullBaseUrl/users';
  static String get searchUsers => '$users/search';
  static String getUserById(String id) => '$users/$id';
  static String getUserByEmail(String email) => '$users/$email';
  static String updateUser(String id) => '$users/$id';
  static String deleteUser(String id) => '$users/$id';
  static String deleteUserCompletely(String id) => '$users/$id/complete';
  static String uploadUserImage(String id) => '$users/$id/uploadimage';

  // Region Endpoints
  static String get regions => '$fullBaseUrl/regions';
  static String getRegionById(String id) => '$regions/$id';
  static String updateRegion(String id) => '$regions/$id';
  static String deleteRegion(String id) => '$regions/$id';
  static String getRegionUsers(String regionId) => '$regions/$regionId/users';
  static String getRegionGroups(String regionId) => '$regions/$regionId/groups';
  static String getRegionAnalytics(String regionId) =>
      '$regions/$regionId/analytics';

  // Group Endpoints
  static String get groups => '$fullBaseUrl/groups';
  static String get groupsAllForProfile => '$groups/all-for-profile';
  static String getGroupById(String id) => '$groups/$id';
  static String get getGroupByName => '$groups/name';
  static String updateGroup(String id) => '$groups/$id';
  static String deleteGroup(String id) => '$groups/$id';
  static String getGroupDemographics(String id) =>
      '$groups/$id/groupDemographics';
  static String getGroupMembers(String id) => '$groups/$id/members';
  static String markGroupMemberInactive(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/status';
  static String getmemberGroups(String userId) => '$groups/user/$userId';
  static String addGroupMember(String groupId, String userId) =>
      '$groups/$groupId/members';
  static String removeGroupMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId';
  static String removeGroupMemberWithReason(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/remove';
  static String getRemovedMembers(String groupId) =>
      '$groups/$groupId/removed-members';
  static String restoreGroupMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/restore';
  static String getGroupRemovalStats(String groupId) =>
      '$groups/$groupId/removal-stats';
  static String getGroupRemovalPermissions(String groupId) =>
      '$groups/$groupId/can-remove-members';
  static String getUserRemovalHistory(String userId) =>
      '$fullBaseUrl/users/$userId/removal-history';
  static String get getAllRemovedMembers =>
      '$fullBaseUrl/admin/removed-members';
  static String getRegionRemovedMembers(String regionId) =>
      '$regionalManagerAnalytics/removed-members/$regionId';
  static String getGroupsByAdmin(String userId) =>
      '$groups/admin/$userId/groups';
  static String get assignAdmin => '$groups/assign-admin';
  static String getGroupAttendance(String id) => '$groups/$id/attendance';
  static String getOverallAttendanceByPeriod(String period) =>
      '$groups/attendance/$period';
  static String getGroupsByRegion(String regionId) =>
      '$groups/region/$regionId';

  // Event Endpoints
  static String get events => '$fullBaseUrl/events';
  static String get leadershipEvents => '$events/leadership';
  static String createGroupEvent(String groupId) => '$events/group/$groupId';
  static String get createLeadershipEvent => '$events/leadership';
  static String getEventById(String id) => '$events/$id';
  static String getEventParticipants(String id) => '$events/$id/participants';
  static String updateEvent(String id) => '$events/$id';
  static String deleteEvent(String id) => '$events/$id';
  static String getEventsByGroup(String groupId) => '$events/group/$groupId';
  static String getEventsByRegion(String regionId) =>
      '$events/region/$regionId';

  // Attendance Endpoints
  static String get attendance => '$fullBaseUrl/attendance';
  static String createEventAttendance(String eventId) =>
      '$attendance/event/$eventId';
  static String createLeadershipAttendance(String eventId) =>
      '$attendance/leadership/$eventId';
  static String getAttendanceById(String id) => '$attendance/$id';
  static String updateAttendance(String id) => '$attendance/$id';
  static String deleteAttendance(String id) => '$attendance/$id';
  static String get getAttendanceByWeek => '$attendance/week';
  static String get getAttendanceByMonth => '$attendance/month';
  static String get getAttendanceByYear => '$attendance/year';
  static String getAttendedMembers(String eventId) =>
      '$attendance/event/$eventId/attended-members';
  static String get getAttendanceStatus => '$attendance/status';
  static String getAttendanceByEvent(String eventId) =>
      '$attendance/event/$eventId';
  static String getAttendanceByUser(String userId) =>
      '$attendance/user/$userId';
  static String getAttendanceByPeriod(String period) => '$attendance/$period';
  static String getAttendanceByRegion(String regionId) =>
      '$attendance/region/$regionId';
  static String getGroupAttendancePercentage(String groupId) =>
      '$attendance/group/$groupId';

  // Analytics Endpoints
  // Base Analytics URLs
  static String get superAdminAnalytics => '$fullBaseUrl/super-admin/analytics';
  static String get regionalManagerAnalytics =>
      '$fullBaseUrl/regional-manager/analytics';
  static String get adminAnalytics => '$fullBaseUrl/admin/analytics';

  // Super Admin Analytics Endpoints
  // Group Analytics
  static String getSuperAdminGroupDemographics(String groupId) =>
      '$superAdminAnalytics/groups/$groupId/demographics';
  static String getSuperAdminGroupAttendance(String groupId) =>
      '$superAdminAnalytics/groups/$groupId/attendance';
  static String getSuperAdminGroupGrowth(String groupId) =>
      '$superAdminAnalytics/groups/$groupId/growth';
  static String get compareSuperAdminGroups =>
      '$superAdminAnalytics/groups/compare';

  // Attendance Analytics
  static String getSuperAdminAttendanceByPeriod(String period) =>
      '$superAdminAnalytics/attendance/period/$period';
  static String getSuperAdminOverallAttendanceByPeriod(String period) =>
      '$superAdminAnalytics/attendance/overall/$period';
  static String getSuperAdminUserAttendanceTrends(String userId) =>
      '$superAdminAnalytics/attendance/user/$userId';

  // Event Analytics
  static String getSuperAdminEventParticipation(String eventId) =>
      '$superAdminAnalytics/events/$eventId/participation';
  static String get compareSuperAdminEventAttendance =>
      '$superAdminAnalytics/events/compare-attendance';

  // Member Analytics
  static String get getSuperAdminMemberParticipation =>
      '$superAdminAnalytics/members/participation';
  static String get getSuperAdminMemberActivityStatus =>
      '$superAdminAnalytics/members/activity-status';

  // Dashboard Analytics
  static String get getSuperAdminDashboardSummary =>
      '$superAdminAnalytics/dashboard/summary';
  static String getSuperAdminGroupDashboardData(String groupId) =>
      '$superAdminAnalytics/dashboard/group/$groupId';

  // Regional Manager Analytics Endpoints
  // Group Analytics
  static String getRegionalManagerGroupDemographics(String groupId) =>
      '$regionalManagerAnalytics/groups/$groupId/demographics';
  static String getRegionalManagerGroupAttendance(String groupId) =>
      '$regionalManagerAnalytics/groups/$groupId/attendance';
  static String getRegionalManagerGroupGrowth(String groupId) =>
      '$regionalManagerAnalytics/groups/$groupId/growth';
  static String get compareRegionalManagerGroups =>
      '$regionalManagerAnalytics/groups/compare';

  // Attendance Analytics
  static String getRegionalManagerAttendanceByPeriod(String period) =>
      '$regionalManagerAnalytics/attendance/period/$period';
  static String getRegionalManagerOverallAttendanceByPeriod(String period) =>
      '$regionalManagerAnalytics/attendance/overall/$period';
  static String getRegionalManagerUserAttendanceTrends(String userId) =>
      '$regionalManagerAnalytics/attendance/user/$userId';

  // Event Analytics
  static String getRegionalManagerEventParticipation(String eventId) =>
      '$regionalManagerAnalytics/events/$eventId/participation';
  static String get compareRegionalManagerEventAttendance =>
      '$regionalManagerAnalytics/events/compare-attendance';

  // Member Analytics
  static String get getRegionalManagerMemberParticipation =>
      '$regionalManagerAnalytics/members/participation';
  static String get getRegionalManagerMemberActivityStatus =>
      '$regionalManagerAnalytics/members/activity-status';

  // Dashboard Analytics
  static String get getRegionalManagerDashboardSummary =>
      '$regionalManagerAnalytics/dashboard/summary';
  static String getRegionalManagerGroupDashboardData(String groupId) =>
      '$regionalManagerAnalytics/dashboard/group/$groupId';

  // Admin (Group Admin) Analytics Endpoints
  // Group Analytics
  static String getAdminGroupDemographics(String groupId) =>
      '$adminAnalytics/groups/$groupId/demographics';
  static String getAdminGroupAttendance(String groupId) =>
      '$adminAnalytics/groups/$groupId/attendance';
  static String getAdminGroupGrowth(String groupId) =>
      '$adminAnalytics/groups/$groupId/growth';

  // Attendance Analytics
  static String getAdminGroupAttendanceByPeriod(
    String groupId,
    String period,
  ) => '$adminAnalytics/groups/$groupId/attendance/period/$period';

  // Event Analytics
  static String getAdminEventParticipation(String eventId) =>
      '$adminAnalytics/events/$eventId/participation';

  // Member Analytics
  static String getAdminGroupMemberParticipation(String groupId) =>
      '$adminAnalytics/groups/$groupId/members/participation';
  static String getAdminGroupMemberActivityStatus(String groupId) =>
      '$adminAnalytics/groups/$groupId/members/activity-status';

  // Dashboard Analytics
  static String getAdminGroupDashboardData(String groupId) =>
      '$adminAnalytics/groups/$groupId/dashboard';
}
