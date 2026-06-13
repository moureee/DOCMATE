import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'patient_home.dart';
import 'doctor_home.dart';
import 'admin_home.dart';

Future<UserCredential> signInWithGoogleFirebase() async {
  if (kIsWeb) {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    return await FirebaseAuth.instance.signInWithPopup(googleProvider);
  } else {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

Future<void> createUserRecords({
  required User user,
  required String role,
  required String firstName,
  required String lastName,
  String specialty = 'Not set',
  String loginMethod = 'email',
}) async {
  String fullName = '$firstName $lastName'.trim();

  if (fullName.isEmpty) {
    fullName = role == 'doctor' ? 'New Doctor' : 'New Patient';
  }

  String email = user.email ?? '';
  String phone = user.phoneNumber ?? '';

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'uid': user.uid,
    'firstName': firstName,
    'lastName': lastName,
    'name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'loginMethod': loginMethod,
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
    if (role == 'doctor') 'specialty': specialty,
    if (role == 'doctor') 'designation': specialty,
    if (role == 'doctor') 'approved': false,
  });

  if (role == 'patient') {
    await FirebaseFirestore.instance
        .collection('health_profiles')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'height': '',
      'weight': '',
      'allergies': '',
      'bloodGroup': '',
      'doctorIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  if (role == 'doctor') {
    await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
      'uid': user.uid,
      'name': fullName,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'designation': specialty,
      'rating': 0.0,
      'ratingAverage': 0.0,
      'ratingCount': 0,
      'available': true,
      'availableSlots': <String>[],
      'averageConsultationMinutes': 12,
      'approved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

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

      await handleExistingUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login failed');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> googleLogin() async {
    if (widget.role == 'admin') {
      showMessage('Admin must login with email and password only');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential = await signInWithGoogleFirebase();

      User? user = userCredential.user;

      if (user == null) {
        showMessage('Google login failed');
        return;
      }

      await handleExistingUser(user);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Google login failed');
    } catch (e) {
      showMessage('Google login cancelled or failed');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void openPhoneLogin() {
    if (widget.role == 'admin') {
      showMessage('Admin must login with email and password only');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneAuthScreen(
          role: widget.role,
          mode: 'login',
        ),
      ),
    );
  }

  Future<void> handleExistingUser(User user) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      showMessage('No account found. Please register first.');
      await FirebaseAuth.instance.signOut();
      return;
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String savedRole = userData['role'] ?? '';

    if (savedRole != widget.role) {
      showMessage('This account is registered as $savedRole');
      await FirebaseAuth.instance.signOut();
      return;
    }

    if (savedRole == 'doctor') {
      bool approved = userData['approved'] ?? false;

      if (approved == false) {
        showMessage('Your doctor account is waiting for admin approval');
        await FirebaseAuth.instance.signOut();
        return;
      }

      openHome(const DoctorHome());
    } else if (savedRole == 'admin') {
      openHome(const AdminHome());
    } else if (savedRole == 'patient') {
      openHome(const PatientHome());
    } else {
      showMessage('Invalid user role');
      await FirebaseAuth.instance.signOut();
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
                  title: 'LOGIN WITH EMAIL',
                  onPressed: loginUser,
                ),
          const SizedBox(height: 25),
          const Text(
            'OR LOGIN WITH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialCircleButton(
                text: 'G',
                color: Colors.red,
                onTap: isLoading ? null : googleLogin,
              ),
              const SizedBox(width: 22),
              SocialCircleButton(
                text: '☎',
                color: const Color(0xFF00D9B8),
                onTap: isLoading ? null : openPhoneLogin,
              ),
            ],
          ),
          const SizedBox(height: 30),
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

  Future<void> registerWithEmail() async {
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

      User user = userCredential.user!;

      await createUserRecords(
        user: user,
        role: widget.role,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        specialty: specialtyController.text.trim(),
        loginMethod: 'email',
      );

      if (widget.role == 'patient') {
        showMessage('Patient account created successfully');
        openHome(const PatientHome());
      } else {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage('Doctor account created. Please wait for admin approval.');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Signup failed');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> registerWithGoogle() async {
    if (widget.role == 'doctor' && specialtyController.text.isEmpty) {
      showMessage('Please enter specialty/designation first');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential = await signInWithGoogleFirebase();
      User? user = userCredential.user;

      if (user == null) {
        showMessage('Google signup failed');
        return;
      }

      DocumentSnapshot existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (existingDoc.exists) {
        showMessage('Account already exists. Please login.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      String displayName = user.displayName ?? 'Google User';
      List<String> nameParts = displayName.split(' ');

      String firstName = nameParts.isNotEmpty ? nameParts.first : 'Google';
      String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

      await createUserRecords(
        user: user,
        role: widget.role,
        firstName: firstName,
        lastName: lastName,
        specialty: specialtyController.text.trim(),
        loginMethod: 'google',
      );

      if (widget.role == 'patient') {
        showMessage('Patient Google account created');
        openHome(const PatientHome());
      } else {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage(
          'Doctor Google account created. Please wait for admin approval.',
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Google signup failed');
    } catch (e) {
      showMessage('Google signup cancelled or failed');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void openPhoneSignup() {
    if (widget.role == 'doctor' && specialtyController.text.isEmpty) {
      showMessage('Please enter specialty/designation first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneAuthScreen(
          role: widget.role,
          mode: 'signup',
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          specialty: specialtyController.text.trim(),
        ),
      ),
    );
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
          const SizedBox(height: 22),
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
          const SizedBox(height: 24),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF00D9B8))
              : AuthButton(
                  title: 'SIGNUP WITH EMAIL',
                  onPressed: registerWithEmail,
                ),
          const SizedBox(height: 22),
          const Text(
            'OR SIGNUP WITH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialCircleButton(
                text: 'G',
                color: Colors.red,
                onTap: isLoading ? null : registerWithGoogle,
              ),
              const SizedBox(width: 22),
              SocialCircleButton(
                text: '☎',
                color: const Color(0xFF00D9B8),
                onTap: isLoading ? null : openPhoneSignup,
              ),
            ],
          ),
          const SizedBox(height: 28),
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

class PhoneAuthScreen extends StatefulWidget {
  final String role;
  final String mode;
  final String firstName;
  final String lastName;
  final String specialty;

  const PhoneAuthScreen({
    super.key,
    required this.role,
    required this.mode,
    this.firstName = '',
    this.lastName = '',
    this.specialty = '',
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String verificationId = '';
  ConfirmationResult? webConfirmationResult;

  bool codeSent = false;
  bool isLoading = false;

  Future<void> sendOtp() async {
    String phone = phoneController.text.trim();

    if (!phone.startsWith('+')) {
      showMessage(
          'Enter phone number with country code. Example: +8801XXXXXXXXX');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      if (kIsWeb) {
        webConfirmationResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(phone);

        setState(() {
          codeSent = true;
        });

        showMessage('OTP sent');
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            UserCredential userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);

            if (userCredential.user != null) {
              await completePhoneAuth(userCredential.user!);
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            showMessage(e.message ?? 'Phone verification failed');
          },
          codeSent: (String id, int? resendToken) {
            setState(() {
              verificationId = id;
              codeSent = true;
            });

            showMessage('OTP sent');
          },
          codeAutoRetrievalTimeout: (String id) {
            verificationId = id;
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Failed to send OTP');
    } catch (e) {
      showMessage('Failed to send OTP');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) {
      showMessage('Please enter OTP');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential;

      if (kIsWeb) {
        userCredential =
            await webConfirmationResult!.confirm(otpController.text.trim());
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otpController.text.trim(),
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      User? user = userCredential.user;

      if (user == null) {
        showMessage('Phone authentication failed');
        return;
      }

      await completePhoneAuth(user);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Invalid OTP');
    } catch (e) {
      showMessage('Invalid OTP or verification failed');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> completePhoneAuth(User user) async {
    DocumentSnapshot existingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (widget.mode == 'login') {
      if (!existingDoc.exists) {
        showMessage('No phone account found. Please signup first.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      Map<String, dynamic> data = existingDoc.data() as Map<String, dynamic>;
      String savedRole = data['role'] ?? '';

      if (savedRole != widget.role) {
        showMessage('This phone account is registered as $savedRole');
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (savedRole == 'doctor') {
        bool approved = data['approved'] ?? false;

        if (approved == false) {
          showMessage('Your doctor account is waiting for admin approval');
          await FirebaseAuth.instance.signOut();
          return;
        }

        openHome(const DoctorHome());
        return;
      }

      if (savedRole == 'patient') {
        openHome(const PatientHome());
        return;
      }

      showMessage('Invalid role for phone login');
      await FirebaseAuth.instance.signOut();
      return;
    }

    if (widget.mode == 'signup') {
      if (existingDoc.exists) {
        showMessage('Phone account already exists. Please login.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      String firstName = widget.firstName.isEmpty ? 'Phone' : widget.firstName;
      String lastName = widget.lastName.isEmpty ? 'User' : widget.lastName;

      await createUserRecords(
        user: user,
        role: widget.role,
        firstName: firstName,
        lastName: lastName,
        specialty: widget.specialty.isEmpty ? 'Not set' : widget.specialty,
        loginMethod: 'phone',
      );

      if (widget.role == 'patient') {
        showMessage('Patient phone account created');
        openHome(const PatientHome());
        return;
      }

      if (widget.role == 'doctor') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage(
          'Doctor phone account created. Please wait for admin approval.',
        );
        Navigator.pop(context);
        return;
      }
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
    String title = widget.mode == 'signup'
        ? '${widget.role.toUpperCase()} PHONE SIGNUP'
        : '${widget.role.toUpperCase()} PHONE LOGIN';

    return AuthPageBackground(
      child: Column(
        children: [
          AuthHeader(title: title),
          const SizedBox(height: 35),
          const Text(
            'Enter phone number with country code',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: phoneController,
            hintText: 'Phone: +8801XXXXXXXXX',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          if (codeSent)
            AuthTextField(
              controller: otpController,
              hintText: 'Enter OTP',
              icon: Icons.lock_outline,
              keyboardType: TextInputType.number,
            ),
          const SizedBox(height: 30),
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF00D9B8))
              : AuthButton(
                  title: codeSent ? 'VERIFY OTP' : 'SEND OTP',
                  onPressed: codeSent ? verifyOtp : sendOtp,
                ),
          const SizedBox(height: 20),
          const Text(
            'For testing, you can add a test phone number in Firebase Authentication phone provider settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
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

      if (!mounted) return;

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
              child: child,
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
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
      width: 245,
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

class SocialCircleButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const SocialCircleButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
