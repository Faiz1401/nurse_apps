import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/service.dart';
import '../application/services_providers.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final Service? existing;
  const ServiceFormScreen({super.key, this.existing});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _qualificationController;
  String? _categoryId;
  String? _skillId;
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _durationController = TextEditingController(text: (existing?.durationMinutes ?? 60).toString());
    _priceController = TextEditingController(text: existing?.basePrice.toStringAsFixed(2) ?? '');
    _qualificationController = TextEditingController(text: existing?.requiredQualification ?? '');
    _categoryId = existing?.categoryId;
    _skillId = existing?.requiredSkillId;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final service = Service(
      id: widget.existing?.id ?? '',
      categoryId: _categoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      durationMinutes: int.tryParse(_durationController.text.trim()) ?? 60,
      basePrice: double.tryParse(_priceController.text.trim()) ?? 0,
      requiredSkillId: _skillId,
      requiredQualification:
          _qualificationController.text.trim().isEmpty ? null : _qualificationController.text.trim(),
      isActive: _isActive,
    );

    try {
      final repo = ref.read(servicesRepositoryProvider);
      if (_isEditing) {
        await repo.updateService(widget.existing!.id, service);
      } else {
        await repo.createService(service);
      }
      ref.invalidate(servicesProvider);
      ref.invalidate(activeServicesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save service: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Service' : 'Add Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('Failed to load categories: $error'),
                  data: (categories) => DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories
                        .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Service name', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration:
                            const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (int.tryParse(value ?? '') == null) ? 'Enter a number' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration:
                            const InputDecoration(labelText: 'Base price (RM)', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) =>
                            (double.tryParse(value ?? '') == null) ? 'Enter a number' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                skillsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('Failed to load skills: $error'),
                  data: (skills) => DropdownButtonFormField<String>(
                    initialValue: _skillId,
                    decoration:
                        const InputDecoration(labelText: 'Required skill (optional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('None')),
                      ...skills.map((skill) => DropdownMenuItem(value: skill.id, child: Text(skill.name))),
                    ],
                    onChanged: (value) => setState(() => _skillId = value),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                      labelText: 'Required qualification (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
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
                      : Text(_isEditing ? 'Save changes' : 'Add service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
