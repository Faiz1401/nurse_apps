import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse_document.dart';
import '../../../data/models/nurse_with_profile.dart';
import '../data/nurse_verification_repository.dart';

final nurseVerificationRepositoryProvider =
    Provider<NurseVerificationRepository>((ref) => NurseVerificationRepository());

final myDocumentsProvider = FutureProvider.autoDispose<List<NurseDocument>>((ref) {
  return ref.watch(nurseVerificationRepositoryProvider).listMyDocuments();
});

final allNursesProvider = FutureProvider.autoDispose<List<NurseWithProfile>>((ref) {
  return ref.watch(nurseVerificationRepositoryProvider).listAllNurses();
});

final nurseDocumentsProvider =
    FutureProvider.autoDispose.family<List<NurseDocument>, String>((ref, nurseId) {
  return ref.watch(nurseVerificationRepositoryProvider).listDocumentsForNurse(nurseId);
});
