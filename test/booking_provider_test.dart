import 'package:book_my_pandit/presentation/providers/booking_provider.dart';
import 'package:book_my_pandit/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fakes.dart';

void main() {
  test('BookingProvider opens checkout with expected params', () async {
    final paymentGateway = FakePaymentGateway();
    final bookingRepository = FakeBookingRepository();
    final provider = BookingProvider(paymentGateway, bookingRepository);

    await provider.initiateCheckout(
      CheckoutRequest(
        userId: 'user_1',
        panditId: 'pandit_1',
        scheduledAt: DateTime(2026, 4, 2, 10, 0),
        amount: 2100,
        payerName: 'Nisha',
        payerEmail: 'nisha@example.com',
        payerPhone: '9999999999',
      ),
    );

    expect(provider.isProcessing, isTrue);
    expect(paymentGateway.amountInPaise, 210000);
    expect(paymentGateway.name, 'Nisha');
    expect(paymentGateway.prefillEmail, 'nisha@example.com');
    expect(paymentGateway.orderId, 'order_1');

    paymentGateway.triggerSuccess(paymentId: 'pay_abc');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isProcessing, isFalse);
    expect(provider.lastPaymentId, 'pay_abc');
    expect(provider.lastBookingId, 'booking_1');
    expect(bookingRepository.createdBooking?.status, BookingModel.statusConfirmed);
    expect(bookingRepository.lastVerificationPayload?['paymentId'], 'pay_abc');
  });

  test('BookingProvider surfaces gateway failure and clears loading state', () async {
    final paymentGateway = FakePaymentGateway();
    final bookingRepository = FakeBookingRepository();
    final provider = BookingProvider(paymentGateway, bookingRepository);

    await provider.initiateCheckout(
      CheckoutRequest(
        userId: 'user_1',
        panditId: 'pandit_1',
        scheduledAt: DateTime(2026, 4, 2, 10, 0),
        amount: 2100,
        payerName: 'Nisha',
        payerEmail: 'nisha@example.com',
        payerPhone: '9999999999',
      ),
    );

    paymentGateway.triggerCheckoutError('Missing key');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isProcessing, isFalse);
    expect(provider.errorMessage, 'Missing key');
  });
}
