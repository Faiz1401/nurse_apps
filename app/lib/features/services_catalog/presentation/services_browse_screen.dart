import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/service.dart';
import '../application/services_providers.dart';

/// Read-only catalog browse for clients/nurses. This is where the booking
/// wizard's "select service" step will plug in once the Booking module
/// exists — for now it just proves the catalog is populated and reachable.
class ServicesBrowseScreen extends ConsumerWidget {
  const ServicesBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(activeServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load services: $error')),
        data: (services) {
          if (services.isEmpty) {
            return const Center(child: Text('No services available yet.'));
          }
          final byCategory = <String, List<Service>>{};
          for (final service in services) {
            byCategory.putIfAbsent(service.categoryName ?? 'Other', () => []).add(service);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activeServicesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: byCategory.entries.expand((entry) sync* {
                yield Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                );
                for (final service in entry.value) {
                  yield Card(
                    child: ListTile(
                      title: Text(service.name),
                      subtitle: Text(
                        '${service.durationMinutes} min'
                        '${service.requiredSkillName != null ? ' • ${service.requiredSkillName}' : ''}'
                        '${service.description != null ? '\n${service.description}' : ''}',
                      ),
                      isThreeLine: service.description != null,
                      trailing: Text('RM ${service.basePrice.toStringAsFixed(2)}'),
                    ),
                  );
                }
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
