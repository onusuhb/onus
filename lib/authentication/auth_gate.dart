import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onus/CompanyHomeScreen.dart';
import 'package:onus/dashboard_page.dart';
import '../home_screen.dart';
 import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getHomeScreen(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? '';

        if (role == 'Customer') {
          return HomeScreen();
        } else if (role == 'Company') {
          return CompanyHomeScreen();
        }
        else if (role == 'Admin') {
          return DashboardPage();
        }
      }
      return const LoginScreen(); 
    } catch (e) {
      return const LoginScreen(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<Widget>(
              future: _getHomeScreen(snapshot.data!), 
              builder: (context, homeSnapshot) {
                if (homeSnapshot.connectionState == ConnectionState.done) {
                  return homeSnapshot.data ?? const LoginScreen();
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
