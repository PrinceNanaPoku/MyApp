import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/constants/routes.dart';
import 'package:myapp/utilities/error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 8, top: 10, right: 8, bottom: 5),
            child: TextField(
              controller: _email,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  hintText: 'Enter your email here',
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  )),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 8, top: 10, right: 8, bottom: 20),
            child: TextField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                  hintText: "Enter your password here",
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  )),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
                if (context.mounted) {
                  Navigator.of(context).pushNamed(
                    verifyEmailView,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (e.code == 'weak-password') {
                  if (context.mounted) {
                    await showErrorDialog(
                      context,
                      'Weak Password',
                    );
                  }
                } else if (e.code == 'email-already-in-use') {
                  if (context.mounted) {
                    await showErrorDialog(
                      context,
                      'Email already in use',
                    );
                  }
                } else if (e.code == 'invalid-email') {
                  if (context.mounted) {
                    await showErrorDialog(
                      context,
                      'Invalid email',
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  await showErrorDialog(
                    context,
                    e.toString(),
                  );
                }
              }
            },
            child: const Text('Register'),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  loginView,
                  (route) => true,
                );
              },
              child: const Text('Already Registered? Login Here'))
        ],
      ),
    );
  }
}
