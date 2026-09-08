import '../../../core/supabase_client.dart';
import '../../../data/models/profile.dart';

class ProfileRepository {
  Future<Profile> updateOwnProfile({
    required String fullName,
    String? icPassport,
    DateTime? dob,
    String? gender,
    String? phone,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'ic_passport': icPassport,
          'dob': dob?.toIso8601String().split('T').first,
          'gender': gender,
          'phone': phone,
          'address': address,
          'emergency_contact_name': emergencyContactName,
          'emergency_contact_phone': emergencyContactPhone,
        })
        .eq('id', userId)
        .select()
        .single();
    return Profile.fromMap(row);
  }
}
