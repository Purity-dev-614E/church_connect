// Analytics Models - These models represent the data structures returned by the analytics API

// ==================== GROUP ANALYTICS MODELS ====================

class GroupDemographics {
  final Map<String, int> ageDistribution;
  final Map<String, int> genderDistribution;
  final Map<String, int> locationDistribution;
  final Map<String, dynamic> additionalMetrics;

  GroupDemographics({
    required this.ageDistribution,
    required this.genderDistribution,
    required this.locationDistribution,
    required this.additionalMetrics,
  });

  factory GroupDemographics.fromJson(Map<String, dynamic> json) {
    return GroupDemographics(
      ageDistribution: Map<String, int>.from(json['ageDistribution'] ?? {}),
      genderDistribution: Map<String, int>.from(json['genderDistribution'] ?? {}),
      locationDistribution: Map<String, int>.from(json['locationDistribution'] ?? {}),
      additionalMetrics: json['additionalMetrics'] ?? {},
    );
  }
  
  // Add isEmpty property for compatibility with UI
  bool get isEmpty => ageDistribution.isEmpty && 
                      genderDistribution.isEmpty && 
                      locationDistribution.isEmpty;
}

class GroupAttendanceStats {
  final double averageAttendance;
  final List<Map<String, dynamic>> attendanceTrend;
  final Map<String, int> attendanceByDayOfWeek;
  final int totalSessions;
  final double growthRate;

  GroupAttendanceStats({
    required this.averageAttendance,
    required this.attendanceTrend,
    required this.attendanceByDayOfWeek,
    required this.totalSessions,
    required this.growthRate,
  });

  factory GroupAttendanceStats.fromJson(Map<String, dynamic> json) {
    return GroupAttendanceStats(
      averageAttendance: json['averageAttendance']?.toDouble() ?? 0.0,
      attendanceTrend: List<Map<String, dynamic>>.from(json['attendanceTrend'] ?? []),
      attendanceByDayOfWeek: Map<String, int>.from(json['attendanceByDayOfWeek'] ?? {}),
      totalSessions: json['totalSessions'] ?? 0,
      growthRate: json['growthRate']?.toDouble() ?? 0.0,
    );
  }
  
  // Add isEmpty property for compatibility with UI
  bool get isEmpty => attendanceTrend.isEmpty && 
                      attendanceByDayOfWeek.isEmpty && 
                      totalSessions == 0;
}

class GroupGrowthAnalytics {
  final List<Map<String, dynamic>> membershipGrowth;
  final double retentionRate;
  final double churnRate;
  final List<Map<String, dynamic>> newMembersByPeriod;
  final Map<String, dynamic> growthFactors;

  GroupGrowthAnalytics({
    required this.membershipGrowth,
    required this.retentionRate,
    required this.churnRate,
    required this.newMembersByPeriod,
    required this.growthFactors,
  });

  factory GroupGrowthAnalytics.fromJson(Map<String, dynamic> json) {
    return GroupGrowthAnalytics(
      membershipGrowth: List<Map<String, dynamic>>.from(json['membershipGrowth'] ?? []),
      retentionRate: json['retentionRate']?.toDouble() ?? 0.0,
      churnRate: json['churnRate']?.toDouble() ?? 0.0,
      newMembersByPeriod: List<Map<String, dynamic>>.from(json['newMembersByPeriod'] ?? []),
      growthFactors: json['growthFactors'] ?? {},
    );
  }
}

class GroupComparisonResult {
  final List<Map<String, dynamic>> comparisonData;
  final Map<String, List<dynamic>> metrics;
  final List<Map<String, dynamic>> growthComparison;
  final List<Map<String, dynamic>> attendanceComparison;

  GroupComparisonResult({
    required this.comparisonData,
    required this.metrics,
    required this.growthComparison,
    required this.attendanceComparison,
  });

  factory GroupComparisonResult.fromJson(Map<String, dynamic> json) {
    return GroupComparisonResult(
      comparisonData: List<Map<String, dynamic>>.from(json['comparisonData'] ?? []),
      metrics: Map<String, List<dynamic>>.from(json['metrics'] ?? {}),
      growthComparison: List<Map<String, dynamic>>.from(json['growthComparison'] ?? []),
      attendanceComparison: List<Map<String, dynamic>>.from(json['attendanceComparison'] ?? []),
    );
  }
}

// ==================== ATTENDANCE ANALYTICS MODELS ====================

class AttendanceData {
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> summary;
  final double averageAttendance;
  final Map<String, dynamic> trends;

