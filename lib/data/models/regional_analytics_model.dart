// Models for Region Analytics

// Gender and Role Distribution
class DistributionItem {
  final String category;
  final int count;

  DistributionItem({required this.category, required this.count});

  factory DistributionItem.fromJson(Map<String, dynamic> json) {
    return DistributionItem(
      category: json['gender'] ?? json['role'] ?? 'Unknown',
      count: json['count'],
    );
  }
}

class GroupDemographics {
  final List<DistributionItem> genderDistribution;
  final List<DistributionItem> roleDistribution;

  GroupDemographics({
    required this.genderDistribution,
    required this.roleDistribution,
  });

  factory GroupDemographics.fromJson(Map<String, dynamic> json) {
    return GroupDemographics(
      genderDistribution: (json['genderDistribution'] as List)
          .map((item) => DistributionItem.fromJson(item))
          .toList(),
      roleDistribution: (json['roleDistribution'] as List)
          .map((item) => DistributionItem.fromJson(item))
          .toList(),
    );
  }
}

// Group Attendance Stats
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
      eventId: json['eventId'],
      eventTitle: json['eventTitle'],
      eventDate: DateTime.parse(json['eventDate']),
      totalMembers: json['totalMembers'],
      presentMembers: json['presentMembers'],
      attendanceRate: json['attendanceRate'].toDouble(),
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
      totalEvents: json['totalEvents'],
      totalMembers: json['totalMembers'],
      presentMembers: json['presentMembers'],
      attendanceRate: json['attendanceRate'].toDouble(),
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
      eventStats: (json['eventStats'] as List)
          .map((item) => EventAttendanceStat.fromJson(item))
          .toList(),
      overallStats: OverallAttendanceStats.fromJson(json['overallStats']),
    );
  }
}

// Group Growth Analytics
class MonthlyGrowth {
  final String month;
  final int count;

  MonthlyGrowth({required this.month, required this.count});

  factory MonthlyGrowth.fromJson(Map<String, dynamic> json) {
    return MonthlyGrowth(
      month: json.keys.first,
      count: json.values.first,
    );
  }
}

class CumulativeGrowthItem {
  final String month;
  final int newMembers;
  final int totalMembers;

  CumulativeGrowthItem({
    required this.month,
    required this.newMembers,
    required this.totalMembers,
  });

  factory CumulativeGrowthItem.fromJson(Map<String, dynamic> json) {
    return CumulativeGrowthItem(
      month: json['month'],
      newMembers: json['newMembers'],
      totalMembers: json['totalMembers'],
    );
  }
}

class GroupGrowthAnalytics {
  final Map<String, int> monthlyGrowth;
  final List<CumulativeGrowthItem> cumulativeGrowth;

  GroupGrowthAnalytics({
    required this.monthlyGrowth,
    required this.cumulativeGrowth,
  });

  factory GroupGrowthAnalytics.fromJson(Map<String, dynamic> json) {
    // Convert monthlyGrowth from JSON to Map<String, int>
    final Map<String, int> monthlyGrowthMap = {};
    (json['monthlyGrowth'] as Map<String, dynamic>).forEach((key, value) {
      monthlyGrowthMap[key] = value as int;
    });

    return GroupGrowthAnalytics(
      monthlyGrowth: monthlyGrowthMap,
      cumulativeGrowth: (json['cumulativeGrowth'] as List)
          .map((item) => CumulativeGrowthItem.fromJson(item))
          .toList(),
    );
  }
}

