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
  String? regionalId;
  String tag;
  String? targetAudience; // 'all', 'rc_only', 'regional'
  int? participantCount;
  int? invitedCount;
  DateTime? createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    this.groupId,
    this.regionalId,
    this.tag = 'org',
    this.targetAudience,
    this.participantCount,
    this.invitedCount,
    this.createdAt,
  });

  /// True if attendance marking is locked.
  /// - Before event start: Locked (cannot mark attendance before event begins)
  /// - During event: Unlocked (can mark attendance)
  /// - After 24 hours from event start: Locked (cannot modify attendance)
  /// - Leadership events: Only locked before start, never locked after
  bool get isAttendanceLocked {
    final now = DateTime.now();

    // Always locked before event starts (for all event types)
    if (now.isBefore(dateTime)) {
      return true;
    }

    // Leadership events are never locked after they start
    if (isLeadershipEvent) {
      return false;
    }

    // Regular events are locked after 24 hours from start
    return now.isAfter(dateTime.add(attendanceLockDuration));
  }

  bool get isLeadershipEvent => tag == 'leadership';
  bool get hasGroup => groupId != null;

  /// True if attendance can currently be marked (during the event window)
  bool get canMarkAttendance {
    final now = DateTime.now();

    // Cannot mark before event starts
    if (now.isBefore(dateTime)) {
      return false;
    }

    // Leadership events can always be marked after they start
    if (isLeadershipEvent) {
      return true;
    }

    // Regular events can be marked until 24 hours after start
    return !now.isAfter(dateTime.add(attendanceLockDuration));
  }

  /// Returns a user-friendly message about attendance availability
  String get attendanceStatusMessage {
    final now = DateTime.now();

    if (now.isBefore(dateTime)) {
      return 'Attendance will be available when the event starts.';
    } else if (isLeadershipEvent) {
      return 'Leadership event attendance is always open.';
    } else if (now.isAfter(dateTime.add(attendanceLockDuration))) {
      return 'Attendance closed 24 hours after event start.';
    } else {
      return 'Attendance is currently open.';
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date_time'] ?? json['date'];
    final rawCreatedAt = json['created_at'];

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

    // Parse createdAt
    DateTime? parsedCreatedAt;
    if (rawCreatedAt != null) {
      try {
        parsedCreatedAt = DateTime.parse(rawCreatedAt);
        if (parsedCreatedAt.isUtc) {
          parsedCreatedAt = parsedCreatedAt.toLocal();
        }
      } catch (_) {
        parsedCreatedAt = null;
      }
    }

    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: parsed,
      location: json['location'] ?? '',
      groupId: json['group_id'],
      regionalId: json['regional_id'],
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
      createdAt: parsedCreatedAt,
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
    'regional_id': regionalId,
    'tag': tag,
    'target_audience': targetAudience,
    'participant_count': participantCount,
    'invited_count': invitedCount,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}
