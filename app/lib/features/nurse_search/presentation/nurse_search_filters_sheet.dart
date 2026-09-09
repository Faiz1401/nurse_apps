import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services_catalog/application/services_providers.dart';
import '../application/nurse_search_providers.dart';

class NurseSearchFiltersSheet extends ConsumerWidget {
  const NurseSearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(nurseSearchFiltersProvider);
    final servicesAsync = ref.watch(activeServicesProvider);
    final skillsAsync = ref.watch(skillsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => ref.read(nurseSearchFiltersProvider.notifier).state =
                      const NurseSearchFilters(),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            servicesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('Failed to load services: $error'),
              data: (services) => DropdownButtonFormField<String>(
                initialValue: filters.serviceId,
                decoration: const InputDecoration(labelText: 'Service', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Any service')),
                  ...services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                    filters.copyWith(serviceId: value, clearServiceId: value == null),
              ),
            ),
            const SizedBox(height: 16),
            skillsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('Failed to load skills: $error'),
              data: (skills) => DropdownButtonFormField<String>(
                initialValue: filters.skillId,
                decoration: const InputDecoration(labelText: 'Skill', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Any skill')),
                  ...skills.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                    filters.copyWith(skillId: value, clearSkillId: value == null),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: filters.gender,
              decoration: const InputDecoration(labelText: 'Nurse gender', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem<String>(value: null, child: Text('Any')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                  filters.copyWith(gender: value, clearGender: value == null),
            ),
            const SizedBox(height: 8),
            Text('Minimum experience: ${filters.minExperience.toStringAsFixed(0)} years'),
            Slider(
              value: filters.minExperience,
              min: 0,
              max: 20,
              divisions: 20,
              label: filters.minExperience.toStringAsFixed(0),
              onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                  filters.copyWith(minExperience: value),
            ),
            Text('Minimum rating: ${filters.minRating.toStringAsFixed(1)}'),
            Slider(
              value: filters.minRating,
              min: 0,
              max: 5,
              divisions: 10,
              label: filters.minRating.toStringAsFixed(1),
              onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                  filters.copyWith(minRating: value),
            ),
            SwitchListTile(
              value: filters.availableOnly,
              onChanged: (value) => ref.read(nurseSearchFiltersProvider.notifier).state =
                  filters.copyWith(availableOnly: value),
              title: const Text('Available only'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Show results'),
            ),
          ],
        ),
      ),
    );
  }
}
