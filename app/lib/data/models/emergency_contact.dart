class EmergencyContact {
  final String id;
  final String patientId;
  final String name;
  final String? relationship;
  final String phone;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.patientId,
    required this.name,
    this.relationship,
    required this.phone,
    required this.isPrimary,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      name: map['name'] as String,
      relationship: map['relationship'] as String?,
      phone: map['phone'] as String,
      isPrimary: map['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap({required String patientId}) {
    return {
      'patient_id': patientId,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'is_primary': isPrimary,
    };
  }
}
