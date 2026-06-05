import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/services/i_supabase_service.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../config/app_config.dart';
import '../../models/booking_model.dart';
import '../../models/pandit_model.dart';
import '../../models/user_model.dart';

class SupabaseServiceImpl implements ISupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  @override
  Future<void> initialize() async {
     if (!AppConfig.hasSupabaseConfig) {
       throw StateError(
         'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Pass them via --dart-define.',
       );
     }

     await Supabase.initialize(
       url: AppConfig.supabaseUrl,
       anonKey: AppConfig.supabaseAnonKey,
     );
  }

  @override
  Future<void> upsertUserProfile(UserModel user) async {
    await client.from('users').upsert(user.toJson(), onConflict: 'id');
  }

  @override
  Future<List<PanditModel>> getPandits() async {
    final response = await client
        .from('pandits')
        .select()
        .eq('is_active', true)
        .order('rating', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(PanditModel.fromJson).toList();
  }

  @override
  Future<PaymentOrder> createPaymentOrder({
    required String panditId,
    required String idempotencyKey,
  }) async {
    final response = await client.functions.invoke(
      'create_payment_order',
      body: {
        'pandit_id': panditId,
        'idempotency_key': idempotencyKey,
      },
    );

    if (response.status != 200 && response.status != 201) {
      throw StateError('Unable to initialize payment order.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    return PaymentOrder(
      orderId: (data['order_id'] ?? '').toString(),
      amountInPaise: ((data['amount_in_paise'] ?? 0) as num).toInt(),
      currency: (data['currency'] ?? 'INR').toString(),
      idempotencyKey: (data['idempotency_key'] ?? idempotencyKey).toString(),
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
  }) async {
    final response = await client.functions.invoke(
      'verify_payment_and_confirm_booking',
      body: {
        'user_id': userId,
        'pandit_id': panditId,
        'scheduled_at': date.toIso8601String(),
        'payment_id': paymentId,
        'order_id': orderId,
        'signature': signature,
        'idempotency_key': idempotencyKey,
      },
    );

    if (response.status != 200 && response.status != 201) {
      throw StateError('Payment verification failed.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    return BookingModel.fromJson(data);
  }

  @override
  Future<BookingModel> createBooking({
    required String userId,
    required String panditId,
    required DateTime date,
    required int amount,
    required String status,
    String? paymentReference,
  }) async {
    final response = await client
        .from('bookings')
        .insert({
          'user_id': userId,
          'pandit_id': panditId,
          'date': date.toIso8601String(),
          'amount': amount,
          'status': status,
          'payment_reference': paymentReference,
        })
        .select()
        .single();

    return BookingModel.fromJson(response);
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String userId,
    required String status,
  }) async {
    final response = await client
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId)
        .eq('user_id', userId)
        .select()
        .single();

    return BookingModel.fromJson(response);
  }

  @override
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final response = await client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(BookingModel.fromJson).toList();
  }

  @override
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  @override
  User? get currentUser => client.auth.currentUser;
}