  AttendanceData({
    required this.data,
    required this.summary,
    required this.averageAttendance,
    required this.trends,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      data: List<Map<String, dynamic>>.from(json['data'] ?? []),
      summary: json['summary'] ?? {},
      averageAttendance: json['averageAttendance']?.toDouble() ?? 0.0,
      trends: json['trends'] ?? {},
    );
  }
}

class OverallAttendanceData {
  final Map<String, dynamic> overallStats;
  final List<Map<String, dynamic>> trendData;
  final Map<String, int> attendanceByGroup;
  final Map<String, int> attendanceByEventType;

  OverallAttendanceData({
    required this.overallStats,
    required this.trendData,
    required this.attendanceByGroup,
    required this.attendanceByEventType,
  });

  factory OverallAttendanceData.fromJson(Map<String, dynamic> json) {
    return OverallAttendanceData(
      overallStats: json['overallStats'] ?? {},
      trendData: List<Map<String, dynamic>>.from(json['trendData'] ?? []),
      attendanceByGroup: Map<String, int>.from(json['attendanceByGroup'] ?? {}),
      attendanceByEventType: Map<String, int>.from(json['attendanceByEventType'] ?? {}),
    );
  }
}

class UserAttendanceTrends {
  final List<Map<String, dynamic>> attendanceHistory;
  final double attendanceRate;
  final int totalEventsAttended;
  final List<Map<String, dynamic>> attendanceByEventType;
  final Map<String, dynamic> attendanceByMonth;

  UserAttendanceTrends({
    required this.attendanceHistory,
    required this.attendanceRate,
    required this.totalEventsAttended,
    required this.attendanceByEventType,
    required this.attendanceByMonth,
  });

  factory UserAttendanceTrends.fromJson(Map<String, dynamic> json) {
    return UserAttendanceTrends(
      attendanceHistory: List<Map<String, dynamic>>.from(json['attendanceHistory'] ?? []),
      attendanceRate: json['attendanceRate']?.toDouble() ?? 0.0,
      totalEventsAttended: json['totalEventsAttended'] ?? 0,
      attendanceByEventType: List<Map<String, dynamic>>.from(json['attendanceByEventType'] ?? []),
      attendanceByMonth: json['attendanceByMonth'] ?? {},
    );
  }
}

// ==================== EVENT ANALYTICS MODELS ====================

class EventParticipationStats {
  final int totalParticipants;
  final double participationRate;
  final Map<String, int> participantDemographics;
  final List<Map<String, dynamic>> participationTrend;
  final Map<String, dynamic> feedback;

  EventParticipationStats({
    required this.totalParticipants,
    required this.participationRate,
    required this.participantDemographics,
    required this.participationTrend,
    required this.feedback,
  });

  factory EventParticipationStats.fromJson(Map<String, dynamic> json) {
    return EventParticipationStats(
      totalParticipants: json['totalParticipants'] ?? 0,
      participationRate: json['participationRate']?.toDouble() ?? 0.0,
      participantDemographics: Map<String, int>.from(json['participantDemographics'] ?? {}),
      participationTrend: List<Map<String, dynamic>>.from(json['participationTrend'] ?? []),
      feedback: json['feedback'] ?? {},
    );
  }
  
  // Add isEmpty property for compatibility with UI
  bool get isEmpty => participantDemographics.isEmpty && 
                      participationTrend.isEmpty && 
                      totalParticipants == 0;
}

class EventAttendanceComparison {
  final List<Map<String, dynamic>> comparisonData;
  final Map<String, List<dynamic>> metrics;
  final List<Map<String, dynamic>> participationComparison;
  final Map<String, dynamic> insights;

  EventAttendanceComparison({
    required this.comparisonData,
    required this.metrics,
    required this.participationComparison,
    required this.insights,
  });

  factory EventAttendanceComparison.fromJson(Map<String, dynamic> json) {
    return EventAttendanceComparison(
      comparisonData: List<Map<String, dynamic>>.from(json['comparisonData'] ?? []),
      metrics: Map<String, List<dynamic>>.from(json['metrics'] ?? {}),
      participationComparison: List<Map<String, dynamic>>.from(json['participationComparison'] ?? []),
      insights: json['insights'] ?? {},
    );
  }
}

// ==================== MEMBER ANALYTICS MODELS ====================

class MemberParticipationStats {
  final List<Map<String, dynamic>> topParticipants;
  final Map<String, dynamic> participationByDemographic;
  final List<Map<String, dynamic>> participationTrend;
  final Map<String, dynamic> engagementMetrics;

