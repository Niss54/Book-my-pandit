import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUser;
  bool _isLoading = false;
  AuthProvider(this._authRepository) {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user; notifyListeners();
    });
  }
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  Future<void> signInWithGoogle() async {
    _isLoading = true; notifyListeners();
    try {
      final user = await _authRepository.signInWithGoogle();
      _currentUser = user;
    } catch (e) {
      print('Auth Error!');
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
  Future<void> signOut() async { await _authRepository.signOut(); }
}