class AttendanceModel {
  String id;
  String userId;
  String eventId;
  bool isPresent;
  String? apology;
  String? topic;
  String? aob;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.isPresent,
    this.apology = '',
    this.topic = '',
    this.aob = ''
  });

  /// Creates an AttendanceModel from JSON data, handling different field names and formats
  AttendanceModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? json['attendance_id'] ?? json['_id'] ?? '',
        userId = json['user_Id'] ?? json['user_id'] ?? json['userId'] ?? json['member_id'] ?? '',
        eventId = json['event_Id'] ?? json['event_id'] ?? json['eventId'] ?? '',
        isPresent = json['present'] == true || json['isPresent'] == true || json['is_present'] == true || json['attendance'] == true,
        apology = json['apology'] ?? json['excuse'] ?? json['reason'] ?? '',
        topic = json['topic'] ?? json['discussion_topic'] ?? '',
        aob = json['aob'] ?? json['any_other_business'] ?? '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_Id': userId,
      'event_Id': eventId,
      'present': isPresent,
      'apology': apology,
      'topic': topic,
      'aob': aob,
    };
  }

  /// Creates an AttendanceModel from a map, safely handling different field types
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    // Extract ID with fallbacks
    String attendanceId = '';
    if (map.containsKey('id')) {
      attendanceId = map['id'].toString();
    } else if (map.containsKey('attendance_id')) {
      attendanceId = map['attendance_id'].toString();
    } else if (map.containsKey('_id')) {
      attendanceId = map['_id'].toString();
    }
    
    // Extract user ID with fallbacks
    String userIdValue = '';
    if (map.containsKey('user_id')) {
      userIdValue = map['user_id'].toString();
    } else if (map.containsKey('user_Id')) {
      userIdValue = map['user_Id'].toString();
    } else if (map.containsKey('userId')) {
      userIdValue = map['userId'].toString();
    } else if (map.containsKey('member_id')) {
      userIdValue = map['member_id'].toString();
    }
    
    // Extract event ID with fallbacks
    String eventIdValue = '';
    if (map.containsKey('event_id')) {
      eventIdValue = map['event_id'].toString();
    } else if (map.containsKey('event_Id')) {
      eventIdValue = map['event_Id'].toString();
    } else if (map.containsKey('eventId')) {
      eventIdValue = map['eventId'].toString();
    }
    
    // Extract presence status with fallbacks
    bool isPresentValue = false;
    if (map.containsKey('present')) {
      isPresentValue = map['present'] == true || map['present'] == 'true' || map['present'] == 1;
    } else if (map.containsKey('isPresent')) {
      isPresentValue = map['isPresent'] == true || map['isPresent'] == 'true' || map['isPresent'] == 1;
    } else if (map.containsKey('is_present')) {
      isPresentValue = map['is_present'] == true || map['is_present'] == 'true' || map['is_present'] == 1;
    } else if (map.containsKey('attendance')) {
      isPresentValue = map['attendance'] == true || map['attendance'] == 'true' || map['attendance'] == 1;
    }
    
    return AttendanceModel(
      id: attendanceId,
      userId: userIdValue,
      eventId: eventIdValue,
      isPresent: isPresentValue,
      topic: map['topic']?.toString() ?? map['discussion_topic']?.toString(),
      aob: map['aob']?.toString() ?? map['any_other_business']?.toString(),
      apology: map['apology']?.toString() ?? map['excuse']?.toString() ?? map['reason']?.toString(),
    );
  }
}