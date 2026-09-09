import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/nurse_availability_slot.dart';
import '../application/nurse_availability_providers.dart';

class WorkingHoursTab extends ConsumerWidget {
  const WorkingHoursTab({super.key});

  Future<void> _addSlot(BuildContext context, WidgetRef ref) async {
    int dayOfWeek = 1;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add working hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem(value: index, child: Text(weekdayLabels[index])),
                ),
                onChanged: (value) => setState(() => dayOfWeek = value ?? 1),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                trailing: Text(displayTimeOfDay(start)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: start);
                  if (picked != null) setState(() => start = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End time'),
                trailing: Text(displayTimeOfDay(end)),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: end);
                  if (picked != null) setState(() => end = picked);
                },
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
                try {
                  await ref
                      .read(nurseAvailabilityRepositoryProvider)
                      .addAvailabilitySlot(dayOfWeek: dayOfWeek, start: start, end: end);
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

    if (saved == true) ref.invalidate(myAvailabilityProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(myAvailabilityProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
        onPressed: () => _addSlot(context, ref),
      ),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
        data: (slots) {
          if (slots.isEmpty) {
            return const Center(child: Text('No working hours set yet.'));
          }
          final byDay = <int, List<NurseAvailabilitySlot>>{};
          for (final slot in slots) {
            byDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
          }
          final days = byDay.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: days.expand((day) sync* {
              yield Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(weekdayLabels[day], style: Theme.of(context).textTheme.titleMedium),
              );
              for (final slot in byDay[day]!) {
                yield Card(
                  child: ListTile(
                    title: Text('${displayTimeOfDay(slot.startTime)} – ${displayTimeOfDay(slot.endTime)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await ref.read(nurseAvailabilityRepositoryProvider).deleteAvailabilitySlot(slot.id);
                        ref.invalidate(myAvailabilityProvider);
                      },
                    ),
                  ),
                );
              }
            }).toList(),
          );
        },
      ),
    );
  }
}
