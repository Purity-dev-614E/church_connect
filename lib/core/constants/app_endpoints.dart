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

  // Event Endpoints
  static const String events = '$baseUrl/events';
  static String createGroupEvent(String groupId) => '$events/group/$groupId';
  static String getEventById(String id) => '$events/$id';
  static String updateEvent(String id) => '$events/$id';
  static String deleteEvent(String id) => '$events/$id';
  static String getEventsByGroup(String groupId) => '$events/group/$groupId';

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
}