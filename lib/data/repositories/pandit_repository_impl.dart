import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/pandit_repository.dart';
import '../../models/pandit_model.dart';
import '../../domain/services/i_supabase_service.dart';

class PanditRepositoryImpl implements PanditRepository {
  final ISupabaseService _supabaseService;
  final SharedPreferences _prefs;
  
  List<PanditModel>? _cachedPandits;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const String _cacheKey = 'cached_pandits';

  PanditRepositoryImpl(this._supabaseService, this._prefs);

  @override
  Future<List<PanditModel>> getActivePandits() async {
    final now = DateTime.now();
    if (_cachedPandits != null && _lastFetchTime != null) {
      if (now.difference(_lastFetchTime!) < _cacheDuration) {
        return _cachedPandits!;
      }
    }

    try {
      final pandits = await _supabaseService.getPandits();
      _cachedPandits = pandits;
      _lastFetchTime = now;
      
      // Save to SharedPreferences for offline use
      final jsonList = pandits.map((p) => p.toJson()).toList();
      await _prefs.setString(_cacheKey, jsonEncode(jsonList));
      
      return pandits;
    } catch (e) {
      // Fallback to SharedPreferences if network fails
      final cachedString = _prefs.getString(_cacheKey);
      if (cachedString != null) {
        final List<dynamic> decoded = jsonDecode(cachedString);
        final pandits = decoded.map((json) => PanditModel.fromJson(json)).toList();
        _cachedPandits = pandits;
        _lastFetchTime = now;
        return pandits;
      }
      rethrow;
    }
  }
}