  MemberParticipationStats({
    required this.topParticipants,
    required this.participationByDemographic,
    required this.participationTrend,
    required this.engagementMetrics,
  });

  factory MemberParticipationStats.fromJson(Map<String, dynamic> json) {
    return MemberParticipationStats(
      topParticipants: List<Map<String, dynamic>>.from(json['topParticipants'] ?? []),
      participationByDemographic: json['participationByDemographic'] ?? {},
      participationTrend: List<Map<String, dynamic>>.from(json['participationTrend'] ?? []),
      engagementMetrics: json['engagementMetrics'] ?? {},
    );
  }
  
  // Add isEmpty property for compatibility with UI
  bool get isEmpty => topParticipants.isEmpty && 
                      participationByDemographic.isEmpty && 
                      participationTrend.isEmpty;
}

class MemberRetentionStats {
  final double overallRetentionRate;
  final List<Map<String, dynamic>> retentionByPeriod;
  final Map<String, double> retentionByDemographic;
  final List<Map<String, dynamic>> churnAnalysis;
  final Map<String, dynamic> retentionFactors;

  MemberRetentionStats({
    required this.overallRetentionRate,
    required this.retentionByPeriod,
    required this.retentionByDemographic,
    required this.churnAnalysis,
    required this.retentionFactors,
  });

  factory MemberRetentionStats.fromJson(Map<String, dynamic> json) {
    return MemberRetentionStats(
      overallRetentionRate: json['overallRetentionRate']?.toDouble() ?? 0.0,
      retentionByPeriod: List<Map<String, dynamic>>.from(json['retentionByPeriod'] ?? []),
      retentionByDemographic: Map<String, double>.from(json['retentionByDemographic'] ?? {}),
      churnAnalysis: List<Map<String, dynamic>>.from(json['churnAnalysis'] ?? []),
      retentionFactors: json['retentionFactors'] ?? {},
    );
  }
}

// ==================== DASHBOARD ANALYTICS MODELS ====================

class DashboardSummary {
  final int totalMembers;
  final int totalGroups;
  final int totalEvents;
  final double averageAttendance;
  final Map<String, dynamic> recentActivity;
  final Map<String, dynamic> keyMetrics;
  final List<Map<String, dynamic>> trendData;

  DashboardSummary({
    required this.totalMembers,
    required this.totalGroups,
    required this.totalEvents,
    required this.averageAttendance,
    required this.recentActivity,
    required this.keyMetrics,
    required this.trendData,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalMembers: json['totalMembers'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalEvents: json['totalEvents'] ?? 0,
      averageAttendance: json['averageAttendance']?.toDouble() ?? 0.0,
      recentActivity: json['recentActivity'] ?? {},
      keyMetrics: json['keyMetrics'] ?? {},
      trendData: List<Map<String, dynamic>>.from(json['trendData'] ?? []),
    );
  }
}

class GroupDashboardData {
  final Map<String, dynamic> groupInfo;
  final Map<String, dynamic> attendanceStats;
  final Map<String, dynamic> membershipStats;
  final List<Map<String, dynamic>> recentEvents;
  final Map<String, dynamic> growthMetrics;

  GroupDashboardData({
    required this.groupInfo,
    required this.attendanceStats,
    required this.membershipStats,
    required this.recentEvents,
    required this.growthMetrics,
  });

  factory GroupDashboardData.fromJson(Map<String, dynamic> json) {
    return GroupDashboardData(
      groupInfo: json['groupInfo'] ?? {},
      attendanceStats: json['attendanceStats'] ?? {},
      membershipStats: json['membershipStats'] ?? {},
      recentEvents: List<Map<String, dynamic>>.from(json['recentEvents'] ?? []),
      growthMetrics: json['growthMetrics'] ?? {},
    );
  }
}

// ==================== EXPORT ANALYTICS MODELS ====================

class ReportData {
  final String reportType;
  final String generatedDate;
  final Map<String, dynamic> reportMetadata;
  final List<Map<String, dynamic>> reportData;
  final String downloadUrl;

  ReportData({
    required this.reportType,
    required this.generatedDate,
    required this.reportMetadata,
    required this.reportData,
    required this.downloadUrl,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      reportType: json['reportType'] ?? '',
      generatedDate: json['generatedDate'] ?? '',
      reportMetadata: json['reportMetadata'] ?? {},
      reportData: List<Map<String, dynamic>>.from(json['reportData'] ?? []),
      downloadUrl: json['downloadUrl'] ?? '',
    );
  }
}