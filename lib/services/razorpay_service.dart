import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;
  
  RazorpayService() {
     _razorpay = Razorpay();
     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  void openCheckout({required int amountInPaise, required String name, required String description, required String prefillEmail, required String prefillContact}) {
     var options = {
         'key': 'YOUR_RAZORPAY_TEST_KEY',
         'amount': amountInPaise,
         'name': name,
         'description': description,
         'prefill': {
             'contact': prefillContact,
             'email': prefillEmail
         }
     };
     
     try {
        _razorpay.open(options);
     } catch (e) {
         print('Error: ');
     }
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
     if (onSuccess != null) onSuccess!(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
     if (onFailure != null) onFailure!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
     if (onExternalWallet != null) onExternalWallet!(response);
  }
  
  void dispose() {
     _razorpay.clear();
  }
}
