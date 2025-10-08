class EventModel {
  String id;
  String title;
  String description;
  DateTime dateTime;
  String location;
  String groupId;
  String regionId;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.groupId,
    this.regionId = '',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date_time'] ?? json['date'];

    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: rawDate != null ? DateTime.parse(rawDate) : DateTime.now(),
      location: json['location'] ?? '',
      groupId: json['group_id'] ?? '',
      regionId: json['region_id'] ?? '',
    );
  }



  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date_time': dateTime.toUtc().toIso8601String(),
    'location': location,
    'group_id': groupId,
    'region_id': regionId,
  };
}
