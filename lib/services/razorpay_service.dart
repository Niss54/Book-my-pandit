import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/app_config.dart';
import 'payment_gateway.dart';

class RazorpayService implements PaymentGateway {
  late Razorpay _razorpay;
   void Function(PaymentSuccessResponse)? _onSuccess;
   void Function(PaymentFailureResponse)? _onFailure;
   void Function(ExternalWalletResponse)? _onExternalWallet;
   void Function(String)? _onCheckoutError;

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
  
  RazorpayService() {
     _razorpay = Razorpay();
     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
   @override
   void openCheckout({required int amountInPaise, required String name, required String description, required String prefillEmail, required String prefillContact, String? orderId}) {
       if (!AppConfig.hasRazorpayKey) {
          _onCheckoutError?.call(
             'Missing RAZORPAY_KEY_ID. Pass it via --dart-define before checkout.',
          );
          return;
       }

       var options = {
             'key': AppConfig.razorpayKeyId,
         'amount': amountInPaise,
         'name': name,
         'description': description,
         'prefill': {
             'contact': prefillContact,
             'email': prefillEmail
         }
     };

       if (orderId != null && orderId.isNotEmpty) {
          options['order_id'] = orderId;
       }
     
     try {
        _razorpay.open(options);
     } catch (e) {
       _onCheckoutError?.call('Unable to open Razorpay checkout.');
     }
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
     _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
     _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
     _onExternalWallet?.call(response);
  }
  
   @override
   void dispose() {
     _razorpay.clear();
  }
}
