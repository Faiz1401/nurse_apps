import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../../data/models/profile.dart';

/// Wraps every Supabase Auth call used by the app. Widgets never call
/// `supabase.auth` directly — they go through this repository.
class AuthRepository {
  Session? get currentSession => supabase.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole role = UserRole.patient,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        // Server-side trigger clamps this to patient/nurse only — admin
        // roles can never be granted through self-registration.
        'role': role == UserRole.nurse ? 'nurse' : 'patient',
      },
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return supabase.auth.resetPasswordForEmail(email);
  }

  Future<Profile?> fetchCurrentProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final row = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }
}
