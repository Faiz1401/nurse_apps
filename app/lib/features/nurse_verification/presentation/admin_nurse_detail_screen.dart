import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/nurse.dart';
import '../../../data/models/nurse_document.dart';
import '../application/nurse_verification_providers.dart';

class AdminNurseDetailScreen extends ConsumerWidget {
  final Nurse nurse;
  final String nurseName;
  const AdminNurseDetailScreen({super.key, required this.nurse, required this.nurseName});

  Future<void> _viewFile(BuildContext context, WidgetRef ref, String path) async {
    try {
      final url = await ref.read(nurseVerificationRepositoryProvider).getSignedUrl(path);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open file: ${e.toString()}')));
      }
    }
  }

  Future<void> _reviewDocument(BuildContext context, WidgetRef ref, NurseDocument doc, VerificationStatus status) async {
    String? notes;
    if (status == VerificationStatus.rejected) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject document'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Reason (shown to the nurse)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
          ],
        ),
      );
      if (confirmed != true) return;
      notes = controller.text.trim().isEmpty ? null : controller.text.trim();
    }

    await ref.read(nurseVerificationRepositoryProvider).reviewDocument(
          documentId: doc.id,
          status: status,
          notes: notes,
        );
    ref.invalidate(nurseDocumentsProvider(nurse.id));
  }

  Future<void> _setOverallStatus(BuildContext context, WidgetRef ref, VerificationStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set nurse status to "${status.name}"?'),
        content: Text('$nurseName will be marked as ${status.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(nurseVerificationRepositoryProvider).setNurseVerificationStatus(nurse.id, status);
    ref.invalidate(allNursesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nurseName is now ${status.name}.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(nurseDocumentsProvider(nurse.id));

    return Scaffold(
      appBar: AppBar(title: Text(nurseName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Qualification: ${nurse.qualification ?? '—'}'),
                  Text('Experience: ${nurse.experienceYears} years'),
                  Text('Bio: ${nurse.bio ?? '—'}'),
                  const SizedBox(height: 8),
                  Text('Overall status: ${nurse.verificationStatus.name}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Documents', style: Theme.of(context).textTheme.titleMedium),
          docsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text('Failed to load documents: $error'),
            data: (docs) {
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No documents uploaded yet.'),
                );
              }
              return Column(
                children: docs
                    .map((doc) => Card(
                          child: ListTile(
                            title: Text(docTypeLabel(doc.docType)),
                            subtitle: Text(
                              'Status: ${doc.status.name}'
                              '${doc.expiryDate != null ? ' • Expires: ${doc.expiryDate!.year}-${doc.expiryDate!.month.toString().padLeft(2, '0')}-${doc.expiryDate!.day.toString().padLeft(2, '0')}' : ''}',
                            ),
                            onTap: () => _viewFile(context, ref, doc.fileUrl),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  onPressed: () =>
                                      _reviewDocument(context, ref, doc, VerificationStatus.approved),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  onPressed: () =>
                                      _reviewDocument(context, ref, doc, VerificationStatus.rejected),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          Text('Overall nurse status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _setOverallStatus(context, ref, VerificationStatus.approved),
                child: const Text('Approve'),
              ),
              OutlinedButton(
                onPressed: () => _setOverallStatus(context, ref, VerificationStatus.rejected),
                child: const Text('Reject'),
              ),
              OutlinedButton(
                onPressed: () => _setOverallStatus(context, ref, VerificationStatus.suspended),
                child: const Text('Suspend'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
