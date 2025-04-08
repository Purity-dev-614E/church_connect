class UserGroups{
  final String id;
  final String user_id;
  final String group_id;
  final String role;

  UserGroups({
    required this.id,
    required this.user_id,
    required this.group_id,
    required this.role,
  });

  factory UserGroups.fromJson(Map<String, dynamic> json) {
    return UserGroups(
      id: json['id'],
      user_id: json['user_id'],
      group_id: json['group_id'],
      role: json['role'],
    );
  }
  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'user_id': user_id,
      'group_id': group_id,
      'role': role,
    };
  }
}