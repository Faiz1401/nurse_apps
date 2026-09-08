import 'nurse.dart';

enum DocType { ic, qualification, apc, certificate, experienceLetter, photo, bankProof, other }

const _docTypeDbValues = {
  DocType.ic: 'ic',
  DocType.qualification: 'qualification',
  DocType.apc: 'apc',
  DocType.certificate: 'certificate',
  DocType.experienceLetter: 'experience_letter',
  DocType.photo: 'photo',
  DocType.bankProof: 'bank_proof',
  DocType.other: 'other',
};

const _docTypeLabels = {
  DocType.ic: 'IC / Passport',
  DocType.qualification: 'Nursing Qualification',
  DocType.apc: 'APC / Professional Registration',
  DocType.certificate: 'Certificate',
  DocType.experienceLetter: 'Experience Letter',
  DocType.photo: 'Profile Photo',
  DocType.bankProof: 'Bank Proof',
  DocType.other: 'Other',
};

String docTypeToDb(DocType type) => _docTypeDbValues[type]!;
String docTypeLabel(DocType type) => _docTypeLabels[type]!;

DocType docTypeFromDb(String value) {
  return _docTypeDbValues.entries.firstWhere((entry) => entry.value == value, orElse: () => const MapEntry(DocType.other, 'other')).key;
}

class NurseDocument {
  final String id;
  final String nurseId;
  final DocType docType;
  final String fileUrl;
  final VerificationStatus status;
  final DateTime? expiryDate;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? notes;
  final DateTime createdAt;

  const NurseDocument({
    required this.id,
    required this.nurseId,
    required this.docType,
    required this.fileUrl,
    required this.status,
    this.expiryDate,
    this.reviewedBy,
    this.reviewedAt,
    this.notes,
    required this.createdAt,
  });

  factory NurseDocument.fromMap(Map<String, dynamic> map) {
    return NurseDocument(
      id: map['id'] as String,
      nurseId: map['nurse_id'] as String,
      docType: docTypeFromDb(map['doc_type'] as String),
      fileUrl: map['file_url'] as String,
      status: verificationStatusFromString(map['status'] as String? ?? 'pending'),
      expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date'] as String) : null,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null ? DateTime.tryParse(map['reviewed_at'] as String) : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
