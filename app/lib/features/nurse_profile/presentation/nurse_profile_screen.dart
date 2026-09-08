import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse.dart';
import '../../../data/models/service.dart';
import '../../../data/models/skill.dart';
import '../../services_catalog/application/services_providers.dart';
import '../application/nurse_profile_providers.dart';

class NurseProfileScreen extends ConsumerStatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  ConsumerState<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends ConsumerState<NurseProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qualificationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountNoController;
  late final TextEditingController _bankAccountHolderController;
  bool _isAvailable = true;
  final Set<String> _selectedSkillIds = {};
  final Set<String> _selectedServiceIds = {};
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _qualificationController = TextEditingController();
    _experienceController = TextEditingController();
    _bioController = TextEditingController();
    _bankNameController = TextEditingController();
    _bankAccountNoController = TextEditingController();
    _bankAccountHolderController = TextEditingController();
  }

  @override
  void dispose() {
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _bankNameController.dispose();
    _bankAccountNoController.dispose();
    _bankAccountHolderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final repo = ref.read(nurseRepositoryProvider);
      await repo.saveMyNurseProfile(Nurse(
        id: '',
        qualification: _qualificationController.text.trim().isEmpty ? null : _qualificationController.text.trim(),
        experienceYears: double.tryParse(_experienceController.text.trim()) ?? 0,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        bankAccountNo:
            _bankAccountNoController.text.trim().isEmpty ? null : _bankAccountNoController.text.trim(),
        bankAccountHolder: _bankAccountHolderController.text.trim().isEmpty
            ? null
            : _bankAccountHolderController.text.trim(),
        verificationStatus: VerificationStatus.pending,
        ratingAvg: 0,
        jobsCompleted: 0,
        isAvailable: _isAvailable,
      ));
      await repo.setMySkills(_selectedSkillIds.toList());
      await repo.setMyServices(_selectedServiceIds.toList());
      ref.invalidate(myNurseProfileProvider);
      ref.invalidate(mySkillIdsProvider);
      ref.invalidate(myServiceIdsProvider);
      setState(() => _successMessage = 'Profile saved.');
    } catch (e) {
      setState(() => _errorMessage = 'Could not save profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurseAsync = ref.watch(myNurseProfileProvider);
    final skillsAsync = ref.watch(skillsProvider);
    final mySkillIdsAsync = ref.watch(mySkillIdsProvider);
    final servicesAsync = ref.watch(activeServicesProvider);
    final myServiceIdsAsync = ref.watch(myServiceIdsProvider);

    final loading = nurseAsync.isLoading ||
        skillsAsync.isLoading ||
        mySkillIdsAsync.isLoading ||
        servicesAsync.isLoading ||
        myServiceIdsAsync.isLoading;

    final error = nurseAsync.error ?? skillsAsync.error ?? servicesAsync.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Nurse Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Failed to load: $error'))
              : _buildForm(
                  context,
                  nurseAsync.value,
                  skillsAsync.value ?? [],
                  mySkillIdsAsync.value ?? [],
                  servicesAsync.value ?? [],
                  myServiceIdsAsync.value ?? [],
                ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    Nurse? nurse,
    List<Skill> skills,
    List<String> mySkillIds,
    List<Service> services,
    List<String> myServiceIds,
  ) {
    if (!_initialized) {
      _qualificationController.text = nurse?.qualification ?? '';
      _experienceController.text = nurse?.experienceYears.toString() ?? '0';
      _bioController.text = nurse?.bio ?? '';
      _bankNameController.text = nurse?.bankName ?? '';
      _bankAccountNoController.text = nurse?.bankAccountNo ?? '';
      _bankAccountHolderController.text = nurse?.bankAccountHolder ?? '';
      _isAvailable = nurse?.isAvailable ?? true;
      _selectedSkillIds.addAll(mySkillIds);
      _selectedServiceIds.addAll(myServiceIds);
      _initialized = true;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (nurse != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Verification: ${nurse.verificationStatus.name}'),
                    backgroundColor: _statusColor(nurse.verificationStatus),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Years of experience', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => (double.tryParse(value ?? '') == null) ? 'Enter a number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                title: const Text('Available for jobs'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 32),
              Text('Skills', style: Theme.of(context).textTheme.titleMedium),
              ...skills.map((skill) => CheckboxListTile(
                    value: _selectedSkillIds.contains(skill.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selectedSkillIds.add(skill.id);
                      } else {
                        _selectedSkillIds.remove(skill.id);
                      }
                    }),
                    title: Text(skill.name),
                    contentPadding: EdgeInsets.zero,
                  )),
              const Divider(height: 32),
              Text('Services you offer', style: Theme.of(context).textTheme.titleMedium),
              ...services.map((service) => CheckboxListTile(
                    value: _selectedServiceIds.contains(service.id),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selectedServiceIds.add(service.id);
                      } else {
                        _selectedServiceIds.remove(service.id);
                      }
                    }),
                    title: Text(service.name),
                    subtitle: Text('RM ${service.basePrice.toStringAsFixed(2)}'),
                    contentPadding: EdgeInsets.zero,
                  )),
              const Divider(height: 32),
              Text('Bank / payout information', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountNoController,
                decoration: const InputDecoration(labelText: 'Account number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountHolderController,
                decoration: const InputDecoration(labelText: 'Account holder name', border: OutlineInputBorder()),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                Text(_successMessage!, style: const TextStyle(color: Colors.green)),
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
                    : const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _statusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return Colors.green.shade100;
      case VerificationStatus.pending:
        return Colors.amber.shade100;
      case VerificationStatus.rejected:
      case VerificationStatus.suspended:
      case VerificationStatus.expired:
        return Colors.red.shade100;
    }
  }
}
