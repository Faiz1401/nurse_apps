import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse.dart';
import '../application/nurse_verification_providers.dart';
import 'admin_nurse_detail_screen.dart';

class AdminNurseVerificationScreen extends ConsumerWidget {
  const AdminNurseVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nursesAsync = ref.watch(allNursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nurse Verification')),
      body: nursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load nurses: $error')),
        data: (nurses) {
          if (nurses.isEmpty) {
            return const Center(child: Text('No nurses registered yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allNursesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: nurses.length,
              itemBuilder: (context, index) {
                final entry = nurses[index];
                return Card(
                  child: ListTile(
                    title: Text(entry.fullName),
                    subtitle: Text(entry.email ?? ''),
                    trailing: Chip(
                      label: Text(entry.nurse.verificationStatus.name),
                      backgroundColor: _statusColor(entry.nurse.verificationStatus),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdminNurseDetailScreen(nurse: entry.nurse, nurseName: entry.fullName)),
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
