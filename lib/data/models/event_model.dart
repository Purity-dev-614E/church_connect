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
      groupId: json['group_id'] ?? '',
      regionId: json['region_id'] ?? '',
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
  };
}
