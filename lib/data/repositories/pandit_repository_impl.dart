import '../../domain/repositories/pandit_repository.dart';
import '../../models/pandit_model.dart';
import '../../domain/services/i_supabase_service.dart';

class PanditRepositoryImpl implements PanditRepository {
  final ISupabaseService _supabaseService;
  
  List<PanditModel>? _cachedPandits;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  PanditRepositoryImpl(this._supabaseService);

  @override
  Future<List<PanditModel>> getActivePandits() async {
    final now = DateTime.now();
    if (_cachedPandits != null && _lastFetchTime != null) {
      if (now.difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedPandits!;
      }
    }

    final pandits = await _supabaseService.getPandits();
    _cachedPandits = pandits;
    _lastFetchTime = now;
    return pandits;
  }
}
