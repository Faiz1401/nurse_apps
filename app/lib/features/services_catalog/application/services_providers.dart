import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/service.dart';
import '../../../data/models/service_category.dart';
import '../../../data/models/skill.dart';
import '../data/services_repository.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) => ServicesRepository());

final skillsProvider = FutureProvider.autoDispose<List<Skill>>((ref) {
  return ref.watch(servicesRepositoryProvider).listSkills();
});

final categoriesProvider = FutureProvider.autoDispose<List<ServiceCategory>>((ref) {
  return ref.watch(servicesRepositoryProvider).listCategories();
});

/// All services (admin management view). Clients browsing for booking will
/// use a separate `activeOnly` provider once the booking module exists.
final servicesProvider = FutureProvider.autoDispose<List<Service>>((ref) {
  return ref.watch(servicesRepositoryProvider).listServices();
});

final activeServicesProvider = FutureProvider.autoDispose<List<Service>>((ref) {
  return ref.watch(servicesRepositoryProvider).listServices(activeOnly: true);
});
