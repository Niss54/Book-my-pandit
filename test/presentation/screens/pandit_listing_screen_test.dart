import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:book_my_pandit/presentation/screens/pandit_listing_screen.dart';
import 'package:book_my_pandit/domain/repositories/pandit_repository.dart';
import 'package:book_my_pandit/presentation/providers/auth_provider.dart';
import 'package:book_my_pandit/models/pandit_model.dart';
import 'package:book_my_pandit/di/service_locator.dart';

class MockPanditRepository extends Mock implements PanditRepository {}
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockPanditRepository mockPanditRepository;
  late MockAuthProvider mockAuthProvider;

  setUpAll(() {
    getIt.registerSingleton<PanditRepository>(MockPanditRepository());
  });

  tearDownAll(() {
    getIt.reset();
  });

  setUp(() {
    mockPanditRepository = getIt<PanditRepository>() as MockPanditRepository;
    mockAuthProvider = MockAuthProvider();
    
    when(() => mockAuthProvider.currentUser).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: const PanditListingScreen(),
      ),
    );
  }

  testWidgets('renders loading state initially', (WidgetTester tester) async {
    when(() => mockPanditRepository.getActivePandits())
        .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return [];
        });

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders pandit list', (WidgetTester tester) async {
    final mockPandits = [
      PanditModel(id: '1', name: 'Pandit A', experienceYears: 10, rating: 5.0, bio: 'Bio A', expertise: 'Marriage', basePrice: 1000, imageUrl: '', isActive: true),
      PanditModel(id: '2', name: 'Pandit B', experienceYears: 5, rating: 4.0, bio: 'Bio B', expertise: 'Puja', basePrice: 500, imageUrl: '', isActive: true),
    ];

    when(() => mockPanditRepository.getActivePandits())
        .thenAnswer((_) async => mockPandits);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Pandit A'), findsOneWidget);
    expect(find.text('Pandit B'), findsOneWidget);
  });
}
