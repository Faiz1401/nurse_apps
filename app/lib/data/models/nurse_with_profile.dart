import 'nurse.dart';

/// Admin-list convenience model: a nurse row joined with its profile's
/// display fields (name/email), since `nurses` itself carries no name.
class NurseWithProfile {
  final Nurse nurse;
  final String fullName;
  final String? email;

  const NurseWithProfile({required this.nurse, required this.fullName, this.email});

  factory NurseWithProfile.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return NurseWithProfile(
      nurse: Nurse.fromMap(map),
      fullName: profile?['full_name'] as String? ?? 'Unknown',
      email: profile?['email'] as String?,
    );
  }
}
