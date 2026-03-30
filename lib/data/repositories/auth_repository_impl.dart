import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../services/google_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  Future<UserModel?> signInWithGoogle() async {
    final user = await _googleAuthService.signIn();
    if (user != null) {
       return UserModel(id: user.uid, email: user.email, name: user.name, profilePictureUrl: user.photoUrl);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _googleAuthService.signOut();
    await _supabaseClient.auth.signOut();
  }

  @override
  Stream<UserModel?> get authStateChanges {
     return _supabaseClient.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        if (user == null) return null;
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] ?? '',
          profilePictureUrl: user.userMetadata?['avatar_url'],
        );
     });
  }
}
