import 'package:book_my_pandit/domain/repositories/pandit_repository.dart';
import 'package:book_my_pandit/models/pandit_model.dart';
import 'package:book_my_pandit/models/user_model.dart';
import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:book_my_pandit/presentation/providers/booking_provider.dart';
import 'package:book_my_pandit/presentation/screens/checkout_screen.dart';
import 'package:book_my_pandit/presentation/screens/home_screen.dart';
import 'package:book_my_pandit/presentation/screens/login_screen.dart';
import 'package:book_my_pandit/presentation/screens/pandit_listing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../test/test_fakes.dart';

void main() {
  testWidgets('login to pandit listing to checkout flow works end-to-end', (WidgetTester tester) async {
    final authRepository = FakeAuthRepository()
      ..nextUser = UserModel(
        id: 'user_1',
        email: 'nisha@example.com',
        name: 'Nisha',
        profilePictureUrl: null,
      );
    final authProvider = AuthProvider(authRepository);
    final bookingGateway = FakePaymentGateway();
    final bookingRepository = FakeBookingRepository();
    final bookingProvider = BookingProvider(bookingGateway, bookingRepository);
    final panditRepository = _TestPanditRepository(
      [
        PanditModel(
          id: 'pandit_1',
          name: 'Pandit Shivram',
          expertise: 'Vastu & Navagraha Shanti',
          rating: 4.9,
          basePrice: 2100,
          imageUrl: '',
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => ChangeNotifierProvider.value(
            value: authProvider,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/pandits',
          builder: (_, __) => ChangeNotifierProvider.value(
            value: authProvider,
            child: PanditListingScreen(panditRepository: panditRepository),
          ),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, state) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: bookingProvider),
            ],
            child: CheckoutScreen(pandit: state.extra! as PanditModel),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Available Pandits'), findsOneWidget);
    await tester.tap(find.text('Pandit Shivram'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Booking'), findsOneWidget);
    await tester.tap(find.text('Proceed to Pay ₹2100'));
    await tester.pumpAndSettle();

    bookingGateway.triggerSuccess(paymentId: 'pay_flow_1');
    await tester.pumpAndSettle();

    expect(find.text('Booking saved successfully.'), findsWidgets);

    authRepository.dispose();
  });
}

class _TestPanditRepository implements PanditRepository {
  final List<PanditModel> pandits;

  _TestPanditRepository(this.pandits);

  @override
  Future<List<PanditModel>> getActivePandits() async => pandits;
}
