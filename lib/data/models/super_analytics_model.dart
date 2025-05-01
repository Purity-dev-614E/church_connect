// Models for Super Admin Analytics


// Group Demographics Models
class GenderDistribution {
  final String gender;
  final int count;

  GenderDistribution({
    required this.gender,
    required this.count,
  });

  factory GenderDistribution.fromJson(Map<String, dynamic> json) {
    return GenderDistribution(
      gender: json['gender'] ?? 'Unknown',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class RoleDistribution {
  final String role;
  final int count;

  RoleDistribution({
    required this.role,
    required this.count,
  });

  factory RoleDistribution.fromJson(Map<String, dynamic> json) {
    return RoleDistribution(
      role: json['role'] ?? 'Unknown',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class GroupDemographics {
  final List<GenderDistribution> genderDistribution;
  final List<RoleDistribution> roleDistribution;

  GroupDemographics({
    required this.genderDistribution,
    required this.roleDistribution,
  });

  factory GroupDemographics.fromJson(Map<String, dynamic> json) {
    return GroupDemographics(
      genderDistribution: (json['genderDistribution'] as List?)
          ?.map((e) => GenderDistribution.fromJson(e))
          .toList() ??
          [],
      roleDistribution: (json['roleDistribution'] as List?)
          ?.map((e) => RoleDistribution.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Group Attendance Models
class EventAttendanceStat {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final int totalMembers;
  final int presentMembers;
  final double attendanceRate;

  EventAttendanceStat({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.totalMembers,
    required this.presentMembers,
    required this.attendanceRate,
  });

  factory EventAttendanceStat.fromJson(Map<String, dynamic> json) {
    return EventAttendanceStat(
      eventId: json['eventId'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      totalMembers: json['totalMembers'] ?? 0,
      presentMembers: json['presentMembers'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class OverallAttendanceStats {
  final int totalEvents;
  final int totalMembers;
  final int presentMembers;
  final double attendanceRate;

  OverallAttendanceStats({
    required this.totalEvents,
    required this.totalMembers,
    required this.presentMembers,
    required this.attendanceRate,
  });

  factory OverallAttendanceStats.fromJson(Map<String, dynamic> json) {
    return OverallAttendanceStats(
      totalEvents: json['totalEvents'] ?? 0,
      totalMembers: json['totalMembers'] ?? 0,
      presentMembers: json['presentMembers'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class GroupAttendanceStats {
  final List<EventAttendanceStat> eventStats;
  final OverallAttendanceStats overallStats;

  GroupAttendanceStats({
    required this.eventStats,
    required this.overallStats,
  });

  factory GroupAttendanceStats.fromJson(Map<String, dynamic> json) {
    return GroupAttendanceStats(
      eventStats: (json['eventStats'] as List?)
          ?.map((e) => EventAttendanceStat.fromJson(e))
          .toList() ??
          [],
      overallStats: OverallAttendanceStats.fromJson(json['overallStats'] ?? {}),
    );
  }
}

// Group Growth Models
class MonthlyGrowth {
  final String month;
  final int newMembers;

  MonthlyGrowth({
    required this.month,
    required this.newMembers,
  });

  factory MonthlyGrowth.fromJson(Map<String, dynamic> json) {
    return MonthlyGrowth(
      month: json.keys.first,
      newMembers: json.values.first,
    );
  }
}

class CumulativeGrowth {
  final String month;
  final int newMembers;
  final int totalMembers;

  CumulativeGrowth({
    required this.month,
    required this.newMembers,
    required this.totalMembers,
  });

  factory CumulativeGrowth.fromJson(Map<String, dynamic> json) {
    return CumulativeGrowth(
      month: json['month'] ?? '',
      newMembers: json['newMembers'] ?? 0,
      totalMembers: json['totalMembers'] ?? 0,
    );
  }
}

class GroupGrowthAnalytics {
  final Map<String, int> monthlyGrowth;
  final List<CumulativeGrowth> cumulativeGrowth;

  GroupGrowthAnalytics({
    required this.monthlyGrowth,
    required this.cumulativeGrowth,
  });

  factory GroupGrowthAnalytics.fromJson(Map<String, dynamic> json) {
    // Convert monthlyGrowth from JSON to Map<String, int>
    Map<String, int> monthlyGrowthMap = {};
    if (json['monthlyGrowth'] != null) {
      json['monthlyGrowth'].forEach((key, value) {
        monthlyGrowthMap[key] = value;
      });
    }

    return GroupGrowthAnalytics(
      monthlyGrowth: monthlyGrowthMap,
      cumulativeGrowth: (json['cumulativeGrowth'] as List?)
          ?.map((e) => CumulativeGrowth.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Group Comparison Models
class GroupMemberCount {
  final String groupId;
  final String groupName;
  final int memberCount;

  GroupMemberCount({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  factory GroupMemberCount.fromJson(Map<String, dynamic> json) {
    return GroupMemberCount(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      memberCount: json['memberCount'] ?? 0,
    );
  }
}

class GroupAttendanceRate {
  final String groupId;
  final String groupName;
  final double attendanceRate;

  GroupAttendanceRate({
    required this.groupId,
    required this.groupName,
    required this.attendanceRate,
  });

  factory GroupAttendanceRate.fromJson(Map<String, dynamic> json) {
    return GroupAttendanceRate(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class GroupComparison {
  final List<GroupMemberCount> memberCounts;
  final List<GroupAttendanceRate> attendanceRates;

  GroupComparison({
    required this.memberCounts,
    required this.attendanceRates,
  });

  factory GroupComparison.fromJson(Map<String, dynamic> json) {
    return GroupComparison(
      memberCounts: (json['memberCounts'] as List?)
          ?.map((e) => GroupMemberCount.fromJson(e))
          .toList() ??
          [],
      attendanceRates: (json['attendanceRates'] as List?)
          ?.map((e) => GroupAttendanceRate.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Attendance Period Models
class DailyAttendanceStat {
  final String date;
  final int events;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  DailyAttendanceStat({
    required this.date,
    required this.events,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory DailyAttendanceStat.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceStat(
      date: json['date'] ?? '',
      events: json['events'] ?? 0,
      totalPossible: json['totalPossible'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class AttendanceByPeriod {
  final List<EventAttendanceStat> eventStats;
  final List<DailyAttendanceStat> dailyStats;

  AttendanceByPeriod({
    required this.eventStats,
    required this.dailyStats,
  });

  factory AttendanceByPeriod.fromJson(Map<String, dynamic> json) {
    return AttendanceByPeriod(
      eventStats: (json['eventStats'] as List?)
          ?.map((e) => EventAttendanceStat.fromJson(e))
          .toList() ??
          [],
      dailyStats: (json['dailyStats'] as List?)
          ?.map((e) => DailyAttendanceStat.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Overall Attendance Models
class GroupAttendanceStat {
  final String groupId;
  final String groupName;
  final int eventCount;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  GroupAttendanceStat({
    required this.groupId,
    required this.groupName,
    required this.eventCount,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory GroupAttendanceStat.fromJson(Map<String, dynamic> json) {
    return GroupAttendanceStat(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      eventCount: json['eventCount'] ?? 0,
      totalPossible: json['totalPossible'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class OverallAttendanceStat {
  final int eventCount;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  OverallAttendanceStat({
    required this.eventCount,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory OverallAttendanceStat.fromJson(Map<String, dynamic> json) {
    return OverallAttendanceStat(
      eventCount: json['eventCount'] ?? 0,
      totalPossible: json['totalPossible'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class OverallAttendanceByPeriod {
  final List<GroupAttendanceStat> groupStats;
  final OverallAttendanceStat overallStats;

  OverallAttendanceByPeriod({
    required this.groupStats,
    required this.overallStats,
  });

  factory OverallAttendanceByPeriod.fromJson(Map<String, dynamic> json) {
    return OverallAttendanceByPeriod(
      groupStats: (json['groupStats'] as List?)
          ?.map((e) => GroupAttendanceStat.fromJson(e))
          .toList() ??
          [],
      overallStats: OverallAttendanceStat.fromJson(json['overallStats'] ?? {}),
    );
  }
}

// Event Participation Models
class ParticipantStat {
  final String userId;
  final String userName;
  final bool present;
  final String? notes;

  ParticipantStat({
    required this.userId,
    required this.userName,
    required this.present,
    this.notes,
  });

  factory ParticipantStat.fromJson(Map<String, dynamic> json) {
    return ParticipantStat(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      present: json['present'] ?? false,
      notes: json['notes'],
    );
  }
}

class EventParticipationStats {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String groupId;
  final String groupName;
  final int totalParticipants;
  final int presentCount;
  final double attendanceRate;
  final List<ParticipantStat> participants;

  EventParticipationStats({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.groupId,
    required this.groupName,
    required this.totalParticipants,
    required this.presentCount,
    required this.attendanceRate,
    required this.participants,
  });

  factory EventParticipationStats.fromJson(Map<String, dynamic> json) {
    return EventParticipationStats(
      eventId: json['eventId'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      totalParticipants: json['totalParticipants'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
      participants: (json['participants'] as List?)
          ?.map((e) => ParticipantStat.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Event Comparison Models
class EventAttendanceComparison {
  final List<EventAttendanceStat> events;

  EventAttendanceComparison({
    required this.events,
  });

  factory EventAttendanceComparison.fromJson(Map<String, dynamic> json) {
    return EventAttendanceComparison(
      events: (json['events'] as List?)
          ?.map((e) => EventAttendanceStat.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Member Activity Status Models
class ActivityStatusCount {
  final int active;
  final int inactive;
  final int total;

  ActivityStatusCount({
    required this.active,
    required this.inactive,
    required this.total,
  });

  factory ActivityStatusCount.fromJson(Map<String, dynamic> json) {
    return ActivityStatusCount(
      active: json['Active'] ?? 0,
      inactive: json['Inactive'] ?? 0,
      total: json['Total'] ?? 0,
    );
  }
}

class MemberActivityStatus {
  final List<Map<String, dynamic>> members;
  final ActivityStatusCount counts;

  MemberActivityStatus({
    required this.members,
    required this.counts,
  });

  factory MemberActivityStatus.fromJson(Map<String, dynamic> json) {
    return MemberActivityStatus(
      members: (json['members'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
          [],
      counts: ActivityStatusCount.fromJson(json['counts'] ?? {}),
    );
  }
}

// Dashboard Summary Models
class RecentAttendance {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String groupId;
  final String groupName;
  final int totalParticipants;
  final int presentCount;
  final double attendanceRate;

  RecentAttendance({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.groupId,
    required this.groupName,
    required this.totalParticipants,
    required this.presentCount,
    required this.attendanceRate,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': eventDate.toIso8601String(),
      'groupId': groupId,
      'groupName': groupName,
      'totalParticipants': totalParticipants,
      'presentCount': presentCount,
      'attendanceRate': attendanceRate,
    };
  }

  factory RecentAttendance.fromJson(Map<String, dynamic> json) {
    return RecentAttendance(
      eventId: json['eventId'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      totalParticipants: json['totalParticipants'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
    );
  }
}

class UpcomingEvent {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String groupId;
  final String groupName;

  UpcomingEvent({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.groupId,
    required this.groupName,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': eventDate.toIso8601String(),
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    return UpcomingEvent(
      eventId: json['eventId'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
    );
  }
}

class DashboardSummary {
  final int totalUsers;
  final int totalGroups;
  final int totalEvents;
  final List<RecentAttendance> recentEvents;
  final List<UpcomingEvent> upcomingEvents;

  DashboardSummary({
    required this.totalUsers,
    required this.totalGroups,
    required this.totalEvents,
    required this.recentEvents,
    required this.upcomingEvents,
  });

  // Convert DashboardSummary to a Map<String, dynamic>
  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'totalGroups': totalGroups,
      'totalEvents': totalEvents,
      'recentEvents': recentEvents.map((e) => e.toJson()).toList(),
      'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
    };
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUsers: json['totalUsers'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
      recentEvents: (json['recentEvents'] as List?)
          ?.map((e) => RecentAttendance.fromJson(e))
          .toList() ??
          [],
      upcomingEvents: (json['upcomingEvents'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// Group Dashboard Models
class GroupMemberStat {
  final int totalMembers;
  final int activeMembers;
  final double activeRate;

  GroupMemberStat({
    required this.totalMembers,
    required this.activeMembers,
    required this.activeRate,
  });

  factory GroupMemberStat.fromJson(Map<String, dynamic> json) {
    return GroupMemberStat(
      totalMembers: json['totalMembers'] ?? 0,
      activeMembers: json['activeMembers'] ?? 0,
      activeRate: (json['activeRate'] ?? 0).toDouble(),
    );
  }
}

class GroupDashboardData {
  final String groupId;
  final String groupName;
  final String? description;
  final DateTime createdAt;
  final GroupMemberStat memberStats;
  final List<EventAttendanceStat> recentAttendance;
  final List<UpcomingEvent> upcomingEvents;

  GroupDashboardData({
    required this.groupId,
    required this.groupName,
    this.description,
    required this.createdAt,
    required this.memberStats,
    required this.recentAttendance,
    required this.upcomingEvents,
  });

  factory GroupDashboardData.fromJson(Map<String, dynamic> json) {
    return GroupDashboardData(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      memberStats: GroupMemberStat.fromJson(json['memberStats'] ?? {}),
      recentAttendance: (json['recentAttendance'] as List?)
          ?.map((e) => EventAttendanceStat.fromJson(e))
          .toList() ??
          [],
      upcomingEvents: (json['upcomingEvents'] as List?)
          ?.map((e) => UpcomingEvent.fromJson(e))
          .toList() ??
          [],
    );
  }
}