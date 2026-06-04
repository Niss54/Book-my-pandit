import 'dart:async';

import 'package:book_my_pandit/domain/repositories/auth_repository.dart';
import 'package:book_my_pandit/domain/repositories/booking_repository.dart';
import 'package:book_my_pandit/domain/repositories/pandit_repository.dart';
import 'package:book_my_pandit/models/booking_model.dart';
import 'package:book_my_pandit/models/pandit_model.dart';
import 'package:book_my_pandit/models/user_model.dart';
import 'package:book_my_pandit/services/payment_gateway.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();
  UserModel? nextUser;
  Object? signInError;
  UserModel? signedInUser;
  bool signOutCalled = false;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  void emit(UserModel? user) {
    _controller.add(user);
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    if (signInError != null) {
      throw signInError!;
    }

    signedInUser = nextUser;
    if (nextUser != null) {
      emit(nextUser);
    }
    return nextUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    emit(null);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeBookingRepository implements BookingRepository {
  BookingModel? createdBooking;
  final List<Map<String, String>> statusUpdates = [];
  PaymentOrder? lastPaymentOrder;
  Map<String, String>? lastVerificationPayload;

  @override
  Future<PaymentOrder> createPaymentOrder({
    required String panditId,
    required String idempotencyKey,
  }) async {
    lastPaymentOrder = PaymentOrder(
      orderId: 'order_1',
      amountInPaise: 210000,
      currency: 'INR',
      idempotencyKey: idempotencyKey,
    );
    return lastPaymentOrder!;
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
    lastVerificationPayload = {
      'userId': userId,
      'panditId': panditId,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'idempotencyKey': idempotencyKey,
    };

    createdBooking = BookingModel(
      id: 'booking_1',
      userId: userId,
      panditId: panditId,
      date: date,
      status: BookingModel.statusConfirmed,
      amount: 2100,
      paymentReference: paymentId,
    );
    return createdBooking!;
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
    createdBooking = BookingModel(
      id: 'booking_1',
      userId: userId,
      panditId: panditId,
      date: date,
      status: status,
      amount: amount,
      paymentReference: paymentReference,
    );
    return createdBooking!;
  }

  @override
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String userId,
    required String status,
  }) async {
    statusUpdates.add({
      'bookingId': bookingId,
      'userId': userId,
      'status': status,
    });

    final booking = createdBooking;
    if (booking == null) {
      throw StateError('No booking to update');
    }

    createdBooking = BookingModel(
      id: booking.id,
      userId: booking.userId,
      panditId: booking.panditId,
      date: booking.date,
      status: status,
      amount: booking.amount,
      paymentReference: booking.paymentReference,
    );
    return createdBooking!;
  }
}

class FakePanditRepository implements PanditRepository {
  final List<PanditModel> pandits;

  FakePanditRepository(this.pandits);

  @override
  Future<List<PanditModel>> getActivePandits() async => pandits;
}

class FakePaymentGateway implements PaymentGateway {
  void Function(PaymentSuccessResponse)? _onSuccess;
  void Function(PaymentFailureResponse)? _onFailure;
  void Function(ExternalWalletResponse)? _onExternalWallet;
  void Function(String)? _onCheckoutError;

  int? amountInPaise;
  String? name;
  String? description;
  String? prefillEmail;
  String? prefillContact;
  String? orderId;
  bool disposed = false;

  @override
  set onSuccess(void Function(PaymentSuccessResponse)? callback) {
    _onSuccess = callback;
  }

  @override
  set onFailure(void Function(PaymentFailureResponse)? callback) {
    _onFailure = callback;
  }

  @override
  set onExternalWallet(void Function(ExternalWalletResponse)? callback) {
    _onExternalWallet = callback;
  }

  @override
  set onCheckoutError(void Function(String)? callback) {
    _onCheckoutError = callback;
  }

  @override
  void openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
    String? orderId,
  }) {
    this.amountInPaise = amountInPaise;
    this.name = name;
    this.description = description;
    this.prefillEmail = prefillEmail;
    this.prefillContact = prefillContact;
    this.orderId = orderId;
  }

  void triggerSuccess({
    String paymentId = 'pay_123',
    String orderId = 'order_1',
    String signature = 'signature_1',
  }) {
    _onSuccess?.call(
      PaymentSuccessResponse(paymentId, orderId, signature, null),
    );
  }

  void triggerFailure({String message = 'Payment failed'}) {
    _onFailure?.call(
      PaymentFailureResponse(0, message, null),
    );
  }

  void triggerCheckoutError(String error) {
    _onCheckoutError?.call(error);
  }

  void triggerExternalWallet({String walletName = 'wallet'}) {
    _onExternalWallet?.call(
      ExternalWalletResponse(walletName),
    );
  }

  @override
  void dispose() {
    disposed = true;
  }
}
