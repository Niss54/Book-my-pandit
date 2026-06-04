import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:book_my_pandit/presentation/screens/home_screen.dart';
import 'package:book_my_pandit/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_fakes.dart';

void main() {
  testWidgets('Home screen shows primary entry point', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Book My Pandit'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Login screen shows Google sign-in button', (WidgetTester tester) async {
    final authRepository = FakeAuthRepository();
    final authProvider = AuthProvider(authRepository);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);

    authRepository.dispose();
  });
}