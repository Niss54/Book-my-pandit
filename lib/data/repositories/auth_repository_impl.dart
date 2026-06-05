import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../domain/services/i_auth_service.dart';
import '../../domain/services/i_supabase_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ISupabaseService _supabaseService;
  final IAuthService _authService;

  AuthRepositoryImpl(this._supabaseService, this._authService);

  @override
  Future<UserModel?> signInWithGoogle() async {
    final user = await _authService.signIn();
    if (user != null) {
      final appUser = UserModel(
        id: user.uid,
        email: user.email,
        name: user.name,
        profilePictureUrl: user.photoUrl,
      );

      await _supabaseService.upsertUserProfile(appUser);
      return appUser;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Stream<UserModel?> get authStateChanges {
     return _supabaseService.authStateChanges.asyncMap((event) async {
        final user = event.session?.user;
        if (user == null) return null;

        final appUser = UserModel(
          id: user.id,
          email: user.email ?? '',
          name: (user.userMetadata?['full_name'] ?? 'User').toString(),
          profilePictureUrl: user.userMetadata?['avatar_url']?.toString(),
        );

        await _supabaseService.upsertUserProfile(appUser);
        return appUser;
     });
  }
}
