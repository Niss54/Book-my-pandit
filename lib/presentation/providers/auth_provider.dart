import 'dart:io';
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
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? imagePath,
  }) async {
    if (_currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _errorMessage = null;
      String? newImageUrl = _currentUser!.profilePictureUrl;
      
      if (imagePath != null) {
        newImageUrl = await _authRepository.uploadAvatar(_currentUser!.id, File(imagePath));
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        address: address,
        profilePictureUrl: newImageUrl,
      );

      await _authRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _errorMessage = 'Failed to update profile. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async { await _authRepository.signOut(); }
}