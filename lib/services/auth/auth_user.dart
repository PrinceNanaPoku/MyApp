import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

@immutable
class AuthUser {
  final bool isEmailVerified;
  const AuthUser({
    required this.isEmailVerified,
  });

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerified: user.emailVerified);
}
