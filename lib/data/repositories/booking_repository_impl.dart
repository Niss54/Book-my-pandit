import '../../domain/repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import '../../domain/services/i_supabase_service.dart';

class BookingRepositoryImpl implements BookingRepository {
  final ISupabaseService _supabaseService;

  BookingRepositoryImpl(this._supabaseService);

  @override
  Future<PaymentOrder> createPaymentOrder({
    required String panditId,
    required String idempotencyKey,
  }) {
    return _supabaseService.createPaymentOrder(
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
    return _supabaseService.verifyPaymentAndConfirmBooking(
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
    return _supabaseService.createBooking(
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
    return _supabaseService.updateBookingStatus(
      bookingId: bookingId,
      userId: userId,
      status: status,
    );
  }

  @override
  Future<void> submitReview({
    required String bookingId,
    required String userId,
    required String panditId,
    required int rating,
    String? comment,
  }) {
    return _supabaseService.submitReview(
      bookingId: bookingId,
      userId: userId,
      panditId: panditId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<List<BookingModel>> getUserBookings(String userId) {
    return _supabaseService.getUserBookings(userId);
  }

  @override
  Future<List<BookingModel>> getAllBookings() {
    return _supabaseService.getAllBookings();
  }

  @override
  Stream<List<BookingModel>> subscribeToUserBookings(String userId) {
    return _supabaseService.subscribeToUserBookings(userId);
  }
}
