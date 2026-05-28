import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? lastError;

  Future<User?> signUp({
    required String email,

    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      lastError = null;
      return userCredential.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        lastError = e.message;
      } else {
        lastError = e.toString();
      }
      return null;
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,

        password: password,
      );
      lastError = null;
      return userCredential.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        lastError = e.message;
      } else {
        lastError = e.toString();
      }
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
