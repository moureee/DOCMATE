import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:docmate/features/auth/screens/intro_screen.dart';
import 'package:docmate/features/patient/screens/patient_home.dart';
import 'package:docmate/features/doctor/screens/doctor_home.dart';
import 'package:docmate/features/admin/screens/admin_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> getStartScreen() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const IntroScreen();
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      await FirebaseAuth.instance.signOut();
      return const IntroScreen();
    }

    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

    String role = data['role'] ?? '';

    if (role == 'patient') {
      return const PatientHome();
    }

    if (role == 'doctor') {
      bool approved = data['approved'] ?? false;

      if (approved == true) {
        return const DoctorHome();
      } else {
        await FirebaseAuth.instance.signOut();
        return const IntroScreen();
      }
    }

    if (role == 'admin') {
      return const AdminHome();
    }

    await FirebaseAuth.instance.signOut();
    return const IntroScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE9FFF9),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D9B8),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return const IntroScreen();
      },
    );
  }
}
