import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'authentication/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _ensureAdminExists();   

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: AuthGate(),  
    );
  }
}

Future<void> _ensureAdminExists() async {
  const String adminEmail = "admin1@admin.com";
  const String adminPassword = "123456";

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
     final QuerySnapshot result = await firestore
        .collection('users')
        .where('email', isEqualTo: adminEmail)
        .limit(1)
        .get();

    if (result.docs.isEmpty) {
       UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

       await firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': 'Admin User',
        'email': adminEmail,
        'role': 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
        'accepted':true
      });

      print("Admin account created successfully.");
    } else {
      print("Admin account already exists.");
    }
  } catch (e) {
    print("Error ensuring admin account: $e");
  }
}
