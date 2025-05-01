class RegionModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  RegionModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = false, // Default to true for backward compatibility
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}