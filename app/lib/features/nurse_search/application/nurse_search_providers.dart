import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse_search_result.dart';
import '../data/nurse_search_repository.dart';

final nurseSearchRepositoryProvider = Provider<NurseSearchRepository>((ref) => NurseSearchRepository());

final browseNursesProvider = FutureProvider.autoDispose<List<NurseSearchResult>>((ref) {
  return ref.watch(nurseSearchRepositoryProvider).browseNurses();
});

class NurseSearchFilters {
  final String? serviceId;
  final String? skillId;
  final String? gender;
  final double minExperience;
  final double minRating;
  final bool availableOnly;

  const NurseSearchFilters({
    this.serviceId,
    this.skillId,
    this.gender,
    this.minExperience = 0,
    this.minRating = 0,
    this.availableOnly = false,
  });

  NurseSearchFilters copyWith({
    String? serviceId,
    bool clearServiceId = false,
    String? skillId,
    bool clearSkillId = false,
    String? gender,
    bool clearGender = false,
    double? minExperience,
    double? minRating,
    bool? availableOnly,
  }) {
    return NurseSearchFilters(
      serviceId: clearServiceId ? null : (serviceId ?? this.serviceId),
      skillId: clearSkillId ? null : (skillId ?? this.skillId),
      gender: clearGender ? null : (gender ?? this.gender),
      minExperience: minExperience ?? this.minExperience,
      minRating: minRating ?? this.minRating,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }
}

final nurseSearchFiltersProvider =
    StateProvider.autoDispose<NurseSearchFilters>((ref) => const NurseSearchFilters());

final filteredNursesProvider = Provider.autoDispose<AsyncValue<List<NurseSearchResult>>>((ref) {
  final nursesAsync = ref.watch(browseNursesProvider);
  final filters = ref.watch(nurseSearchFiltersProvider);

  return nursesAsync.whenData((nurses) {
    return nurses.where((nurse) {
      if (filters.serviceId != null && !nurse.services.any((s) => s.id == filters.serviceId)) {
        return false;
      }
      if (filters.skillId != null && !nurse.skills.any((s) => s.id == filters.skillId)) {
        return false;
      }
      if (filters.gender != null && nurse.gender != filters.gender) {
        return false;
      }
      if (nurse.experienceYears < filters.minExperience) {
        return false;
      }
      if (nurse.ratingAvg < filters.minRating) {
        return false;
      }
      if (filters.availableOnly && !nurse.isAvailable) {
        return false;
      }
      return true;
    }).toList();
  });
});
