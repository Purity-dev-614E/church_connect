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

  AttendanceModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        userId = json['user_Id'] ?? '',
        eventId = json['event_Id'] ?? '',
        isPresent = json['present'] == true,
        apology = json['apology'],
        topic = json['topic'],
        aob = json['aob'];

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
}