import 'package:flutter/material.dart';
import '../../services/payment_gateway.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../models/booking_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutRequest {
  final String userId;
  final String panditId;
  final DateTime scheduledAt;
  final int amount;
  final String payerName;
  final String payerEmail;
  final String payerPhone;

  const CheckoutRequest({
    required this.userId,
    required this.panditId,
    required this.scheduledAt,
    required this.amount,
    required this.payerName,
    required this.payerEmail,
    required this.payerPhone,
  });
}

class BookingProvider extends ChangeNotifier {
  final PaymentGateway _paymentGateway;
  final BookingRepository _bookingRepository;
  bool _isProcessing = false;
  String? _lastPaymentId;
  String? _lastBookingId;
  String? _errorMessage;
  BookingModel? _lastBooking;
  CheckoutRequest? _pendingRequest;
  String? _pendingIdempotencyKey;

  BookingProvider(this._paymentGateway, this._bookingRepository) {
    _paymentGateway.onSuccess = _handlePaymentSuccess;
    _paymentGateway.onFailure = _handlePaymentError;
    _paymentGateway.onExternalWallet = _handleExternalWallet;
    _paymentGateway.onCheckoutError = _handleCheckoutError;
  }

  bool get isProcessing => _isProcessing;
  String? get lastPaymentId => _lastPaymentId;
  String? get lastBookingId => _lastBookingId;
  String? get errorMessage => _errorMessage;
  BookingModel? get lastBooking => _lastBooking;

  void clearTransientMessages() {
    _errorMessage = null;
    _lastBookingId = null;
    notifyListeners();
  }

  Future<void> initiateCheckout(CheckoutRequest request) async {
    _pendingRequest = request;
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();

    final idempotencyKey = _buildIdempotencyKey(request);
    _pendingIdempotencyKey = idempotencyKey;

    try {
      final order = await _bookingRepository.createPaymentOrder(
        panditId: request.panditId,
        idempotencyKey: idempotencyKey,
      );

      _paymentGateway.openCheckout(
        amountInPaise: order.amountInPaise,
        name: request.payerName,
        description: 'Pandit Booking',
        prefillEmail: request.payerEmail,
        prefillContact: request.payerPhone,
        orderId: order.orderId,
      );
    } catch (_) {
      _isProcessing = false;
      _errorMessage = 'Unable to initialize payment. Please try again.';
      notifyListeners();
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final pending = _pendingRequest;
    final idempotencyKey = _pendingIdempotencyKey;
    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;

    if (pending == null || idempotencyKey == null) {
      _isProcessing = false;
      _errorMessage = 'Checkout request not found. Please try again.';
      notifyListeners();
      return;
    }

    if (paymentId == null || orderId == null || signature == null) {
      _isProcessing = false;
      _errorMessage = 'Payment response was incomplete. Please contact support.';
      notifyListeners();
      return;
    }

    try {
      final booking = await _bookingRepository.verifyPaymentAndConfirmBooking(
        userId: pending.userId,
        panditId: pending.panditId,
        date: pending.scheduledAt,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        idempotencyKey: idempotencyKey,
      );
      _lastBooking = booking;
      _lastBookingId = booking.id;
      _lastPaymentId = paymentId;
      _pendingRequest = null;
      _pendingIdempotencyKey = null;
      _isProcessing = false;
      notifyListeners();
    } catch (_) {
      _isProcessing = false;
      _errorMessage = 'Payment verification failed. If debited, contact support.';
      notifyListeners();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessing = false;
    _errorMessage = response.message ?? 'Payment failed. Please try again.';
    notifyListeners();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessing = false;
    notifyListeners();
  }

  void _handleCheckoutError(String error) {
    _isProcessing = false;
    _errorMessage = error;
    notifyListeners();
  }

  String _buildIdempotencyKey(CheckoutRequest request) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final schedule = request.scheduledAt.millisecondsSinceEpoch;
    return '${request.userId}_${request.panditId}_${schedule}_$now';
  }

  Future<void> markBookingCompleted({required String bookingId, required String userId}) async {
    if (_lastBooking == null || !_lastBooking!.canTransitionTo(BookingModel.statusCompleted)) {
      _errorMessage = 'Invalid booking state transition.';
      notifyListeners();
      return;
    }

    _lastBooking = await _bookingRepository.updateBookingStatus(
      bookingId: bookingId,
      userId: userId,
      status: BookingModel.statusCompleted,
    );
    notifyListeners();
  }

  Future<void> cancelBooking({required String bookingId, required String userId}) async {
    if (_lastBooking == null || !_lastBooking!.canTransitionTo(BookingModel.statusCancelled)) {
      _errorMessage = 'Invalid booking state transition.';
      notifyListeners();
      return;
    }

    _lastBooking = await _bookingRepository.updateBookingStatus(
      bookingId: bookingId,
      userId: userId,
      status: BookingModel.statusCancelled,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentGateway.dispose();
    super.dispose();
  }
}