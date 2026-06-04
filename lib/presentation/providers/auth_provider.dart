import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  AuthProvider(this._authRepository) {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user; notifyListeners();
    });
  }
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<void> signInWithGoogle() async {
    _isLoading = true; notifyListeners();
    try {
      _errorMessage = null;
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
      } else {
        _errorMessage = 'Google sign-in did not complete. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Unable to sign in right now. Please retry.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
  Future<void> signOut() async { await _authRepository.signOut(); }
}