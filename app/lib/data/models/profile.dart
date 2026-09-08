enum UserRole { patient, family, nurse, admin, superAdmin }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'family':
      return UserRole.family;
    case 'nurse':
      return UserRole.nurse;
    case 'admin':
      return UserRole.admin;
    case 'super_admin':
      return UserRole.superAdmin;
    case 'patient':
    default:
      return UserRole.patient;
  }
}

class Profile {
  final String id;
  final UserRole role;
  final String fullName;
  final String? icPassport;
  final DateTime? dob;
  final String? gender;
  final String? email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isActive;

  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    this.icPassport,
    this.dob,
    this.gender,
    this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.isActive,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      role: userRoleFromString(map['role'] as String),
      fullName: map['full_name'] as String? ?? '',
      icPassport: map['ic_passport'] as String?,
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      gender: map['gender'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      photoUrl: map['photo_url'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
