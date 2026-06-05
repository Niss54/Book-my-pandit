import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:book_my_pandit/presentation/screens/checkout_screen.dart';
import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:book_my_pandit/presentation/providers/booking_provider.dart';
import 'package:book_my_pandit/models/pandit_model.dart';
import 'package:book_my_pandit/models/user_model.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockBookingProvider extends Mock implements BookingProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockBookingProvider mockBookingProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockBookingProvider = MockBookingProvider();

    when(() => mockAuthProvider.currentUser).thenReturn(
      UserModel(id: 'u1', email: 'test@test.com', name: 'Test User'),
    );
    when(() => mockBookingProvider.isProcessing).thenReturn(false);
    when(() => mockBookingProvider.errorMessage).thenReturn(null);
  });

  Widget createWidgetUnderTest(PanditModel pandit) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<BookingProvider>.value(value: mockBookingProvider),
        ],
        child: CheckoutScreen(pandit: pandit),
      ),
    );
  }

  testWidgets('renders pandit details correctly', (WidgetTester tester) async {
    final pandit = PanditModel(id: '1', name: 'Test Pandit', experienceYears: 10, rating: 5.0, bio: 'Bio', expertise: 'Marriage', basePrice: 1500, profilePictureUrl: null, isActive: true);

    await tester.pumpWidget(createWidgetUnderTest(pandit));

    expect(find.text('Test Pandit'), findsOneWidget);
    expect(find.text('₹1500'), findsNWidgets(2)); // Base price and total price
    expect(find.text('Pay Now'), findsOneWidget);
  });
}
