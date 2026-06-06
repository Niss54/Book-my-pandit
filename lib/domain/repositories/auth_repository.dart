import 'dart:io';
import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  Future<void> updateUserProfile(UserModel updatedUser);
  Future<String> uploadAvatar(String userId, File imageFile);
  Stream<UserModel?> get authStateChanges;
}
