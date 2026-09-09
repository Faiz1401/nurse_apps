import 'package:flutter/material.dart';

import '../../../data/models/nurse_search_result.dart';

/// Read-only nurse profile view. No booking action yet — that arrives with
/// the Booking module, where this becomes the "select this nurse" step.
class NurseDetailScreen extends StatelessWidget {
  final NurseSearchResult nurse;
  const NurseDetailScreen({super.key, required this.nurse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nurse.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              child: Text(nurse.fullName.isNotEmpty ? nurse.fullName[0] : '?', style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(nurse.fullName, style: Theme.of(context).textTheme.headlineSmall)),
          Center(child: Text(nurse.qualification ?? '', style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
                  label: Text(nurse.ratingAvg.toStringAsFixed(1)),
                ),
                Chip(label: Text('${nurse.experienceYears.toStringAsFixed(0)} yrs experience')),
                Chip(label: Text('${nurse.jobsCompleted} jobs completed')),
                Chip(
                  label: Text(nurse.isAvailable ? 'Available' : 'Unavailable'),
                  backgroundColor: nurse.isAvailable ? Colors.green.shade100 : Colors.grey.shade300,
                ),
              ],
            ),
          ),
          if (nurse.bio != null) ...[
            const Divider(height: 32),
            Text('Bio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(nurse.bio!),
          ],
          const Divider(height: 32),
          Text('Skills', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          nurse.skills.isEmpty
              ? const Text('No skills listed.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: nurse.skills.map((s) => Chip(label: Text(s.name))).toList(),
                ),
          const Divider(height: 32),
          Text('Services offered', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          nurse.services.isEmpty
              ? const Text('No services listed.')
              : Column(
                  children: nurse.services
                      .map((s) => Card(
                            child: ListTile(
                              title: Text(s.name),
                              trailing: Text('RM ${s.price.toStringAsFixed(2)}'),
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}
