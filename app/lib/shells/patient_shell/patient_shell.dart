import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/client_profile/presentation/profile_screen.dart';
import '../../features/nurse_search/presentation/nurse_search_screen.dart';
import '../../features/patients/presentation/patients_list_screen.dart';
import '../../features/services_catalog/presentation/services_browse_screen.dart';

/// Client/patient shell. Bottom-nav grows as more modules land — Book a
/// Nurse, My Bookings, Health Records, Care Plans, Messages, Payments and
/// Notifications are added with their own modules (see docs/02-module-tree.md).
class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key});

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const ServicesBrowseScreen(),
      const NurseSearchScreen(),
      const PatientsListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services),
              label: 'Services'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Find Nurses'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'My Patients'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${profile?.fullName ?? ''}\n\nBooking, health records and more land here as their modules are built.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
