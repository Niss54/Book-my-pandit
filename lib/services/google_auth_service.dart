import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthUser {
   final String uid; final String email; final String name; final String? photoUrl;
   GoogleAuthUser({required this.uid, required this.email, required this.name, this.photoUrl});
}

class GoogleAuthService {
  Future<GoogleAuthUser?> signIn() async {
    try {
      final success = await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
      if (!success) return null;
    } catch (e) {
      print('Google sign in failed ' + e.toString());
    }
    return null;
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
