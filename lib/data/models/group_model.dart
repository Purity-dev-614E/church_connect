class GroupModel{
  final String id;
  final String name;
  final String description;
  final String group_admin;
  final String? region_id;
  final String created_at;

  final List<dynamic>? members;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.group_admin,
    this.members,
    required this.region_id,
    this.created_at = '',
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      group_admin: json['group_admin_id'] ?? '',
      region_id: json['region_id'],
      members: json['members'],
      created_at: json['created_at'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'description': description,
      'group_admin_id': group_admin,
      'region_id': region_id,
      'created_at': created_at,
    };
  }
}