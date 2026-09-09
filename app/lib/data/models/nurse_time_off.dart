class NurseTimeOff {
  final String id;
  final String nurseId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;

  const NurseTimeOff({
    required this.id,
    required this.nurseId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
  });

  factory NurseTimeOff.fromMap(Map<String, dynamic> map) {
    return NurseTimeOff(
      id: map['id'] as String,
      nurseId: map['nurse_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      reason: map['reason'] as String?,
      status: map['status'] as String? ?? 'approved',
    );
  }
}
