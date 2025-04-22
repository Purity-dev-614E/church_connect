class GroupModel{
  final String id;
  final String name;
  final String description;
  final String group_admin;
  final String? region_id;

  final List<dynamic>? members;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.group_admin,
    this.members,
    required this.region_id,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      group_admin: json['group_admin_id'] ?? '',
      region_id: json['region_id'],
      members: json['members'],
    );
  }
  
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'description': description,
      'group_admin_id': group_admin,
      'region_id': region_id,
    };
  }
}