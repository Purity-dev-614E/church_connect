class UserModel{
  final String id;
  final String fullName;
  final String email;
  final String contact;
  final String nextOfKin;
  final String nextOfKinContact;
  final String role;
  final String gender;
  final String regionId;
  final String? regionName;
  final String? createdAt;
  final String? profileImageUrl;
  final String? age;
  final String? citam_Assembly;
  final String? if_Not;
  final String regionalID;
  final String? overalRegionName;
  final String? regionalTitle;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.nextOfKin,
    required this.nextOfKinContact,
    required this.role,
    required this.gender,
    required this.regionId,
    required this.regionalID,
    this.regionName,
    this.createdAt,
    this.profileImageUrl,
    this.age,
    this.citam_Assembly,
    this.if_Not,
    this.overalRegionName,
    this.regionalTitle,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? contact,
    String? nextOfKin,
    String? nextOfKinContact,
    String? role,
    String? gender,
    String? regionId,
    String? regionName,
    String? regionalID,
    String? createdAt,
    String? profileImageUrl,
    String? OveralRegionName,
    String? regionalTitle,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      nextOfKin: nextOfKin ?? this.nextOfKin,
      nextOfKinContact: nextOfKinContact ?? this.nextOfKinContact,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      regionalID: this.regionalID,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      overalRegionName: OveralRegionName ?? this.overalRegionName,
      regionalTitle: regionalTitle ?? this.regionalTitle,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert any value to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    // Get the user ID from various possible fields
    String userId = '';
    if (json['uid'] != null) {
      userId = safeToString(json['uid']);
    } else if (json['id'] != null) {
      userId = safeToString(json['id']);
    } else if (json['_id'] != null) {
      userId = safeToString(json['_id']);
    }

    // Normalize role strings and map aliases to canonical DB roles
    String role = safeToString(json['role'] ?? 'user').toLowerCase();
    if (role == 'super_admin' || role == 'superadmin' || role == 'super admin') {
      role = 'super_admin';
    } else if (role == 'regional_manager' || role == 'regionalmanager' || role == 'regional manager'
        || role == 'regional coordinator' || role == 'regional coordinator' || role == 'regional focal person') {
      role = 'regional manager';
    }

    return UserModel(
      id: userId,
      fullName: safeToString(json['full_name'] ?? json['fullName']),
      contact: safeToString(json['phone_number'] ?? json['contact']),
      nextOfKin: safeToString(json['next_of_kin_name'] ?? json['nextOfKin']),
      nextOfKinContact: safeToString(json['next_of_kin_contact'] ?? json['nextOfKinContact']),
      role: role,
      email: safeToString(json['email']),
      gender: safeToString(json['gender']),
      regionId: safeToString(json['group_id'] ?? json['groupId']),
      regionName: safeToString(json['location'] ?? json['regionName']),
      regionalID: safeToString(json['region_id'] ?? json['regionId']),
      createdAt: safeToString(json['created_at'] ?? json['createdAt']),
      profileImageUrl: safeToString(json['profile_picture'] ?? json['profileImageUrl']),
      age: safeToString(json['age']),
      citam_Assembly: safeToString(json['citam_assembly'] ?? json['citamAssembly']),
      if_Not: safeToString(json['if_not_member'] ?? json['ifNot']),
      overalRegionName: safeToString(json['region_name'] ?? json['overalRegionName']),
      regionalTitle: null,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'auth_id': id,
      'full_name': fullName,
      'phone_number': contact,
      'next_of_kin_name': nextOfKin,
      'next_of_kin_contact': nextOfKinContact,
      'role': role,
      'email': email,
      'gender': gender,
      'group_id': regionId,
      'region_id': regionalID,
      'location': regionName,
      'profile_picture': profileImageUrl,
      // 'created_at': createdAt,
      'age': age,
      'citam_assembly': citam_Assembly,
      'if_not_member': if_Not,
      'region_name': overalRegionName,
    };
  }
}