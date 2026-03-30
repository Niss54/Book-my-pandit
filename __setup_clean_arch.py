import os
import textwrap

base_path = r'c:\Users\nisha\.gemini\antigravity\brain\53dee077-a903-4465-b78e-d8eb54238de4\may be imp\book_my_pandit'
files = {
    'lib/models/user_model.dart': '''
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;

  UserModel({required this.id, required this.email, required this.name, this.profilePictureUrl});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(id: json['id'], email: json['email'], name: json['name'], profilePictureUrl: json['profile_picture_url']);
}
''',
    'lib/models/pandit_model.dart': '''
class PanditModel {
  final String id;
  final String name;
  final String expertise;
  final double rating;
  final int basePrice;
  final String imageUrl;

  PanditModel({required this.id, required this.name, required this.expertise, required this.rating, required this.basePrice, required this.imageUrl});
  
  factory PanditModel.fromJson(Map<String, dynamic> json) => PanditModel(id: json['id'], name: json['name'], expertise: json['expertise'], rating: (json['rating'] as num).toDouble(), basePrice: json['base_price'], imageUrl: json['image_url']);
}
''',
    'lib/models/booking_model.dart': '''
class BookingModel {
  final String id;
  final String userId;
  final String panditId;
  final DateTime date;
  final String status;
  final int amount;

  BookingModel({required this.id, required this.userId, required this.panditId, required this.date, required this.status, required this.amount});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(id: json['id'], userId: json['user_id'], panditId: json['pandit_id'], date: DateTime.parse(json['date']), status: json['status'], amount: json['amount']);
}
''',
    'lib/domain/repositories/auth_repository.dart': '''
import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> get authStateChanges;
}
''',
    'lib/data/repositories/auth_repository_impl.dart': '''
import '../../domain/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../services/google_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  Future<UserModel?> signInWithGoogle() async {
    final user = await _googleAuthService.signIn();
    if (user != null) {
       return UserModel(id: user.uid, email: user.email, name: user.name, profilePictureUrl: user.photoUrl);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _googleAuthService.signOut();
    await _supabaseClient.auth.signOut();
  }

  @override
  Stream<UserModel?> get authStateChanges {
     return _supabaseClient.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        if (user == null) return null;
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] ?? '',
          profilePictureUrl: user.userMetadata?['avatar_url'],
        );
     });
  }
}
''',
    'lib/services/google_auth_service.dart': '''
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthUser {
   final String uid;
   final String email;
   final String name;
   final String? photoUrl;
   
   GoogleAuthUser({required this.uid, required this.email, required this.name, this.photoUrl});
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
     scopes: ['email', 'profile'],
  );

  Future<GoogleAuthUser?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final AuthResponse res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: auth.idToken!,
        accessToken: auth.accessToken,
      );
      
      if (res.user != null) {
          return GoogleAuthUser(
            uid: res.user!.id,
            email: res.user!.email ?? account.email,
            name: account.displayName ?? 'User',
            photoUrl: account.photoUrl,
          );
      }
      return null;
    } catch (e) {
      print('Google sign in failed: ');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
''',
    'lib/services/razorpay_service.dart': '''
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
''',
    'lib/services/supabase_service.dart': '''
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
     // TODO: Replace with real credentials in production
     await Supabase.initialize(
       url: 'YOUR_SUPABASE_URL',
       anonKey: 'YOUR_SUPABASE_ANON_KEY',
     );
  }

  static Future<List<dynamic>> getPandits() async {
    try {
      final response = await client.from('pandits').select();
      return response as List<dynamic>;
    } catch (e) {
      print( Error fetching pandits: );
      return [];
    }
  }
}
'''
}

for path, content in files.items():
    full_path = os.path.join(base_path, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\\n')
print('Files created successfully.')
