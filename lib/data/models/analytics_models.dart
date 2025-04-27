// Base class for all analytics models
abstract class AnalyticsModel {
  Map<String, dynamic> toJson();
  
  // Factory constructor to create model from JSON
  factory AnalyticsModel.fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'dashboardSummary':
        return DashboardSummary.fromJson(json);
      case 'groupDemographics':
        return GroupDemographics.fromJson(json);
      case 'groupAttendance':
        return GroupAttendanceStats.fromJson(json);
      case 'groupGrowth':
        return GroupGrowthAnalytics.fromJson(json);
      case 'memberActivity':
        return MemberActivityStatus.fromJson(json);
      default:
        throw ArgumentError('Unknown analytics model type: $type');
    }
  }
}

// Dashboard Summary Model
class DashboardSummary implements AnalyticsModel {
  final int totalGroups;
  final int totalMembers;
  final int activeEvents;
  final double attendanceRate;
  final Map<String, dynamic> additionalData;

  DashboardSummary({
    required this.totalGroups,
    required this.totalMembers,
    required this.activeEvents,
    required this.attendanceRate,
    this.additionalData = const {},
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final totalGroups = json['totalGroups'] as int? ?? 0;
    final totalMembers = json['totalMembers'] as int? ?? 0;
    final activeEvents = json['activeEvents'] as int? ?? 0;
    final attendanceRate = (json['attendanceRate'] as num?)?.toDouble() ?? 0.0;
    
    // Extract any additional fields
    final additionalData = Map<String, dynamic>.from(json)
      ..remove('totalGroups')
      ..remove('totalMembers')
      ..remove('activeEvents')
      ..remove('attendanceRate');
    
    return DashboardSummary(
      totalGroups: totalGroups,
      totalMembers: totalMembers,
      activeEvents: activeEvents,
      attendanceRate: attendanceRate,
      additionalData: additionalData,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'totalGroups': totalGroups,
      'totalMembers': totalMembers,
      'activeEvents': activeEvents,
      'attendanceRate': attendanceRate,
      ...additionalData,
    };
  }
}

// Group Demographics Model
class GroupDemographics implements AnalyticsModel {
  final String groupId;
  final String groupName;
  final int totalMembers;
  final Map<String, int> ageDistribution;
  final Map<String, int> genderDistribution;
  final Map<String, dynamic> additionalData;

  GroupDemographics({
    required this.groupId,
    required this.groupName,
    required this.totalMembers,
    required this.ageDistribution,
    required this.genderDistribution,
    this.additionalData = const {},
  });

  factory GroupDemographics.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final groupId = json['groupId'] as String? ?? '';
    final groupName = json['groupName'] as String? ?? '';
    final totalMembers = json['totalMembers'] as int? ?? 0;
    
    // Extract distributions
    final ageDistribution = (json['ageDistribution'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, value as int),
    ) ?? {};
    
    final genderDistribution = (json['genderDistribution'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, value as int),
    ) ?? {};
    
    // Extract any additional fields
    final additionalData = Map<String, dynamic>.from(json)
      ..remove('groupId')
      ..remove('groupName')
      ..remove('totalMembers')
      ..remove('ageDistribution')
      ..remove('genderDistribution');
    
    return GroupDemographics(
      groupId: groupId,
      groupName: groupName,
      totalMembers: totalMembers,
      ageDistribution: ageDistribution,
      genderDistribution: genderDistribution,
      additionalData: additionalData,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'totalMembers': totalMembers,
      'ageDistribution': ageDistribution,
      'genderDistribution': genderDistribution,
      ...additionalData,
    };
  }
}

// Group Attendance Stats Model
class GroupAttendanceStats implements AnalyticsModel {
  final String groupId;
  final String groupName;
  final double averageAttendance;
  final List<Map<String, dynamic>> attendanceHistory;
  final Map<String, dynamic> additionalData;

  GroupAttendanceStats({
    required this.groupId,
    required this.groupName,
    required this.averageAttendance,
    required this.attendanceHistory,
    this.additionalData = const {},
  });

