import '../../domain/repositories/pandit_repository.dart';
import '../../models/pandit_model.dart';
import '../../services/supabase_service.dart';

class PanditRepositoryImpl implements PanditRepository {
  @override
  Future<List<PanditModel>> getActivePandits() {
    return SupabaseService.getPandits();
  }
}
