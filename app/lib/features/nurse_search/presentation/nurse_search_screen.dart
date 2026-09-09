import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/nurse_search_providers.dart';
import 'nurse_detail_screen.dart';
import 'nurse_search_filters_sheet.dart';

class NurseSearchScreen extends ConsumerWidget {
  const NurseSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(filteredNursesProvider);
    final filters = ref.watch(nurseSearchFiltersProvider);
    final hasActiveFilters = filters.serviceId != null ||
        filters.skillId != null ||
        filters.gender != null ||
        filters.minExperience > 0 ||
        filters.minRating > 0 ||
        filters.availableOnly;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nurses'),
        actions: [
          IconButton(
            icon: Icon(hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const NurseSearchFiltersSheet(),
            ),
          ),
        ],
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load nurses: $error')),
        data: (nurses) {
          if (nurses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No nurses match these filters.', textAlign: TextAlign.center),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(browseNursesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: nurses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final nurse = nurses[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(nurse.fullName.isNotEmpty ? nurse.fullName[0] : '?')),
                    title: Text(nurse.fullName),
                    subtitle: Text(
                      '${nurse.qualification ?? ''} • ${nurse.experienceYears.toStringAsFixed(0)} yrs'
                      '${nurse.minPrice != null ? ' • from RM ${nurse.minPrice!.toStringAsFixed(2)}' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            Text(nurse.ratingAvg.toStringAsFixed(1)),
                          ],
                        ),
                        if (!nurse.isAvailable)
                          const Text('Unavailable', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NurseDetailScreen(nurse: nurse)),
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
