import 'package:flutter/material.dart';

import '../../../core/supabase_client.dart';
import '../../../data/models/nurse_availability_slot.dart';
import '../../../data/models/nurse_time_off.dart';

class NurseAvailabilityRepository {
  Future<List<NurseAvailabilitySlot>> listMyAvailability() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('nurse_availability')
        .select()
        .eq('nurse_id', userId)
        .order('day_of_week')
        .order('start_time');
    return rows.map((row) => NurseAvailabilitySlot.fromMap(row)).toList();
  }

  /// Throws a PostgrestException with a friendly message (from the DB
  /// trigger) if this slot overlaps an existing one for that day.
  Future<void> addAvailabilitySlot({
    required int dayOfWeek,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('nurse_availability').insert({
      'nurse_id': userId,
      'day_of_week': dayOfWeek,
      'start_time': formatTimeOfDay(start),
      'end_time': formatTimeOfDay(end),
    });
  }

  Future<void> deleteAvailabilitySlot(String id) async {
    await supabase.from('nurse_availability').delete().eq('id', id);
  }

  Future<List<NurseTimeOff>> listMyTimeOff() async {
    final userId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('nurse_time_off')
        .select()
        .eq('nurse_id', userId)
        .order('start_date', ascending: false);
    return rows.map((row) => NurseTimeOff.fromMap(row)).toList();
  }

  /// Throws a PostgrestException with a friendly message (from the DB
  /// trigger) if this range overlaps existing time off.
  Future<void> addTimeOff({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('nurse_time_off').insert({
      'nurse_id': userId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'reason': reason,
    });
  }

  Future<void> deleteTimeOff(String id) async {
    await supabase.from('nurse_time_off').delete().eq('id', id);
  }
}
