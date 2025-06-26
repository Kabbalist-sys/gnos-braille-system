import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final FirebaseAuth? auth;

  const AuthWrapper({super.key, required this.child, this.auth});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = auth ?? FirebaseAuth.instance;

    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is signed in
          return child;
        } else {
          // User is not signed in
          return const LoginScreen();
        }
      },
    );
  }
}
