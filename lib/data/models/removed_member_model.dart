import 'package:group_management_church_app/data/models/user_model.dart';

/// Represents a member who was removed from a group, with removal justification.
class RemovedMemberModel {
  final String id;
  final String userId;
  final String groupId;
  final String groupName;
  final String userName;
  final String userEmail;
  final String removedBy;
  final String removedByName;
  final DateTime removedAt;
  final String? reason;
  final bool isRestored;
  final DateTime? restoredAt;
  final String? restoredBy;

  RemovedMemberModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.groupName,
    required this.userName,
    required this.userEmail,
    required this.removedBy,
    required this.removedByName,
    required this.removedAt,
    this.reason,
    this.isRestored = false,
    this.restoredAt,
    this.restoredBy,
  });

  factory RemovedMemberModel.fromJson(Map<String, dynamic> json) {
    return RemovedMemberModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      removedBy: json['removed_by'] as String? ?? '',
      removedByName: json['removed_by_name'] as String? ?? '',
      removedAt:
          json['removed_at'] != null
              ? DateTime.parse(json['removed_at'] as String).toLocal()
              : DateTime.now(),
      reason: json['reason'] as String?,
      isRestored: json['is_restored'] as bool? ?? false,
      restoredAt:
          json['restored_at'] != null
              ? DateTime.parse(json['restored_at'] as String).toLocal()
              : null,
      restoredBy: json['restored_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'group_name': groupName,
      'user_name': userName,
      'user_email': userEmail,
      'removed_by': removedBy,
      'removed_by_name': removedByName,
      'removed_at': removedAt.toIso8601String(),
      'reason': reason,
      'is_restored': isRestored,
      'restored_at': restoredAt?.toIso8601String(),
      'restored_by': restoredBy,
    };
  }

  static String _str(dynamic v) => v?.toString() ?? '';
}

class RemovalStats {
  final int totalRemoved;
  final int activeRemovals;
  final int restoredMembers;
  final Map<String, int> removalsByMonth;
  final List<String> topRemovers;

  RemovalStats({
    required this.totalRemoved,
    required this.activeRemovals,
    required this.restoredMembers,
    required this.removalsByMonth,
    required this.topRemovers,
  });

  factory RemovalStats.fromJson(Map<String, dynamic> json) {
    return RemovalStats(
      totalRemoved: json['total_removed'] as int? ?? 0,
      activeRemovals: json['active_removals'] as int? ?? 0,
      restoredMembers: json['restored_members'] as int? ?? 0,
      removalsByMonth: Map<String, int>.from(
        (json['removals_by_month'] as Map?)?.map(
              (key, value) => MapEntry(key as String, value as int? ?? 0),
            ) ??
            <String, int>{},
      ),
      topRemovers: List<String>.from(json['top_removers'] as List? ?? []),
    );
  }
}

class RemovalRequest {
  final String userId;
  final String? reason;

  RemovalRequest({required this.userId, this.reason});

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'reason': reason};
  }
}
