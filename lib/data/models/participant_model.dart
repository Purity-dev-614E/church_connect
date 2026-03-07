class Participant {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? regionId;

  Participant({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.regionId,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      regionId: json['region_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'region_id': regionId,
  };
}
