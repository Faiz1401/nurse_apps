import '../../../core/supabase_client.dart';
import '../../../data/models/service.dart';
import '../../../data/models/service_category.dart';
import '../../../data/models/skill.dart';

/// Wraps `skills`/`service_categories`/`services` Postgrest calls. Reads are
/// open to any authenticated role (patients/nurses browse the catalog);
/// writes are RLS-restricted to admins — this repository doesn't enforce
/// that itself, the server does.
class ServicesRepository {
  Future<List<Skill>> listSkills() async {
    final rows = await supabase.from('skills').select().order('name');
    return rows.map((row) => Skill.fromMap(row)).toList();
  }

  Future<List<ServiceCategory>> listCategories() async {
    final rows = await supabase.from('service_categories').select().order('name');
    return rows.map((row) => ServiceCategory.fromMap(row)).toList();
  }

  Future<ServiceCategory> createCategory(ServiceCategory category) async {
    final row = await supabase.from('service_categories').insert(category.toInsertMap()).select().single();
    return ServiceCategory.fromMap(row);
  }

  Future<ServiceCategory> updateCategory(String id, ServiceCategory category) async {
    final row = await supabase
        .from('service_categories')
        .update(category.toInsertMap())
        .eq('id', id)
        .select()
        .single();
    return ServiceCategory.fromMap(row);
  }

  Future<void> deleteCategory(String id) async {
    await supabase.from('service_categories').delete().eq('id', id);
  }

  Future<List<Service>> listServices({bool activeOnly = false}) async {
    var query = supabase.from('services').select('*, service_categories(name), skills(name)');
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('name');
    return rows.map((row) => Service.fromMap(row)).toList();
  }

  Future<Service> createService(Service service) async {
    final row = await supabase
        .from('services')
        .insert(service.toInsertMap())
        .select('*, service_categories(name), skills(name)')
        .single();
    return Service.fromMap(row);
  }

  Future<Service> updateService(String id, Service service) async {
    final row = await supabase
        .from('services')
        .update(service.toInsertMap())
        .eq('id', id)
        .select('*, service_categories(name), skills(name)')
        .single();
    return Service.fromMap(row);
  }

  Future<void> deleteService(String id) async {
    await supabase.from('services').delete().eq('id', id);
  }
}
