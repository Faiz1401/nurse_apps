import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/patients_providers.dart';
import 'patient_detail_screen.dart';
import 'patient_form_screen.dart';

class PatientsListScreen extends ConsumerWidget {
  const PatientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(myPatientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Patients')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Patient'),
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const PatientFormScreen()),
          );
          if (saved == true) ref.invalidate(myPatientsProvider);
        },
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load patients: $error')),
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No patients yet. Tap "Add Patient" to add yourself or a family member.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPatientsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(patient.fullName.isNotEmpty ? patient.fullName[0] : '?')),
                    title: Text(patient.fullName),
                    subtitle: Text(patient.relationshipToOwner.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.id)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
