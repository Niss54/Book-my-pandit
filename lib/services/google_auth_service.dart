import 'dart:async';

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

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        return GoogleAuthUser(
          uid: currentUser.id,
          email: currentUser.email ?? '',
          name: (currentUser.userMetadata?['full_name'] ?? '').toString(),
          photoUrl: currentUser.userMetadata?['avatar_url']?.toString(),
        );
      }

      final oauthUser = await Supabase.instance.client.auth.onAuthStateChange
          .map((event) => event.session?.user)
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 90), onTimeout: () => null);

      if (oauthUser == null) return null;

      return GoogleAuthUser(
        uid: oauthUser.id,
        email: oauthUser.email ?? '',
        name: (oauthUser.userMetadata?['full_name'] ?? '').toString(),
        photoUrl: oauthUser.userMetadata?['avatar_url']?.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
