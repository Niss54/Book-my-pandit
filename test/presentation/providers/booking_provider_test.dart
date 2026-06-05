import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:book_my_pandit/presentation/providers/booking_provider.dart';
import 'package:book_my_pandit/domain/repositories/booking_repository.dart';
import 'package:book_my_pandit/services/payment_gateway.dart';
import 'package:book_my_pandit/models/booking_model.dart';
import 'package:book_my_pandit/models/pandit_model.dart';

class MockBookingRepository extends Mock implements BookingRepository {}
class MockPaymentGateway extends Mock implements PaymentGateway {}

void main() {
  late MockBookingRepository mockBookingRepository;
  late MockPaymentGateway mockPaymentGateway;
  late BookingProvider bookingProvider;
  late StreamController<List<BookingModel>> bookingsStreamController;

  setUp(() {
    mockBookingRepository = MockBookingRepository();
    mockPaymentGateway = MockPaymentGateway();
    bookingsStreamController = StreamController<List<BookingModel>>.broadcast();

    when(() => mockBookingRepository.subscribeToUserBookings(any()))
        .thenAnswer((_) => bookingsStreamController.stream);

    bookingProvider = BookingProvider(mockPaymentGateway, mockBookingRepository);
  });

  tearDown(() {
    bookingsStreamController.close();
    bookingProvider.dispose();
  });

  test('initial state should be empty', () {
    expect(bookingProvider.isProcessing, isFalse);
    expect(bookingProvider.isLoadingBookings, isFalse);
    expect(bookingProvider.userBookings, isNull);
  });

  test('subscribeToUserBookings updates state on stream events', () async {
    final bookings = [
      BookingModel(id: '1', userId: 'u1', panditId: 'p1', date: DateTime.now(), amount: 100, status: 'pending')
    ];

    bookingProvider.subscribeToUserBookings('u1');
    
    // Simulate stream emitting data
    bookingsStreamController.add(bookings);
    
    // Allow stream to process
    await Future.delayed(Duration.zero);

    expect(bookingProvider.userBookings, equals(bookings));
    expect(bookingProvider.isLoadingBookings, isFalse);
  });
}
