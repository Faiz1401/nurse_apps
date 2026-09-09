class NurseSkillRef {
  final String id;
  final String name;

  const NurseSkillRef({required this.id, required this.name});

  factory NurseSkillRef.fromMap(Map<String, dynamic> map) {
    return NurseSkillRef(id: map['id'] as String, name: map['name'] as String);
  }
}

class NurseServiceRef {
  final String id;
  final String name;
  final String categoryId;
  final double price;

  const NurseServiceRef({required this.id, required this.name, required this.categoryId, required this.price});

  factory NurseServiceRef.fromMap(Map<String, dynamic> map) {
    return NurseServiceRef(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['category_id'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }
}

class NurseSearchResult {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? gender;
  final String? qualification;
  final double experienceYears;
  final String? bio;
  final double ratingAvg;
  final int jobsCompleted;
  final bool isAvailable;
  final List<NurseSkillRef> skills;
  final List<NurseServiceRef> services;

  const NurseSearchResult({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.gender,
    this.qualification,
    required this.experienceYears,
    this.bio,
    required this.ratingAvg,
    required this.jobsCompleted,
    required this.isAvailable,
    required this.skills,
    required this.services,
  });

  factory NurseSearchResult.fromMap(Map<String, dynamic> map) {
    return NurseSearchResult(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      photoUrl: map['photo_url'] as String?,
      gender: map['gender'] as String?,
      qualification: map['qualification'] as String?,
      experienceYears: (map['experience_years'] as num?)?.toDouble() ?? 0,
      bio: map['bio'] as String?,
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 0,
      jobsCompleted: map['jobs_completed'] as int? ?? 0,
      isAvailable: map['is_available'] as bool? ?? true,
      skills: (map['skills'] as List<dynamic>? ?? [])
          .map((s) => NurseSkillRef.fromMap(s as Map<String, dynamic>))
          .toList(),
      services: (map['services'] as List<dynamic>? ?? [])
          .map((s) => NurseServiceRef.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  double? get minPrice => services.isEmpty ? null : services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
}
