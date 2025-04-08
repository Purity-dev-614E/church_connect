class GroupModel{
  final String id;
  final String name;
  final String group_admin;

  GroupModel({
    required this.id,
    required this.name,
    required this.group_admin,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      group_admin: json['group_admin_id'] ?? '',
    );
  }
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'group_admin_id': group_admin,
    };
  }
}