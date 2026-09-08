import '../../../core/supabase_client.dart';
import '../../../data/models/nurse.dart';

class NurseRepository {
  Future<Nurse?> fetchMyNurseProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('nurses').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Nurse.fromMap(row);
  }

  Future<Nurse> saveMyNurseProfile(Nurse nurse) async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('nurses').upsert(nurse.toUpsertMap(id: userId)).select().single();
    return Nurse.fromMap(row);
  }

  Future<List<String>> listMySkillIds() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase.from('nurse_skills').select('skill_id').eq('nurse_id', userId);
    return rows.map((row) => row['skill_id'] as String).toList();
  }

  Future<void> setMySkills(List<String> skillIds) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('nurse_skills').delete().eq('nurse_id', userId);
    if (skillIds.isEmpty) return;
    await supabase.from('nurse_skills').insert(
          skillIds.map((skillId) => {'nurse_id': userId, 'skill_id': skillId}).toList(),
        );
  }

  Future<List<String>> listMyServiceIds() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase.from('nurse_services').select('service_id').eq('nurse_id', userId);
    return rows.map((row) => row['service_id'] as String).toList();
  }

  Future<void> setMyServices(List<String> serviceIds) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('nurse_services').delete().eq('nurse_id', userId);
    if (serviceIds.isEmpty) return;
    await supabase.from('nurse_services').insert(
          serviceIds.map((serviceId) => {'nurse_id': userId, 'service_id': serviceId}).toList(),
        );
  }
}
