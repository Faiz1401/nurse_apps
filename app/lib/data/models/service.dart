class Service {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final int durationMinutes;
  final double basePrice;
  final String? requiredSkillId;
  final String? requiredSkillName;
  final String? requiredQualification;
  final bool isActive;

  const Service({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    required this.durationMinutes,
    required this.basePrice,
    this.requiredSkillId,
    this.requiredSkillName,
    this.requiredQualification,
    required this.isActive,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      categoryName: (map['service_categories'] as Map<String, dynamic>?)?['name'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 60,
      basePrice: (map['base_price'] as num).toDouble(),
      requiredSkillId: map['required_skill_id'] as String?,
      requiredSkillName: (map['skills'] as Map<String, dynamic>?)?['name'] as String?,
      requiredQualification: map['required_qualification'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
      'base_price': basePrice,
      'required_skill_id': requiredSkillId,
      'required_qualification': requiredQualification,
      'is_active': isActive,
    };
  }
}
