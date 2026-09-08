class ServiceCategory {
  final String id;
  final String name;
  final String? description;

  const ServiceCategory({required this.id, required this.name, this.description});

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {'name': name, 'description': description};
  }
}
