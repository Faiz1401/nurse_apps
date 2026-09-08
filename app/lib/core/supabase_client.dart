import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin accessor around the single Supabase client instance.
/// Initialized once in main.dart via Supabase.initialize(...).
SupabaseClient get supabase => Supabase.instance.client;
