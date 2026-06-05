import '../../models/booking_model.dart';

class PaymentOrder {
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String idempotencyKey;

  const PaymentOrder({
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.idempotencyKey,
  });
}

abstract class BookingRepository {
  Future<PaymentOrder> createPaymentOrder({
    required String panditId,
    required String idempotencyKey,
  });

  Future<BookingModel> verifyPaymentAndConfirmBooking({
    required String userId,
    required String panditId,
    required DateTime date,
    required String paymentId,
    required String orderId,
    required String signature,
    required String idempotencyKey,
  });

  Future<BookingModel> createBooking({
    required String userId,
    required String panditId,
    required DateTime date,
    required int amount,
    required String status,
    String? paymentReference,
  });

  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String userId,
    required String status,
  });

  Future<List<BookingModel>> getUserBookings(String userId);

  Future<List<BookingModel>> getAllBookings();

  Stream<List<BookingModel>> subscribeToUserBookings(String userId);
}
