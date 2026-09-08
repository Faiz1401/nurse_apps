import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/patient.dart';
import '../application/patients_providers.dart';

/// Add/edit form for a single patient. Pass [existing] to edit; omit to create.
class PatientFormScreen extends ConsumerStatefulWidget {
  final Patient? existing;
  const PatientFormScreen({super.key, this.existing});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _icController;
  late final TextEditingController _addressController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _instructionsController;

  Relationship _relationship = Relationship.self;
  String? _gender;
  DateTime? _dob;
  MobilityStatus? _mobilityStatus;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.fullName ?? '');
    _icController = TextEditingController(text: existing?.icPassport ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _conditionsController = TextEditingController(text: existing?.medicalConditions ?? '');
    _allergiesController = TextEditingController(text: existing?.allergies ?? '');
    _instructionsController = TextEditingController(text: existing?.specialInstructions ?? '');
    _relationship = existing?.relationshipToOwner ?? Relationship.self;
    _gender = existing?.gender;
    _dob = existing?.dob;
    _mobilityStatus = existing?.mobilityStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _addressController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1970, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final patient = Patient(
      id: widget.existing?.id ?? '',
      ownerId: widget.existing?.ownerId ?? '',
      fullName: _nameController.text.trim(),
      icPassport: _icController.text.trim().isEmpty ? null : _icController.text.trim(),
      dob: _dob,
      gender: _gender,
      relationshipToOwner: _relationship,
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      medicalConditions: _conditionsController.text.trim().isEmpty ? null : _conditionsController.text.trim(),
      allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
      mobilityStatus: _mobilityStatus,
      specialInstructions:
          _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
    );

    try {
      final repo = ref.read(patientsRepositoryProvider);
      if (_isEditing) {
        await repo.updatePatient(widget.existing!.id, patient);
      } else {
        await repo.createPatient(patient);
      }
      ref.invalidate(myPatientsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save patient: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Patient' : 'Add Patient')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<Relationship>(
                  initialValue: _relationship,
                  decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                  items: Relationship.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(_relationshipLabel(r))))
                      .toList(),
                  onChanged: (value) => setState(() => _relationship = value ?? Relationship.self),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _icController,
                  decoration: const InputDecoration(labelText: 'IC / Passport', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of birth', border: OutlineInputBorder()),
                    child: Text(_dob == null
                        ? 'Select date'
                        : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const Divider(height: 32),
                Text('Health information', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conditionsController,
                  decoration:
                      const InputDecoration(labelText: 'Medical conditions', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(labelText: 'Allergies', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MobilityStatus>(
                  initialValue: _mobilityStatus,
                  decoration: const InputDecoration(labelText: 'Mobility status', border: OutlineInputBorder()),
                  items: MobilityStatus.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(_mobilityLabel(m))))
                      .toList(),
                  onChanged: (value) => setState(() => _mobilityStatus = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructionsController,
                  decoration:
                      const InputDecoration(labelText: 'Special instructions', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Add patient'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relationshipLabel(Relationship r) {
    switch (r) {
      case Relationship.self:
        return 'Myself';
      case Relationship.father:
        return 'Father';
      case Relationship.mother:
        return 'Mother';
      case Relationship.child:
        return 'Child';
      case Relationship.other:
        return 'Other family member';
    }
  }

  String _mobilityLabel(MobilityStatus m) {
    switch (m) {
      case MobilityStatus.independent:
        return 'Independent';
      case MobilityStatus.assisted:
        return 'Assisted';
      case MobilityStatus.wheelchair:
        return 'Wheelchair';
      case MobilityStatus.bedridden:
        return 'Bedridden';
    }
  }
}
