import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:book_my_pandit/domain/repositories/auth_repository.dart';
import 'package:book_my_pandit/models/user_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthProvider authProvider;
  late StreamController<UserModel?> authStateController;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<UserModel?>.broadcast();
    
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);

    authProvider = AuthProvider(mockAuthRepository);
  });

  tearDown(() {
    authStateController.close();
    authProvider.dispose();
  });

  test('initial state should be unauthenticated', () {
    expect(authProvider.currentUser, isNull);
    expect(authProvider.isAuthenticated, isFalse);
    expect(authProvider.isLoading, isFalse);
  });

  test('signInWithGoogle should update state on success', () async {
    final user = UserModel(id: '1', email: 'test@test.com', name: 'Test User');
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => user);

    await authProvider.signInWithGoogle();

    expect(authProvider.currentUser, equals(user));
    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.isLoading, isFalse);
    expect(authProvider.error, isNull);
  });

  test('signInWithGoogle should handle errors', () async {
    when(() => mockAuthRepository.signInWithGoogle())
        .thenThrow(Exception('Login failed'));

    await authProvider.signInWithGoogle();

    expect(authProvider.currentUser, isNull);
    expect(authProvider.isAuthenticated, isFalse);
    expect(authProvider.isLoading, isFalse);
    expect(authProvider.error, isNotNull);
  });

  test('signOut should clear current user', () async {
    when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

    await authProvider.signOut();

    expect(authProvider.currentUser, isNull);
    expect(authProvider.isAuthenticated, isFalse);
  });
}
