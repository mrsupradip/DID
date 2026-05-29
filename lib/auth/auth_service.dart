import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? lastError;
  static bool _googleSignInInitialized = false;

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
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      }

      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleSignInInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      lastError = e.message;
      return null;
    } on GoogleSignInException catch (e) {
      lastError = e.code == GoogleSignInExceptionCode.canceled
          ? 'Google sign-in was cancelled.'
          : e.toString();
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
