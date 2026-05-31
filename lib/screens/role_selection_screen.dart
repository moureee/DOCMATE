import 'package:flutter/material.dart';
import 'auth_screens.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void openLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthLoginScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'USER SELECTION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 25),
              userCard(
                imagePath: 'assets/images/doctor_intro.jpg',
                title: 'Doctor',
                onPressed: () {
                  openLogin(context, 'doctor');
                },
              ),
              const SizedBox(height: 28),
              userCard(
                imagePath: 'assets/images/patient_intro.jpg',
                title: 'Patient',
                onPressed: () {
                  openLogin(context, 'patient');
                },
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  openLogin(context, 'admin');
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin Login'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget userCard({
    required String imagePath,
    required String title,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 175,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF00D9B8),
              width: 6,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9B8).withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imagePath,
                width: 165,
                height: 125,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: const Color(0xFF00D9B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: Color(0xFF00D9B8),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
