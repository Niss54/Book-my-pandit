import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/booking_model.dart';
import '../../models/pandit_model.dart';
import '../../models/user_model.dart';
import '../repositories/booking_repository.dart';

abstract class ISupabaseService {
  Future<void> initialize();
  
  // User Management
  Future<void> upsertUserProfile(UserModel user);
  Future<String> getUserRole(String userId);
  Future<String> uploadProfilePicture(String userId, File imageFile);
  
  Future<List<PanditModel>> getPandits();
  
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

  Future<void> submitReview({
    required String bookingId,
    required String userId,
    required String panditId,
    required int rating,
    String? comment,
  });

  Future<List<BookingModel>> getUserBookings(String userId);

  Future<List<BookingModel>> getAllBookings();

  Stream<List<BookingModel>> subscribeToUserBookings(String userId);



  Stream<AuthState> get authStateChanges;
  User? get currentUser;
}
