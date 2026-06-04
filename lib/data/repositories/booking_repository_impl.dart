import '../../domain/repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../services/supabase_service.dart';

class BookingRepositoryImpl implements BookingRepository {
  @override
  Future<PaymentOrder> createPaymentOrder({
    required String panditId,
    required String idempotencyKey,
  }) {
    return SupabaseService.createPaymentOrder(
      panditId: panditId,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<BookingModel> verifyPaymentAndConfirmBooking({
    required String userId,
    required String panditId,
    required DateTime date,
    required String paymentId,
    required String orderId,
    required String signature,
    required String idempotencyKey,
  }) {
    return SupabaseService.verifyPaymentAndConfirmBooking(
      userId: userId,
      panditId: panditId,
      date: date,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<BookingModel> createBooking({
    required String userId,
    required String panditId,
    required DateTime date,
    required int amount,
    required String status,
    String? paymentReference,
  }) {
    return SupabaseService.createBooking(
      userId: userId,
      panditId: panditId,
      date: date,
      amount: amount,
      status: status,
      paymentReference: paymentReference,
    );
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String userId,
    required String status,
  }) {
    return SupabaseService.updateBookingStatus(
      bookingId: bookingId,
      userId: userId,
      status: status,
    );
  }
}
