enum VerificationStatus { pending, approved, rejected, suspended, expired }

VerificationStatus verificationStatusFromString(String value) {
  return VerificationStatus.values.firstWhere(
    (v) => v.name == value,
    orElse: () => VerificationStatus.pending,
  );
}

class Nurse {
  final String id;
  final String? qualification;
  final double experienceYears;
  final String? bio;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankAccountHolder;
  final VerificationStatus verificationStatus;
  final double ratingAvg;
  final int jobsCompleted;
  final bool isAvailable;

  const Nurse({
    required this.id,
    this.qualification,
    required this.experienceYears,
    this.bio,
    this.bankName,
    this.bankAccountNo,
    this.bankAccountHolder,
    required this.verificationStatus,
    required this.ratingAvg,
    required this.jobsCompleted,
    required this.isAvailable,
  });

  factory Nurse.fromMap(Map<String, dynamic> map) {
    return Nurse(
      id: map['id'] as String,
      qualification: map['qualification'] as String?,
      experienceYears: (map['experience_years'] as num?)?.toDouble() ?? 0,
      bio: map['bio'] as String?,
      bankName: map['bank_name'] as String?,
      bankAccountNo: map['bank_account_no'] as String?,
      bankAccountHolder: map['bank_account_holder'] as String?,
      verificationStatus: verificationStatusFromString(map['verification_status'] as String? ?? 'pending'),
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      jobsCompleted: map['jobs_completed'] as int? ?? 0,
      isAvailable: map['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toUpsertMap({required String id}) {
    return {
      'id': id,
      'qualification': qualification,
      'experience_years': experienceYears,
      'bio': bio,
      'bank_name': bankName,
      'bank_account_no': bankAccountNo,
      'bank_account_holder': bankAccountHolder,
      'is_available': isAvailable,
    };
  }
}
