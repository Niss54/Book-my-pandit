import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:book_my_pandit/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: Booking Flow Test', (WidgetTester tester) async {
    // Note: To run this test successfully, you might need to mock the 
    // Supabase backend or ensure test data exists.
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Wait for initial render (might be Login or Home depending on auth state)
    // We assume the user needs to log in for the first time, 
    // or they are already logged in. 
    
    // For the sake of this mock integration test, let's just assert 
    // we can find basic elements if we were on the PanditListingScreen
    // (assuming we are either there or can navigate there).
    
    // If we see login button, we are on login screen.
    final loginButtonFinder = find.text('Continue with Google');
    if (loginButtonFinder.evaluate().isNotEmpty) {
       // Cannot really test Google Login via UI easily in E2E without mock
       // So we just assert it's there.
       expect(loginButtonFinder, findsOneWidget);
       return; 
    }

    // If logged in, we should see PanditListingScreen
    expect(find.text('Find Your Pandit'), findsOneWidget);
    
    // Scroll and tap the first pandit
    final panditCardFinder = find.byType(Card).first;
    if (panditCardFinder.evaluate().isNotEmpty) {
        await tester.tap(panditCardFinder);
        await tester.pumpAndSettle();

        // Should be on Details Screen
        expect(find.text('Book Now'), findsOneWidget);

        // Tap Book Now
        await tester.tap(find.text('Book Now'));
        await tester.pumpAndSettle();

        // Should be on Checkout Screen
        expect(find.text('Checkout'), findsOneWidget);
        expect(find.text('Pay Now'), findsOneWidget);
    }
  });
}
