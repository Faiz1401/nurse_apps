class Skill {
  final String id;
  final String name;
  final String? category;

  const Skill({required this.id, required this.name, this.category});

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
    );
  }
}
