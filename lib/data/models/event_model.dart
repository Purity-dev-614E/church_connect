class EventModel {
  String id;
  String title;
  String description;
  DateTime dateTime;
  String location;
  String groupId;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.groupId
  });

  EventModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? '',
        title = json['title'] ?? '',
        description = json['description'] ?? '',
        dateTime = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        location = json['location'] ?? '',
        groupId = json['group_id'] ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date_time': dateTime.toIso8601String(),
        'location': location,
        'group_id': groupId,
      };

}