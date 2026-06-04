import '../../domain/repositories/pandit_repository.dart';
import '../../models/pandit_model.dart';
import '../../services/supabase_service.dart';

class PanditRepositoryImpl implements PanditRepository {
  List<PanditModel>? _cachedPandits;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  Future<List<PanditModel>> getActivePandits() async {
    final now = DateTime.now();
    if (_cachedPandits != null && _lastFetchTime != null) {
      if (now.difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedPandits!;
      }
    }

    final pandits = await SupabaseService.getPandits();
    _cachedPandits = pandits;
    _lastFetchTime = now;
    return pandits;
  }
}
