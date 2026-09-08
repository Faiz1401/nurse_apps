import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse.dart';
import '../data/nurse_repository.dart';

final nurseRepositoryProvider = Provider<NurseRepository>((ref) => NurseRepository());

final myNurseProfileProvider = FutureProvider.autoDispose<Nurse?>((ref) {
  return ref.watch(nurseRepositoryProvider).fetchMyNurseProfile();
});

final mySkillIdsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(nurseRepositoryProvider).listMySkillIds();
});

final myServiceIdsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(nurseRepositoryProvider).listMyServiceIds();
});
