import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/profile.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Emits whenever Supabase Auth's session changes (sign in/out/token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// The signed-in user's `profiles` row, re-fetched whenever auth state changes.
/// Null means "signed out"; the router uses this to decide which shell to show.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider); // re-run this provider on every auth change
  return ref.watch(authRepositoryProvider).fetchCurrentProfile();
});
