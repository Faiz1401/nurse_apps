import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/nurse_availability/presentation/nurse_availability_screen.dart';
import '../../features/nurse_profile/presentation/nurse_profile_screen.dart';
import '../../features/nurse_verification/presentation/nurse_documents_screen.dart';

/// Nurse shell. Bottom-nav grows as more modules land — Available Jobs, My
/// Jobs, Calendar, Patients, Visit Documentation, Messages, Earnings and
/// Verification are added with their own modules (see docs/02-module-tree.md).
class NurseShell extends ConsumerStatefulWidget {
  const NurseShell({super.key});

  @override
  ConsumerState<NurseShell> createState() => _NurseShellState();
}

class _NurseShellState extends ConsumerState<NurseShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const NurseProfileScreen(),
      const NurseDocumentsScreen(),
      const NurseAvailabilityScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(
              icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Verification'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Availability'),
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
          'Welcome, ${profile?.fullName ?? ''}\n\nAvailable Jobs, My Jobs, Calendar and more land here as their modules are built.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
