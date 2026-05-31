import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'patient_home.dart';
import 'doctor_home.dart';
import 'admin_home.dart';

class AuthLoginScreen extends StatefulWidget {
  final String role;

  const AuthLoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showMessage('Please enter email and password');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        showMessage('User data not found in Firestore');
        return;
      }

      String savedRole = userDoc['role'];

      if (savedRole != widget.role) {
        showMessage('This account is registered as $savedRole');
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (savedRole == 'doctor') {
        openHome(const DoctorHome());
      } else if (savedRole == 'admin') {
        openHome(const AdminHome());
      } else {
        openHome(const PatientHome());
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login failed');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void openHome(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void openSignup() {
    if (widget.role == 'admin') {
      showMessage('Admin account must be created manually in Firebase');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthSignupScreen(role: widget.role),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageBackground(
      child: Column(
        children: [
          AuthHeader(title: '${widget.role.toUpperCase()} LOGIN'),
          const SizedBox(height: 35),
          AuthTextField(
            controller: emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 15),
          AuthTextField(
            controller: passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF00D9B8))
              : AuthButton(
                  title: 'LOGIN',
                  onPressed: loginUser,
                ),
          const SizedBox(height: 35),
          const Text(
            'OR LOGIN WITH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'G',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 12),
              ),
              GestureDetector(
                onTap: openSignup,
                child: const Text(
                  'Register now',
                  style: TextStyle(
                    color: Color(0xFF00D9B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class AuthSignupScreen extends StatefulWidget {
  final String role;

  const AuthSignupScreen({
    super.key,
    required this.role,
  });

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final specialtyController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> registerUser() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    if (widget.role == 'doctor' && specialtyController.text.isEmpty) {
      showMessage('Please enter specialty/designation');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Passwords do not match');
      return;
    }

    if (passwordController.text.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      String fullName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'name': fullName,
        'email': emailController.text.trim(),
        'role': widget.role,
        'createdAt': DateTime.now(),
      });

      if (widget.role == 'doctor') {
        await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
          'uid': uid,
          'name': fullName,
          'email': emailController.text.trim(),
          'specialty': specialtyController.text.trim(),
          'designation': specialtyController.text.trim(),
          'rating': 4.5,
          'available': true,
          'approved': false,
          'createdAt': DateTime.now(),
        });
      }

      if (widget.role == 'patient') {
        await FirebaseFirestore.instance
            .collection('health_profiles')
            .doc(uid)
            .set({
          'uid': uid,
          'height': '',
          'weight': '',
          'allergies': '',
          'bloodGroup': '',
          'createdAt': DateTime.now(),
        });
      }

      showMessage('${widget.role} account created successfully');

      if (widget.role == 'doctor') {
        openHome(const DoctorHome());
      } else {
        openHome(const PatientHome());
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Signup failed');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void openHome(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDoctor = widget.role == 'doctor';

    return AuthPageBackground(
      child: Column(
        children: [
          AuthHeader(
            title: isDoctor ? 'DOCTOR SIGNUP' : 'PATIENT SIGNUP',
          ),
          const SizedBox(height: 25),
          AuthTextField(
            controller: firstNameController,
            hintText: 'First name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: lastNameController,
            hintText: 'Last name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
          ),
          if (isDoctor) ...[
            const SizedBox(height: 12),
            AuthTextField(
              controller: specialtyController,
              hintText: 'Specialty / Designation',
              icon: Icons.work_outline,
            ),
          ],
          const SizedBox(height: 12),
          AuthTextField(
            controller: passwordController,
            hintText: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 28),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF00D9B8))
              : AuthButton(
                  title: 'SIGNUP',
                  onPressed: registerUser,
                ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 12),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF00D9B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  Future<void> sendResetEmail() async {
    if (emailController.text.isEmpty) {
      showMessage('Please enter your email');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      showMessage('Password reset email sent');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Failed to send reset email');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageBackground(
      child: Column(
        children: [
          const AuthHeader(title: 'FORGOT PASSWORD'),
          const SizedBox(height: 35),
          const Text(
            'Enter your registered email address\nto reset your password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 35),
          AuthTextField(
            controller: emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 60),
          AuthButton(
            title: 'SEND',
            onPressed: sendResetEmail,
          ),
        ],
      ),
    );
  }
}

class AuthPageBackground extends StatelessWidget {
  final Widget child;

  const AuthPageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 360,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 35,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title;

  const AuthHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFFF),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 14),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const AuthButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 48,
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
