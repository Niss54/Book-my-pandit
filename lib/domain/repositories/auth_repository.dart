import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> get authStateChanges;
}
