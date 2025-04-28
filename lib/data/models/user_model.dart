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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Get the user ID from various possible fields
    String userId = '';
    if (json['uid'] != null) {
      userId = json['uid'].toString();
    } else if (json['id'] != null) {
      userId = json['id'].toString();
    } else if (json['_id'] != null) {
      userId = json['_id'].toString();
    }

    // Normalize role to lowercase for consistent comparison
    String role = (json['role'] ?? 'user').toString().toLowerCase();

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
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      contact: json['phone_number'] ?? json['contact'] ?? '',
      nextOfKin: json['next_of_kin_name'] ?? json['nextOfKin'] ?? '',
      nextOfKinContact: json['next_of_kin_contact'] ?? json['nextOfKinContact'] ?? '',
      role: role,
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      regionId: json['region_id'] ?? json['regionId'] ?? '',
      regionName: json['location'] ?? json['regionName'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'],
      profileImageUrl: json['profile_picture'] ?? json['profile_picture'] ?? ''
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
    };
  }
}