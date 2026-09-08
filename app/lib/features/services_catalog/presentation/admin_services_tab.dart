import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/service.dart';
import '../application/services_providers.dart';
import 'service_form_screen.dart';

class AdminServicesTab extends ConsumerWidget {
  const AdminServicesTab({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Delete "${service.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(servicesRepositoryProvider).deleteService(service.id);
      ref.invalidate(servicesProvider);
      ref.invalidate(activeServicesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ServiceFormScreen()),
          );
          if (saved == true) ref.invalidate(servicesProvider);
        },
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load services: $error')),
        data: (services) {
          if (services.isEmpty) {
            return const Center(child: Text('No services yet. Add a category first, then a service.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text(
                    '${service.categoryName ?? ''} • ${service.durationMinutes} min • RM ${service.basePrice.toStringAsFixed(2)}'
                    '${service.isActive ? '' : ' • INACTIVE'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => ServiceFormScreen(existing: service)),
                          );
                          if (saved == true) ref.invalidate(servicesProvider);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _delete(context, ref, service),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
