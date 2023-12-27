import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

@immutable
class AuthUser {
<<<<<<< HEAD
  final String id;
  final String email;
  final bool isEmailVerified;
  const AuthUser({
    required this.id,
=======
  final String? email;
  final bool isEmailVerified;
  const AuthUser({
>>>>>>> eaafe14d6c4b837196a299be73278885ed2adf74
    required this.email,
    required this.isEmailVerified,
  });

  factory AuthUser.fromFirebase(User user) => AuthUser(
<<<<<<< HEAD
        id: user.uid,
        email: user.email!,
=======
        email: user.email,
>>>>>>> eaafe14d6c4b837196a299be73278885ed2adf74
        isEmailVerified: user.emailVerified,
      );
}