  factory GroupAttendanceStats.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final groupId = json['groupId'] as String? ?? '';
    final groupName = json['groupName'] as String? ?? '';
    final averageAttendance = (json['averageAttendance'] as num?)?.toDouble() ?? 0.0;
    
    // Extract attendance history
    final attendanceHistory = (json['attendanceHistory'] as List<dynamic>?)
        ?.map((item) => item as Map<String, dynamic>)
        .toList() ?? [];
    
    // Extract any additional fields
    final additionalData = Map<String, dynamic>.from(json)
      ..remove('groupId')
      ..remove('groupName')
      ..remove('averageAttendance')
      ..remove('attendanceHistory');
    
    return GroupAttendanceStats(
      groupId: groupId,
      groupName: groupName,
      averageAttendance: averageAttendance,
      attendanceHistory: attendanceHistory,
      additionalData: additionalData,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'averageAttendance': averageAttendance,
      'attendanceHistory': attendanceHistory,
      ...additionalData,
    };
  }
}

// Group Growth Analytics Model
class GroupGrowthAnalytics implements AnalyticsModel {
  final String groupId;
  final String groupName;
  final int initialMembers;
  final int currentMembers;
  final double growthRate;
  final List<Map<String, dynamic>> growthHistory;
  final Map<String, dynamic> additionalData;

  GroupGrowthAnalytics({
    required this.groupId,
    required this.groupName,
    required this.initialMembers,
    required this.currentMembers,
    required this.growthRate,
    required this.growthHistory,
    this.additionalData = const {},
  });

  factory GroupGrowthAnalytics.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final groupId = json['groupId'] as String? ?? '';
    final groupName = json['groupName'] as String? ?? '';
    final initialMembers = json['initialMembers'] as int? ?? 0;
    final currentMembers = json['currentMembers'] as int? ?? 0;
    final growthRate = (json['growthRate'] as num?)?.toDouble() ?? 0.0;
    
    // Extract growth history
    final growthHistory = (json['growthHistory'] as List<dynamic>?)
        ?.map((item) => item as Map<String, dynamic>)
        .toList() ?? [];
    
    // Extract any additional fields
    final additionalData = Map<String, dynamic>.from(json)
      ..remove('groupId')
      ..remove('groupName')
      ..remove('initialMembers')
      ..remove('currentMembers')
      ..remove('growthRate')
      ..remove('growthHistory');
    
    return GroupGrowthAnalytics(
      groupId: groupId,
      groupName: groupName,
      initialMembers: initialMembers,
      currentMembers: currentMembers,
      growthRate: growthRate,
      growthHistory: growthHistory,
      additionalData: additionalData,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'initialMembers': initialMembers,
      'currentMembers': currentMembers,
      'growthRate': growthRate,
      'growthHistory': growthHistory,
      ...additionalData,
    };
  }
}

// Member Activity Status Model
class MemberActivityStatus implements AnalyticsModel {
  final int active;
  final int inactive;
  final int newThisMonth;
  final Map<String, dynamic> activityBreakdown;
  final Map<String, dynamic> additionalData;

  MemberActivityStatus({
    required this.active,
    required this.inactive,
    required this.newThisMonth,
    required this.activityBreakdown,
    this.additionalData = const {},
  });

  factory MemberActivityStatus.fromJson(Map<String, dynamic> json) {
    // Extract known fields
    final active = json['active'] as int? ?? 0;
    final inactive = json['inactive'] as int? ?? 0;
    final newThisMonth = json['newThisMonth'] as int? ?? 0;
    
    // Extract activity breakdown
    final activityBreakdown = json['activityBreakdown'] as Map<String, dynamic>? ?? {};
    
    // Extract any additional fields
    final additionalData = Map<String, dynamic>.from(json)
      ..remove('active')
      ..remove('inactive')
      ..remove('newThisMonth')
      ..remove('activityBreakdown');
    
    return MemberActivityStatus(
      active: active,
      inactive: inactive,
      newThisMonth: newThisMonth,
      activityBreakdown: activityBreakdown,
      additionalData: additionalData,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'inactive': inactive,
      'newThisMonth': newThisMonth,
      'activityBreakdown': activityBreakdown,
      ...additionalData,
    };
  }
}