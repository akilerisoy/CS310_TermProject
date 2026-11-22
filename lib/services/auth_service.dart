import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

/// Error with a message that is safe to show under a field.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

/// The signed-in user, for both Firebase and demo mode.
class AppUser {
  final String uid;
  final String name;
  final String email;
  const AppUser({required this.uid, required this.name, required this.email});

  factory AppUser.fromFirebase(User u) =>
      AppUser(uid: u.uid, name: u.displayName ?? '', email: u.email ?? '');
}

class AuthService {
  /// [demo] is true when Firebase is not configured. Then log in and sign up
  /// only work on this device and the app shows placeholder data.
  AuthService({this.demo = false});
  final bool demo;

  // A getter, so FirebaseAuth is never touched in demo mode.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  final _demoUser = StreamController<AppUser?>.broadcast();
  AppUser? _demoCurrent;

  Stream<AppUser?> get userChanges {
    if (!demo) return _auth.authStateChanges().map((u) => u == null ? null : AppUser.fromFirebase(u));
    return () async* {
      yield _demoCurrent;
      yield* _demoUser.stream;
    }();
  }

  void _setDemoUser(AppUser? u) {
    _demoCurrent = u;
    _demoUser.add(u);
  }

  Future<void> logIn(String email, String password) async {
    if (demo) {
      final e = email.trim();
      return _setDemoUser(AppUser(uid: 'demo', name: e.split('@').first, email: e));
    }
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    if (demo) {
      return _setDemoUser(AppUser(uid: 'demo', name: name.trim(), email: email.trim()));
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'settings': const AppSettings().toMap(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<void> sendReset(String email) async {
    if (demo) return;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether the address has an account.
      if (e.code == 'user-not-found') return;
      throw AuthFailure(_message(e));
    }
  }

  Future<void> logOut() async {
    if (demo) return _setDemoUser(null);
    await _auth.signOut();
  }

  void dispose() => _demoUser.close();

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'Wrong email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
