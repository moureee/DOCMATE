import 'dart:async';
import 'package:flutter/material.dart';
import 'package:docmate/features/auth/screens/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthGate(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFE),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: 170,
                color: const Color(0xFF9FF5E5),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 160,
                color: const Color(0xFF9FF5E5),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.jpg',
                    width: 230,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Bridging Patients & Doctors with Smart Care',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    color: Color(0xFF00D9B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height * 0.45);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(0, size.height * 0.45);
    path.quadraticBezierTo(
      size.width * 0.45,
      0,
      size.width,
      size.height * 0.35,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
