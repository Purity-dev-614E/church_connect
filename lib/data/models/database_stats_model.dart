// Database Stats Models
class DatabaseStats {
  final int totalUsers;
  final int totalGroups;
  final int totalEvents;
  final double overallAttendancePercentage;
  final int activeGroups;
  final int inactiveGroups;

  DatabaseStats({
    required this.totalUsers,
    required this.totalGroups,
    required this.totalEvents,
    required this.overallAttendancePercentage,
    required this.activeGroups,
    required this.inactiveGroups,
  });

  factory DatabaseStats.fromJson(Map<String, dynamic> json) {
    return DatabaseStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
      overallAttendancePercentage: (json['overallAttendancePercentage'] ?? 0.0).toDouble(),
      activeGroups: json['activeGroups'] ?? 0,
      inactiveGroups: json['inactiveGroups'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalGroups': totalGroups,
      'totalEvents': totalEvents,
      'overallAttendancePercentage': overallAttendancePercentage,
      'activeGroups': activeGroups,
      'inactiveGroups': inactiveGroups,
    };
  }
}
