import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? lastError;

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      lastError = null;
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      lastError = null;
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      lastError = null;
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = kIsWeb
          ? await _auth.signInWithPopup(googleProvider)
          : await _auth.signInWithProvider(googleProvider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  /// GitHub OAuth using FirebaseAuth OAuth provider.
  Future<User?> signInWithGitHub() async {
    try {
      lastError = null;
      final provider = OAuthProvider('github.com');
      provider.addScope('read:user');
      provider.addScope('user:email');

      final userCredential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      lastError = e.message;
      return null;
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
