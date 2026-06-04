import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../services/google_auth_service.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  Future<UserModel?> signInWithGoogle() async {
    final user = await _googleAuthService.signIn();
    if (user != null) {
      final appUser = UserModel(
        id: user.uid,
        email: user.email,
        name: user.name,
        profilePictureUrl: user.photoUrl,
      );

      await SupabaseService.upsertUserProfile(appUser);
      return appUser;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _googleAuthService.signOut();
  }

  @override
  Stream<UserModel?> get authStateChanges {
     return _supabaseClient.auth.onAuthStateChange.asyncMap((event) async {
        final user = event.session?.user;
        if (user == null) return null;

        final appUser = UserModel(
          id: user.id,
          email: user.email ?? '',
          name: (user.userMetadata?['full_name'] ?? 'User').toString(),
          profilePictureUrl: user.userMetadata?['avatar_url']?.toString(),
        );

        await SupabaseService.upsertUserProfile(appUser);
        return appUser;
     });
  }
}
