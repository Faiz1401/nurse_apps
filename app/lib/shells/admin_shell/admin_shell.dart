import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/nurse_verification/presentation/admin_nurse_verification_screen.dart';
import '../../features/services_catalog/presentation/admin_services_screen.dart';

enum _AdminSection { dashboard, services, nurseVerification }

/// Admin shell. Ships as this same Flutter codebase compiled to Flutter Web
/// (desktop-first) per docs/01-architecture.md; a Drawer is used here rather
/// than a fixed side rail so it still works cleanly on the phone emulator
/// during development — swapping to a permanent NavigationRail for the wide
/// Flutter Web layout is a presentation-only change for later, once more
/// admin sections exist.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  _AdminSection _section = _AdminSection.dashboard;

  String get _title {
    switch (_section) {
      case _AdminSection.dashboard:
        return 'Admin Dashboard';
      case _AdminSection.services:
        return 'Services';
      case _AdminSection.nurseVerification:
        return 'Nurse Verification';
    }
  }

  Widget get _body {
    switch (_section) {
      case _AdminSection.dashboard:
        return const _DashboardBody();
      case _AdminSection.services:
        return const AdminServicesScreen();
      case _AdminSection.nurseVerification:
        return const AdminNurseVerificationScreen();
    }
  }

  void _select(_AdminSection section) {
    setState(() => _section = section);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Admin Console')),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: _section == _AdminSection.dashboard,
              onTap: () => _select(_AdminSection.dashboard),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Services'),
              selected: _section == _AdminSection.services,
              onTap: () => _select(_AdminSection.services),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Nurse Verification'),
              selected: _section == _AdminSection.nurseVerification,
              onTap: () => _select(_AdminSection.nurseVerification),
            ),
          ],
        ),
      ),
      body: _body,
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return Center(
      child: Text(
        'Welcome, ${profile?.fullName ?? ''}\n\nUsers, Patients, Bookings, Live Ops, Payments, Incidents, Reviews, Reports and Audit Logs land here as their modules are built.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
