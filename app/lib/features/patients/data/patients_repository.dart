import '../../../core/supabase_client.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/models/patient.dart';

/// Wraps all `patients`/`emergency_contacts` Postgrest calls. RLS on the
/// server guarantees a client only ever sees their own (non-deleted)
/// patients — this repository doesn't need to filter by owner itself.
class PatientsRepository {
  Future<List<Patient>> listMyPatients() async {
    final rows = await supabase
        .from('patients')
        .select()
        .order('created_at', ascending: true);
    return rows.map((row) => Patient.fromMap(row)).toList();
  }

  Future<Patient> createPatient(Patient patient) async {
    final ownerId = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('patients')
        .insert(patient.toInsertMap(ownerId: ownerId))
        .select()
        .single();
    return Patient.fromMap(row);
  }

  Future<Patient> updatePatient(String patientId, Patient patient) async {
    final ownerId = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('patients')
        .update(patient.toInsertMap(ownerId: ownerId))
        .eq('id', patientId)
        .select()
        .single();
    return Patient.fromMap(row);
  }

  /// Soft-delete only — patients are never hard-deleted since bookings/visits
  /// may reference them (see docs/03-database-schema.sql).
  Future<void> archivePatient(String patientId) async {
    await supabase
        .from('patients')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', patientId);
  }

  Future<List<EmergencyContact>> listEmergencyContacts(String patientId) async {
    final rows = await supabase
        .from('emergency_contacts')
        .select()
        .eq('patient_id', patientId)
        .order('is_primary', ascending: false);
    return rows.map((row) => EmergencyContact.fromMap(row)).toList();
  }

  Future<EmergencyContact> addEmergencyContact(EmergencyContact contact) async {
    final row = await supabase
        .from('emergency_contacts')
        .insert(contact.toInsertMap(patientId: contact.patientId))
        .select()
        .single();
    return EmergencyContact.fromMap(row);
  }

  Future<void> deleteEmergencyContact(String id) async {
    await supabase.from('emergency_contacts').delete().eq('id', id);
  }
}
