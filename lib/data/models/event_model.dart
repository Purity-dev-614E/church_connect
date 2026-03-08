class EventModel {
  /// After this duration from [dateTime], attendance and event changes are locked.
  static const Duration attendanceLockDuration = Duration(hours: 24);

  /// Leadership events have a longer locking period (7 days) or can be unlocked
  static const Duration leadershipAttendanceLockDuration = Duration(days: 7);

  String id;
  String title;
  String description;
  DateTime dateTime;
  String location;
  String? groupId;
  String? regionId;
  String tag;
  String? targetAudience; // 'all', 'rc_only', 'regional'
  int? participantCount;
  int? invitedCount;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    this.groupId,
    this.regionId,
    this.tag = 'org',
    this.targetAudience,
    this.participantCount,
    this.invitedCount,
  });

  /// True if more than 24 hours have passed since the event start for regular events.
  /// Leadership events are never locked for attendance marking.
  bool get isAttendanceLocked {
    // Leadership events are never locked for attendance marking
    if (isLeadershipEvent) {
      return false;
    }

    return DateTime.now().isAfter(dateTime.add(attendanceLockDuration));
  }

  bool get isLeadershipEvent => tag == 'leadership';
  bool get hasGroup => groupId != null;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date_time'] ?? json['date'];

    // Parse as DateTime, then normalize to local if UTC
    DateTime parsed;
    if (rawDate != null) {
      try {
        parsed = DateTime.parse(rawDate);
        // If the parsed value is UTC, convert to local for app display/comparison
        if (parsed.isUtc) {
          parsed = parsed.toLocal();
        }
      } catch (_) {
        parsed = DateTime.now();
      }
    } else {
      parsed = DateTime.now();
    }

    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: parsed,
      location: json['location'] ?? '',
      groupId: json['group_id'],
      regionId: json['region_id'],
      tag: json['tag'] ?? 'org',
      targetAudience: json['target_audience'],
      participantCount:
          json['participant_count'] != null
              ? int.parse(json['participant_count'].toString())
              : null,
      invitedCount:
          json['invited_count'] != null
              ? int.parse(json['invited_count'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    // Store as UTC ISO to avoid ambiguity
    'date_time': dateTime.toUtc().toIso8601String(),
    'location': location,
    'group_id': groupId,
    'region_id': regionId,
    'tag': tag,
    'target_audience': targetAudience,
    'participant_count': participantCount,
    'invited_count': invitedCount,
  };
}
