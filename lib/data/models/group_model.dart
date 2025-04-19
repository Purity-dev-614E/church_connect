class GroupModel{
  final String id;
  final String name;
  final String description;
  final String group_admin;
  final String? regionId;
  final String? regionName;
  final List<dynamic>? members;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.group_admin,
    this.regionId,
    this.regionName,
    this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      group_admin: json['group_admin_id'] ?? '',
      regionId: json['region_id'],
      regionName: json['region_name'],
      members: json['members'],
    );
  }
  
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'description': description,
      'group_admin_id': group_admin,
      'region_id': regionId,
    };
  }
}