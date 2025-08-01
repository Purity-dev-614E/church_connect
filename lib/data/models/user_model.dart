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
    this.regionName,
    this.createdAt,
    this.profileImageUrl,
    this.age,
    this.citam_Assembly,
    this.if_Not,
  });

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

    // Normalize role to lowercase for consistent comparison
    String role = safeToString(json['role'] ?? 'user').toLowerCase();

    // Map role values to expected format
    if (role == 'super_admin' || role == 'superadmin' || role == 'super admin') {
      role = 'super_admin';
    } else if (role == 'admin') {
      role = 'admin';
    } else if (role == 'regional_manager' || role == 'regionalmanager' || role == 'regional manager') {
      role = 'regional manager';
    } else {
      // Default to 'user' for any other role
      role = 'user';
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
      regionId: safeToString(json['region_id'] ?? json['regionId']),
      regionName: safeToString(json['location'] ?? json['regionName']),
      createdAt: safeToString(json['created_at'] ?? json['createdAt']),
      profileImageUrl: safeToString(json['profile_picture'] ?? json['profileImageUrl']),
      age: safeToString(json['age']),
      citam_Assembly: safeToString(json['citam_assembly'] ?? json['citamAssembly']),
      if_Not: safeToString(json['if_not_member'] ?? json['ifNot']),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'uid': id,
      'full_name': fullName,
      'phone_number': contact,
      'next_of_kin_name': nextOfKin,
      'next_of_kin_contact': nextOfKinContact,
      'role': role,
      'email': email,
      'gender': gender,
      'region_id': regionId,
      'location': regionName,
      'profile_picture': profileImageUrl,
      'created_at': createdAt,
      'age': age,
      'citam_assembly': citam_Assembly,
      'if_not_member': if_Not,
    };
  }
}