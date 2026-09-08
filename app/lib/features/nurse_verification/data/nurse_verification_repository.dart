import 'dart:typed_data';

import '../../../core/supabase_client.dart';
import '../../../data/models/nurse.dart';
import '../../../data/models/nurse_document.dart';
import '../../../data/models/nurse_with_profile.dart';

const _bucket = 'nurse-documents';

class NurseVerificationRepository {
  Future<List<NurseDocument>> listMyDocuments() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('nurse_documents')
        .select()
        .eq('nurse_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => NurseDocument.fromMap(row)).toList();
  }

  Future<List<NurseDocument>> listDocumentsForNurse(String nurseId) async {
    final rows = await supabase
        .from('nurse_documents')
        .select()
        .eq('nurse_id', nurseId)
        .order('created_at', ascending: false);
    return rows.map((row) => NurseDocument.fromMap(row)).toList();
  }

  /// Uploads the file to the private `nurse-documents` bucket under
  /// `{nurseId}/{docType}_{timestamp}.{ext}`, then records it. Status always
  /// lands on 'pending' — enforced server-side by a trigger regardless of
  /// what this inserts.
  Future<NurseDocument> uploadDocument({
    required DocType docType,
    required Uint8List bytes,
    required String fileExtension,
    DateTime? expiryDate,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${docTypeToDb(docType)}_$timestamp.$fileExtension';

    await supabase.storage.from(_bucket).uploadBinary(path, bytes);

    final row = await supabase
        .from('nurse_documents')
        .insert({
          'nurse_id': userId,
          'doc_type': docTypeToDb(docType),
          'file_url': path,
          'expiry_date': expiryDate?.toIso8601String().split('T').first,
        })
        .select()
        .single();
    return NurseDocument.fromMap(row);
  }

  Future<String> getSignedUrl(String path) async {
    return supabase.storage.from(_bucket).createSignedUrl(path, 60 * 10);
  }

  Future<List<NurseWithProfile>> listAllNurses() async {
    final rows = await supabase
        .from('nurses')
        .select('*, profiles(full_name, email)')
        .order('created_at', ascending: false);
    return rows.map((row) => NurseWithProfile.fromMap(row)).toList();
  }

  Future<void> reviewDocument({
    required String documentId,
    required VerificationStatus status,
    String? notes,
  }) async {
    final adminId = supabase.auth.currentUser!.id;
    await supabase.from('nurse_documents').update({
      'status': status.name,
      'reviewed_by': adminId,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'notes': notes,
    }).eq('id', documentId);
  }

  Future<void> setNurseVerificationStatus(String nurseId, VerificationStatus status) async {
    await supabase.from('nurses').update({'verification_status': status.name}).eq('id', nurseId);
  }
}
