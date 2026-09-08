import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse.dart';
import '../../../data/models/nurse_document.dart';
import '../application/nurse_verification_providers.dart';

const _requiredDocTypes = [
  DocType.ic,
  DocType.qualification,
  DocType.apc,
  DocType.certificate,
  DocType.experienceLetter,
  DocType.photo,
  DocType.bankProof,
];

class NurseDocumentsScreen extends ConsumerWidget {
  const NurseDocumentsScreen({super.key});

  NurseDocument? _latestFor(List<NurseDocument> docs, DocType type) {
    final matching = docs.where((doc) => doc.docType == type).toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matching.first;
  }

  Future<DateTime?> _askExpiryDate(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Expiry date (optional — cancel to skip)',
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref, DocType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) return;
    final extension = (picked.extension ?? 'bin').toLowerCase();

    if (!context.mounted) return;
    final expiryDate = await _askExpiryDate(context);

    try {
      await ref.read(nurseVerificationRepositoryProvider).uploadDocument(
            docType: type,
            bytes: bytes,
            fileExtension: extension,
            expiryDate: expiryDate,
          );
      ref.invalidate(myDocumentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Uploaded. Awaiting admin review.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(myDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Documents')),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Failed to load: $error')),
        data: (docs) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myDocumentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _requiredDocTypes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final type = _requiredDocTypes[index];
                final latest = _latestFor(docs, type);
                return Card(
                  child: ListTile(
                    title: Text(docTypeLabel(type)),
                    subtitle: latest == null
                        ? const Text('Not uploaded')
                        : Text(
                            'Status: ${latest.status.name}'
                            '${latest.notes != null && latest.status == VerificationStatus.rejected ? '\nReason: ${latest.notes}' : ''}',
                          ),
                    isThreeLine: latest?.notes != null && latest?.status == VerificationStatus.rejected,
                    leading: Icon(_statusIcon(latest?.status)),
                    trailing: FilledButton(
                      onPressed: () => _upload(context, ref, type),
                      child: Text(latest == null ? 'Upload' : 'Re-upload'),
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

  IconData _statusIcon(VerificationStatus? status) {
    switch (status) {
      case null:
        return Icons.upload_file_outlined;
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.pending:
        return Icons.hourglass_top;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.suspended:
      case VerificationStatus.expired:
        return Icons.warning;
    }
  }
}
