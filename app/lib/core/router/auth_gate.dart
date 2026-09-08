import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profile.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../shells/admin_shell/admin_shell.dart';
import '../../shells/nurse_shell/nurse_shell.dart';
import '../../shells/patient_shell/patient_shell.dart';

/// Root widget deciding what to show based on auth + role state:
/// signed out -> LoginScreen; signed in -> the shell matching profiles.role.
/// This is the single place role-based routing happens (§RBAC).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _Splash(),
      error: (error, stackTrace) => _ErrorScreen(message: error.toString()),
      data: (state) {
        final session = state.session;
        if (session == null) return const LoginScreen();

        final profileAsync = ref.watch(currentProfileProvider);
        return profileAsync.when(
          loading: () => const _Splash(),
          error: (error, stackTrace) => _ErrorScreen(message: error.toString()),
          data: (profile) {
            if (profile == null) {
              return const _ErrorScreen(
                message: 'No profile found for this account. Contact support.',
              );
            }
            switch (profile.role) {
              case UserRole.nurse:
                return const NurseShell();
              case UserRole.admin:
              case UserRole.superAdmin:
                return const AdminShell();
              case UserRole.patient:
              case UserRole.family:
                return const PatientShell();
            }
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message))));
  }
}
