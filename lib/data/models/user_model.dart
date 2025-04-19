class UserModel{
  final String id;
  final String fullName;
  final String email;
  final String contact;
  final String nextOfKin;
  final String nextOfKinContact;
  final String role;
  final String gender;
  final String? regionId;
  final String? regionName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.nextOfKin,
    required this.nextOfKinContact,
    required this.role,
    required this.gender,
    this.regionId,
    this.regionName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Normalize role to lowercase for consistent comparison
    String role = (json['role'] ?? 'user').toString().toLowerCase();
    
    // Map role values to expected format
    if (role == 'super_admin' || role == 'superadmin' || role == 'super admin') {
      role = 'super_admin';
    } else if (role == 'admin') {
      role = 'admin';
    } else if (role == 'region_manager') {
      role = 'region_manager';
    } else {
      // Default to 'user' for any other role
      role = 'user';
    }
    
    return UserModel(
      id: json['uid'] ?? '',
      fullName: json['full_name'] ?? '',
      contact: json['phone_number'] ?? '',
      nextOfKin: json['next_of_kin_name'] ?? '',
      nextOfKinContact: json['next_of_kin_contact'] ?? '',
      role: role,
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      regionId: json['region_id'],
      regionName: json['region_name'],
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
    };
  }
}