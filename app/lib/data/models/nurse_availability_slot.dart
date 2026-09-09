import 'package:flutter/material.dart';

const weekdayLabels = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String displayTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class NurseAvailabilitySlot {
  final String id;
  final String nurseId;
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const NurseAvailabilitySlot({
    required this.id,
    required this.nurseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory NurseAvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return NurseAvailabilitySlot(
      id: map['id'] as String,
      nurseId: map['nurse_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      startTime: _parseTime(map['start_time'] as String),
      endTime: _parseTime(map['end_time'] as String),
    );
  }
}
