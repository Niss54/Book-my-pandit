import 'package:book_my_pandit/models/user_model.dart';
import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fakes.dart';

void main() {
  test('AuthProvider signs in and updates current user', () async {
    final repository = FakeAuthRepository()
      ..nextUser = UserModel(
        id: 'user_1',
        email: 'nisha@example.com',
        name: 'Nisha',
        profilePictureUrl: null,
      );
    final provider = AuthProvider(repository);

    await provider.signInWithGoogle();

    expect(provider.isLoading, isFalse);
    expect(provider.currentUser?.id, 'user_1');
    expect(provider.errorMessage, isNull);

    repository.dispose();
  });

  test('AuthProvider surfaces sign-in errors', () async {
    final repository = FakeAuthRepository()..signInError = StateError('boom');
    final provider = AuthProvider(repository);

    await provider.signInWithGoogle();

    expect(provider.isLoading, isFalse);
    expect(provider.currentUser, isNull);
    expect(provider.errorMessage, isNotNull);

    repository.dispose();
  });
}
