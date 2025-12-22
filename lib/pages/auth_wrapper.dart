import 'package:alignme/pages/home_root.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // إذا في يوزر → فوتي على التطبيق
        if (snapshot.hasData) {
          return const MainShell();
        }

        // إذا ما في → تسجيل دخول
        return const LoginScreen();
      },
    );
  }
}
