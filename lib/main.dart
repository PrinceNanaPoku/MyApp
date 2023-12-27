import 'package:flutter/material.dart';
import 'package:myapp/constants/routes.dart';
import 'package:myapp/services/auth/auth_service.dart';
import 'package:myapp/view/login_view.dart';
import 'package:myapp/view/notes/create_update_new_note_view.dart';
import 'package:myapp/view/notes/notes_view.dart';
import 'package:myapp/view/register_view.dart';
import 'package:myapp/view/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const HomePage(),
    routes: {
      loginView: (context) => const LoginView(),
      registerView: (context) => const RegisterView(),
      notesView: (context) => const NotesView(),
      verifyEmailView: (context) => const VerifiedEmailView(),
      createOrUpdateNotesView: (context) => const CreateUpdateNewNotesView()
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                if (user.isEmailVerified) {
                  return const NotesView();
                } else {
                  return const VerifiedEmailView();
                }
              } else {
                return const LoginView();
              }
            default:
              return const CircularProgressIndicator();
          }
        });
  }
}
