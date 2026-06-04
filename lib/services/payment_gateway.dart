import 'package:razorpay_flutter/razorpay_flutter.dart';

abstract class PaymentGateway {
  set onSuccess(void Function(PaymentSuccessResponse)? callback);
  set onFailure(void Function(PaymentFailureResponse)? callback);
  set onExternalWallet(void Function(ExternalWalletResponse)? callback);
  set onCheckoutError(void Function(String)? callback);

  void openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
    String? orderId,
  });

  void dispose();
}
