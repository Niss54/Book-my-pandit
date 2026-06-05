class GoogleAuthUser {
   final String uid; final String email; final String name; final String? photoUrl;
   GoogleAuthUser({required this.uid, required this.email, required this.name, this.photoUrl});
}

abstract class IAuthService {
  Future<GoogleAuthUser?> signIn();
  Future<void> signOut();
}
