import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/emergency_contact.dart';
import '../../../data/models/patient.dart';
import '../data/patients_repository.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) => PatientsRepository());

final myPatientsProvider = FutureProvider.autoDispose<List<Patient>>((ref) async {
  return ref.watch(patientsRepositoryProvider).listMyPatients();
});

final emergencyContactsProvider =
    FutureProvider.autoDispose.family<List<EmergencyContact>, String>((ref, patientId) async {
  return ref.watch(patientsRepositoryProvider).listEmergencyContacts(patientId);
});
