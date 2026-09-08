import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/emergency_contact.dart';
import '../../../data/models/patient.dart';
import '../application/patients_providers.dart';
import 'patient_form_screen.dart';

class PatientDetailScreen extends ConsumerWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(myPatientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient')),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
        data: (patients) {
          Patient? patient;
          for (final p in patients) {
            if (p.id == patientId) {
              patient = p;
              break;
            }
          }
          if (patient == null) {
            return const Center(child: Text('Patient not found.'));
          }
          return _PatientDetailBody(patient: patient);
        },
      ),
    );
  }
}

class _PatientDetailBody extends ConsumerWidget {
  final Patient patient;
  const _PatientDetailBody({required this.patient});

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove patient?'),
        content: Text('This hides ${patient.fullName} from your list. Booking/visit history is preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(patientsRepositoryProvider).archivePatient(patient.id);
    ref.invalidate(myPatientsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _addEmergencyContact(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    bool isPrimary = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add emergency contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(labelText: 'Relationship')),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              CheckboxListTile(
                value: isPrimary,
                onChanged: (value) => setState(() => isPrimary = value ?? false),
                title: const Text('Primary contact'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (saved != true || nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;

    await ref.read(patientsRepositoryProvider).addEmergencyContact(
          EmergencyContact(
            id: '',
            patientId: patient.id,
            name: nameController.text.trim(),
            relationship:
                relationshipController.text.trim().isEmpty ? null : relationshipController.text.trim(),
            phone: phoneController.text.trim(),
            isPrimary: isPrimary,
          ),
        );
    ref.invalidate(emergencyContactsProvider(patient.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider(patient.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(patient.fullName, style: Theme.of(context).textTheme.headlineSmall),
        Text(patient.relationshipToOwner.name, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'IC / Passport', value: patient.icPassport),
                _InfoRow(
                    label: 'Date of birth',
                    value: patient.dob != null
                        ? '${patient.dob!.year}-${patient.dob!.month.toString().padLeft(2, '0')}-${patient.dob!.day.toString().padLeft(2, '0')}'
                        : null),
                _InfoRow(label: 'Gender', value: patient.gender),
                _InfoRow(label: 'Address', value: patient.address),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health information', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _InfoRow(label: 'Medical conditions', value: patient.medicalConditions),
                _InfoRow(label: 'Allergies', value: patient.allergies),
                _InfoRow(label: 'Mobility', value: patient.mobilityStatus?.name),
                _InfoRow(label: 'Special instructions', value: patient.specialInstructions),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Emergency contacts', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addEmergencyContact(context, ref),
            ),
          ],
        ),
        contactsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text('Failed to load contacts: $error'),
          data: (contacts) {
            if (contacts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No emergency contacts added yet.'),
              );
            }
            return Column(
              children: contacts
                  .map((contact) => Card(
                        child: ListTile(
                          title: Text(contact.name),
                          subtitle: Text('${contact.relationship ?? ''} • ${contact.phone}'),
                          trailing: contact.isPrimary ? const Chip(label: Text('Primary')) : null,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Edit patient'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PatientFormScreen(existing: patient)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Remove patient', style: TextStyle(color: Colors.red)),
          onPressed: () => _archive(context, ref),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : '—')),
        ],
      ),
    );
  }
}