// Group Comparison
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
      groupId: json['groupId'],
      groupName: json['groupName'],
      memberCount: json['memberCount'],
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
      groupId: json['groupId'],
      groupName: json['groupName'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

class GroupComparisonResult {
  final List<GroupMemberCount> memberCounts;
  final List<GroupAttendanceRate> attendanceRates;

  GroupComparisonResult({
    required this.memberCounts,
    required this.attendanceRates,
  });

  factory GroupComparisonResult.fromJson(Map<String, dynamic> json) {
    return GroupComparisonResult(
      memberCounts: (json['memberCounts'] as List)
          .map((item) => GroupMemberCount.fromJson(item))
          .toList(),
      attendanceRates: (json['attendanceRates'] as List)
          .map((item) => GroupAttendanceRate.fromJson(item))
          .toList(),
    );
  }
}

// Event Participation Stats
class ParticipationDetail {
  final String userId;
  final String userName;
  final String userEmail;
  final bool present;
  final String? notes;

  ParticipationDetail({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.present,
    this.notes,
  });

  factory ParticipationDetail.fromJson(Map<String, dynamic> json) {
    return ParticipationDetail(
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      present: json['present'],
      notes: json['notes'],
    );
  }
}

class EventParticipationStats {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final int totalMembers;
  final int presentMembers;
  final double attendanceRate;
  final List<ParticipationDetail> participationDetails;

  EventParticipationStats({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.totalMembers,
    required this.presentMembers,
    required this.attendanceRate,
    required this.participationDetails,
  });

  factory EventParticipationStats.fromJson(Map<String, dynamic> json) {
    return EventParticipationStats(
      eventId: json['eventId'],
      eventTitle: json['eventTitle'],
      eventDate: DateTime.parse(json['eventDate']),
      totalMembers: json['totalMembers'],
      presentMembers: json['presentMembers'],
      attendanceRate: json['attendanceRate'].toDouble(),
      participationDetails: (json['participationDetails'] as List)
          .map((item) => ParticipationDetail.fromJson(item))
          .toList(),
    );
  }
}

// Event Attendance Comparison
class EventAttendanceComparison {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  EventAttendanceComparison({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory EventAttendanceComparison.fromJson(Map<String, dynamic> json) {
    return EventAttendanceComparison(
      eventId: json['eventId'],
      eventTitle: json['eventTitle'],
      eventDate: DateTime.parse(json['eventDate']),
      totalPossible: json['totalPossible'],
      presentCount: json['presentCount'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

// User Attendance Trends
class AttendanceRecord {
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String groupId;
  final String groupName;
  final bool present;

  AttendanceRecord({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.groupId,
    required this.groupName,
    required this.present,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      eventId: json['eventId'],
      eventTitle: json['eventTitle'],
      eventDate: DateTime.parse(json['eventDate']),
      groupId: json['groupId'],
      groupName: json['groupName'],
      present: json['present'],
    );
  }
}

class MonthlyTrend {
  final String month;
  final int totalEvents;
  final int attendedEvents;
  final double attendanceRate;

  MonthlyTrend({
    required this.month,
    required this.totalEvents,
    required this.attendedEvents,
    required this.attendanceRate,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'],
      totalEvents: json['totalEvents'],
      attendedEvents: json['attendedEvents'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

class UserAttendanceTrends {
  final String userId;
  final String userName;
  final int totalEvents;
  final int attendedEvents;
  final double overallAttendanceRate;
  final List<AttendanceRecord> attendanceRecords;
  final List<MonthlyTrend> monthlyTrends;

  UserAttendanceTrends({
    required this.userId,
    required this.userName,
    required this.totalEvents,
    required this.attendedEvents,
    required this.overallAttendanceRate,
    required this.attendanceRecords,
    required this.monthlyTrends,
  });

  factory UserAttendanceTrends.fromJson(Map<String, dynamic> json) {
    return UserAttendanceTrends(
      userId: json['userId'],
      userName: json['userName'],
      totalEvents: json['totalEvents'],
      attendedEvents: json['attendedEvents'],
      overallAttendanceRate: json['overallAttendanceRate'].toDouble(),
      attendanceRecords: (json['attendanceRecords'] as List)
          .map((item) => AttendanceRecord.fromJson(item))
          .toList(),
      monthlyTrends: (json['monthlyTrends'] as List)
          .map((item) => MonthlyTrend.fromJson(item))
          .toList(),
    );
  }
}

// Attendance By Period
class GroupStat {
  final String groupId;
  final String groupName;
  final int eventCount;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  GroupStat({
    required this.groupId,
    required this.groupName,
    required this.eventCount,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory GroupStat.fromJson(Map<String, dynamic> json) {
    return GroupStat(
      groupId: json['groupId'],
      groupName: json['groupName'],
      eventCount: json['eventCount'],
      totalPossible: json['totalPossible'],
      presentCount: json['presentCount'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

class OverallPeriodStats {
  final int eventCount;
  final int totalPossible;
  final int presentCount;
  final double attendanceRate;

  OverallPeriodStats({
    required this.eventCount,
    required this.totalPossible,
    required this.presentCount,
    required this.attendanceRate,
  });

  factory OverallPeriodStats.fromJson(Map<String, dynamic> json) {
    return OverallPeriodStats(
      eventCount: json['eventCount'],
      totalPossible: json['totalPossible'],
      presentCount: json['presentCount'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

class AttendanceByPeriod {
  final String period;
  final List<GroupStat> groupStats;
  final OverallPeriodStats overallStats;

  AttendanceByPeriod({
    required this.period,
    required this.groupStats,
    required this.overallStats,
  });

  factory AttendanceByPeriod.fromJson(Map<String, dynamic> json) {
    return AttendanceByPeriod(
      period: json['period'],
      groupStats: (json['groupStats'] as List)
          .map((item) => GroupStat.fromJson(item))
          .toList(),
      overallStats: OverallPeriodStats.fromJson(json['overallStats']),
    );
  }
}

// Group Dashboard Data
class GroupDashboardData {
  final String groupId;
  final String groupName;
  final int memberCount;
  final List<dynamic> recentEvents;
  final List<dynamic> upcomingEvents;
  final OverallAttendanceStats attendanceStats;
  final Map<String, dynamic> growthAnalytics;

  GroupDashboardData({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.recentEvents,
    required this.upcomingEvents,
    required this.attendanceStats,
    required this.growthAnalytics,
  });

  factory GroupDashboardData.fromJson(Map<String, dynamic> json) {
    return GroupDashboardData(
      groupId: json['groupId'],
      groupName: json['groupName'],
      memberCount: json['memberCount'],
      recentEvents: json['recentEvents'],
      upcomingEvents: json['upcomingEvents'],
      attendanceStats: OverallAttendanceStats.fromJson(json['attendanceStats']),
      growthAnalytics: json['growthAnalytics'],
    );
  }
}

// Region Demographics
class RegionDemographics {
  final List<DistributionItem> genderDistribution;

  RegionDemographics({
    required this.genderDistribution,
  });

  factory RegionDemographics.fromJson(Map<String, dynamic> json) {
    return RegionDemographics(
      genderDistribution: (json['genderDistribution'] as List)
          .map((item) => DistributionItem.fromJson(item))
          .toList(),
    );
  }
}

// Region Attendance Stats
class RegionAttendanceStats {
  final List<EventAttendanceStat> eventStats;
  final OverallAttendanceStats overallStats;

  RegionAttendanceStats({
    required this.eventStats,
    required this.overallStats,
  });

  factory RegionAttendanceStats.fromJson(Map<String, dynamic> json) {
    return RegionAttendanceStats(
      eventStats: (json['eventStats'] as List)
          .map((item) => EventAttendanceStat.fromJson(item))
          .toList(),
      overallStats: OverallAttendanceStats.fromJson(json['overallStats']),
    );
  }
}

// Region Growth Analytics
class RegionGrowthAnalytics {
  final Map<String, int> monthlyGrowth;
  final List<CumulativeGrowthItem> cumulativeGrowth;

  RegionGrowthAnalytics({
    required this.monthlyGrowth,
    required this.cumulativeGrowth,
  });

  factory RegionGrowthAnalytics.fromJson(Map<String, dynamic> json) {
    // Convert monthlyGrowth from JSON to Map<String, int>
    final Map<String, int> monthlyGrowthMap = {};
    (json['monthlyGrowth'] as Map<String, dynamic>).forEach((key, value) {
      monthlyGrowthMap[key] = value as int;
    });

    return RegionGrowthAnalytics(
      monthlyGrowth: monthlyGrowthMap,
      cumulativeGrowth: (json['cumulativeGrowth'] as List)
          .map((item) => CumulativeGrowthItem.fromJson(item))
          .toList(),
    );
  }
}

// Attendance By Period Stats
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
      date: json['date'],
      events: json['events'],
      totalPossible: json['totalPossible'],
      presentCount: json['presentCount'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}

class AttendanceByPeriodStats {
  final List<EventAttendanceComparison> eventStats;
  final List<DailyAttendanceStat> dailyStats;

  AttendanceByPeriodStats({
    required this.eventStats,
    required this.dailyStats,
  });

  factory AttendanceByPeriodStats.fromJson(Map<String, dynamic> json) {
    return AttendanceByPeriodStats(
      eventStats: (json['eventStats'] as List)
          .map((item) => EventAttendanceComparison.fromJson(item))
          .toList(),
      dailyStats: (json['dailyStats'] as List)
          .map((item) => DailyAttendanceStat.fromJson(item))
          .toList(),
    );
  }
}

// Dashboard Summary
class DashboardSummary {
  final int userCount;
  final int groupCount;
  final int eventCount;
  final int? attendanceCount;
  final List<dynamic> recentEvents;

  DashboardSummary({
    required this.userCount,
    required this.groupCount,
    required this.eventCount,
    this.attendanceCount,
    required this.recentEvents,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      userCount: json['userCount'] ?? 0,
      groupCount: json['groupCount'] ?? 0,
      eventCount: json['eventCount'] ?? 0,
      attendanceCount: json['attendanceCount'],
      recentEvents: json['recentEvents'] ?? [],
    );
  }
}

// Member Activity Status
class UserActivityStat {
  final String userId;
  final String userName;
  final String userEmail;
  final int totalPossibleEvents;
  final int attendedEvents;
  final double attendanceRate;
  final String activityStatus;
  final String activityThreshold;

  UserActivityStat({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.totalPossibleEvents,
    required this.attendedEvents,
    required this.attendanceRate,
    required this.activityStatus,
    required this.activityThreshold,
  });

  factory UserActivityStat.fromJson(Map<String, dynamic> json) {
    return UserActivityStat(
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      totalPossibleEvents: json['totalPossibleEvents'],
      attendedEvents: json['attendedEvents'],
      attendanceRate: json['attendanceRate'].toDouble(),
      activityStatus: json['activityStatus'],
      activityThreshold: json['activityThreshold'],
    );
  }
}

class StatusSummary {
  final int active;
  final int inactive;
  final int total;

  StatusSummary({
    required this.active,
    required this.inactive,
    required this.total,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      active: json['Active'],
      inactive: json['Inactive'],
      total: json['Total'],
    );
  }
}

class MemberActivityStatus {
  final List<UserActivityStat> userStats;
  final StatusSummary statusSummary;

  MemberActivityStatus({
    required this.userStats,
    required this.statusSummary,
  });

  factory MemberActivityStatus.fromJson(Map<String, dynamic> json) {
    return MemberActivityStatus(
      userStats: (json['userStats'] as List)
          .map((item) => UserActivityStat.fromJson(item))
          .toList(),
      statusSummary: StatusSummary.fromJson(json['statusSummary']),
    );
  }
}