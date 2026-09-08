import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _icController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  String? _gender;
  DateTime? _dob;
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _icController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
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
      _successMessage = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateOwnProfile(
            fullName: _nameController.text.trim(),
            icPassport: _icController.text.trim().isEmpty ? null : _icController.text.trim(),
            dob: _dob,
            gender: _gender,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            emergencyContactName:
                _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
            emergencyContactPhone:
                _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
          );
      ref.invalidate(currentProfileProvider);
      setState(() => _successMessage = 'Profile updated.');
    } catch (e) {
      setState(() => _errorMessage = 'Could not save profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load profile: $error')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile found.'));

          if (!_initialized) {
            _nameController.text = profile.fullName;
            _icController.text = profile.icPassport ?? '';
            _phoneController.text = profile.phone ?? '';
            _addressController.text = profile.address ?? '';
            _emergencyNameController.text = profile.emergencyContactName ?? '';
            _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
            _gender = profile.gender;
            _dob = profile.dob;
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
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        child: Text(profile.fullName.isNotEmpty ? profile.fullName[0] : '?',
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: Text(profile.email ?? '', style: Theme.of(context).textTheme.bodyMedium)),
                    Center(child: Text('Role: ${profile.role.name}', style: const TextStyle(color: Colors.grey))),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _icController,
                      decoration:
                          const InputDecoration(labelText: 'IC / Passport', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Date of birth', border: OutlineInputBorder()),
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
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const Divider(height: 32),
                    Text('Emergency contact', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emergencyNameController,
                      decoration: const InputDecoration(labelText: 'Contact name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyPhoneController,
                      decoration:
                          const InputDecoration(labelText: 'Contact phone', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
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
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
