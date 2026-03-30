import 'package:flutter/material.dart';
import '../../services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
class BookingProvider extends ChangeNotifier {
  final RazorpayService _razorpayService;
  bool _isProcessing = false;
  String? _lastPaymentId;
  BookingProvider(this._razorpayService) {
    _razorpayService.onSuccess = _handlePaymentSuccess;
    _razorpayService.onFailure = _handlePaymentError;
    _razorpayService.onExternalWallet = _handleExternalWallet;
  }
  bool get isProcessing => _isProcessing;
  String? get lastPaymentId => _lastPaymentId;
  void initiateCheckout({required int amount, required String name, required String email, required String phone}) {
    _isProcessing = true; notifyListeners();
    _razorpayService.openCheckout(amountInPaise: amount * 100, name: name, description: 'Pandit Booking', prefillEmail: email, prefillContact: phone);
  }
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isProcessing = false; _lastPaymentId = response.paymentId; notifyListeners();
  }
  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessing = false; notifyListeners();
  }
  void _handleExternalWallet(ExternalWalletResponse response) {
    _isProcessing = false; notifyListeners();
  }
}