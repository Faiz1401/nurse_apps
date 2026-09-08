enum Relationship { self, father, mother, child, other }

Relationship relationshipFromString(String value) {
  return Relationship.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Relationship.other,
  );
}

enum MobilityStatus { independent, assisted, wheelchair, bedridden }

MobilityStatus? mobilityStatusFromString(String? value) {
  if (value == null) return null;
  return MobilityStatus.values.firstWhere(
    (m) => m.name == value,
    orElse: () => MobilityStatus.independent,
  );
}

class Patient {
  final String id;
  final String ownerId;
  final String fullName;
  final String? icPassport;
  final DateTime? dob;
  final String? gender;
  final Relationship relationshipToOwner;
  final String? address;
  final String? photoUrl;
  final String? medicalConditions;
  final String? allergies;
  final MobilityStatus? mobilityStatus;
  final String? specialInstructions;

  const Patient({
    required this.id,
    required this.ownerId,
    required this.fullName,
    this.icPassport,
    this.dob,
    this.gender,
    required this.relationshipToOwner,
    this.address,
    this.photoUrl,
    this.medicalConditions,
    this.allergies,
    this.mobilityStatus,
    this.specialInstructions,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      fullName: map['full_name'] as String,
      icPassport: map['ic_passport'] as String?,
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      gender: map['gender'] as String?,
      relationshipToOwner: relationshipFromString(map['relationship_to_owner'] as String? ?? 'self'),
      address: map['address'] as String?,
      photoUrl: map['photo_url'] as String?,
      medicalConditions: map['medical_conditions'] as String?,
      allergies: map['allergies'] as String?,
      mobilityStatus: mobilityStatusFromString(map['mobility_status'] as String?),
      specialInstructions: map['special_instructions'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'full_name': fullName,
      'ic_passport': icPassport,
      'dob': dob?.toIso8601String().split('T').first,
      'gender': gender,
      'relationship_to_owner': relationshipToOwner.name,
      'address': address,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'mobility_status': mobilityStatus?.name,
      'special_instructions': specialInstructions,
    };
  }
}
