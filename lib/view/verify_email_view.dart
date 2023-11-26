import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants/routes.dart';

class VerifiedEmailView extends StatefulWidget {
  const VerifiedEmailView({super.key});

  @override
  State<VerifiedEmailView> createState() => _VerifiedEmailViewState();
}

class _VerifiedEmailViewState extends State<VerifiedEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Column(children: [
        const Text(
          'Email Verification Sent. Open your Email to Verify',
        ),
        const Text(
          "Please press the button below if you didn't receive an Email Verification",
        ),
        TextButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            await user?.sendEmailVerification();
          },
          child: const Text('Send Email Verification'),
        ),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerView,
                (route) => false,
              );
            }
          },
          child: const Text('Restart'),
        ),
      ]),
    );
  }
}
