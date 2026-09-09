import '../../../core/supabase_client.dart';
import '../../../data/models/nurse_search_result.dart';

class NurseSearchRepository {
  /// Fetches every approved, browsable nurse profile. Filtering (service,
  /// skill, gender, experience, rating, availability, price) is applied
  /// client-side in the search screen — the nurse pool is small enough at
  /// this stage that a round-trip per filter change isn't worth the
  /// complexity of JSONB containment queries against skills/services.
  Future<List<NurseSearchResult>> browseNurses() async {
    final rows = await supabase.from('public_nurse_profiles').select();
    return rows.map((row) => NurseSearchResult.fromMap(row)).toList();
  }
}
