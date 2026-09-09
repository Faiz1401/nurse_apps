import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/nurse_availability_providers.dart';

class TimeOffTab extends ConsumerWidget {
  const TimeOffTab({super.key});

  Future<void> _addTimeOff(BuildContext context, WidgetRef ref) async {
    DateTimeRange? range = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );
    final reasonController = TextEditingController();
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add time off'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dates'),
                trailing: Text(range == null
                    ? 'Select'
                    : '${range!.start.year}-${range!.start.month.toString().padLeft(2, '0')}-${range!.start.day.toString().padLeft(2, '0')} → ${range!.end.year}-${range!.end.month.toString().padLeft(2, '0')}-${range!.end.day.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: range,
                  );
                  if (picked != null) setState(() => range = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (range == null) {
                  setState(() => errorMessage = 'Select a date range');
                  return;
                }
                try {
                  await ref.read(nurseAvailabilityRepositoryProvider).addTimeOff(
                        startDate: range!.start,
                        endDate: range!.end,
                        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context, true);
                } on PostgrestException catch (e) {
                  setState(() => errorMessage = e.message);
                } catch (e) {
                  setState(() => errorMessage = e.toString());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) ref.invalidate(myTimeOffProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOffAsync = ref.watch(myTimeOffProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Time Off'),
        onPressed: () => _addTimeOff(context, ref),
      ),
      body: timeOffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No time off scheduled.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  title: Text(
                    '${entry.startDate.year}-${entry.startDate.month.toString().padLeft(2, '0')}-${entry.startDate.day.toString().padLeft(2, '0')} → ${entry.endDate.year}-${entry.endDate.month.toString().padLeft(2, '0')}-${entry.endDate.day.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text('${entry.reason ?? 'No reason given'} • ${entry.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await ref.read(nurseAvailabilityRepositoryProvider).deleteTimeOff(entry.id);
                      ref.invalidate(myTimeOffProvider);
                    },
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
