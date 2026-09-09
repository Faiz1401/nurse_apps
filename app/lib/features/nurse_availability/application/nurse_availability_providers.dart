import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse_availability_slot.dart';
import '../../../data/models/nurse_time_off.dart';
import '../data/nurse_availability_repository.dart';

final nurseAvailabilityRepositoryProvider =
    Provider<NurseAvailabilityRepository>((ref) => NurseAvailabilityRepository());

final myAvailabilityProvider = FutureProvider.autoDispose<List<NurseAvailabilitySlot>>((ref) {
  return ref.watch(nurseAvailabilityRepositoryProvider).listMyAvailability();
});

final myTimeOffProvider = FutureProvider.autoDispose<List<NurseTimeOff>>((ref) {
  return ref.watch(nurseAvailabilityRepositoryProvider).listMyTimeOff();
});
