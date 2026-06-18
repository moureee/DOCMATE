import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:docmate/features/patient/screens/patient_home.dart';
import 'package:docmate/features/doctor/screens/doctor_home.dart';
import 'package:docmate/features/admin/screens/admin_home.dart';
import 'package:docmate/core/utils/auth_validators.dart';

String friendlyAuthMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return AuthValidators.passwordHelp;
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'The email or password is incorrect.';
    case 'invalid-phone-number':
      return 'Enter a valid international phone number, for example +8801XXXXXXXXX.';
    case 'missing-phone-number':
      return 'Enter your phone number with the country code.';
    case 'quota-exceeded':
      return 'The SMS quota has been reached. Use a Firebase test number or try again later.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait before trying again.';
    case 'captcha-check-failed':
      return 'The security check failed. Refresh and try again.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled in Firebase.';
    case 'session-expired':
      return 'The OTP has expired. Request a new code.';
    case 'invalid-verification-code':
      return 'The OTP is incorrect.';
    default:
      final message = error.message ?? 'Authentication failed.';
      if (message.toLowerCase().contains('region')) {
        return 'SMS is blocked for this country. Enable the country in Firebase Authentication > Settings > SMS region policy.';
      }
      return message;
  }
}

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
  var fullName = '$firstName $lastName'.trim();
  if (fullName.isEmpty) {
    fullName = role == 'doctor' ? 'New Doctor' : 'New Patient';
  }

  final email = user.email ?? '';
  final phone = user.phoneNumber ?? '';
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  batch.set(firestore.collection('users').doc(user.uid), {
    'uid': user.uid,
    'firstName': firstName,
    'lastName': lastName,
    'name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'loginMethod': loginMethod,
    'isActive': true,
    'accountStatus': role == 'doctor' ? 'pending' : 'active',
    'createdAt': FieldValue.serverTimestamp(),
    if (role == 'doctor') 'specialty': specialty,
    if (role == 'doctor') 'designation': specialty,
    if (role == 'doctor') 'approved': false,
  });

  if (role == 'patient') {
    batch.set(firestore.collection('health_profiles').doc(user.uid), {
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
    batch.set(firestore.collection('doctors').doc(user.uid), {
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
      'weeklySchedule': <String, dynamic>{},
      'scheduleExceptions': <String, dynamic>{},
      'averageConsultationMinutes': 30,
      'approved': false,
      'accountStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  if (role == 'doctor') {
    final adminSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    final notificationBatch = firestore.batch();
    for (final document in adminSnapshot.docs) {
      notificationBatch.set(firestore.collection('notifications').doc(), {
        'userId': document.id,
        'title': 'New Doctor Request',
        'message': '$fullName requested approval as $specialty.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await notificationBatch.commit();
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!AuthValidators.isValidEmail(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      showMessage('Please enter your password.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await handleExistingUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      showMessage(friendlyAuthMessage(e));
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
      showMessage(friendlyAuthMessage(e));
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
                icon: Icons.phone_android,
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

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    specialtyController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool validateProfileFields() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (!AuthValidators.isValidName(firstName)) {
      showMessage('Enter a valid first name using letters only.');
      return false;
    }

    if (!AuthValidators.isValidName(lastName)) {
      showMessage('Enter a valid last name using letters only.');
      return false;
    }

    if (widget.role == 'doctor' && specialtyController.text.trim().length < 2) {
      showMessage('Please enter a valid specialty or designation.');
      return false;
    }

    return true;
  }

  Future<void> registerWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!validateProfileFields()) return;

    if (!AuthValidators.isValidEmail(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password != confirmPasswordController.text) {
      showMessage('Passwords do not match.');
      return;
    }

    if (!AuthValidators.isStrongPassword(password)) {
      showMessage(AuthValidators.passwordHelp);
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
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
      showMessage(friendlyAuthMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> registerWithGoogle() async {
    if (!validateProfileFields()) return;

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
      showMessage(friendlyAuthMessage(e));
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
    if (!validateProfileFields()) return;

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
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AuthValidators.passwordHelp,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
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
                icon: Icons.phone_android,
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

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  String phoneAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Phone sign-in is disabled. In Firebase Console, open Authentication > Sign-in method > Phone and enable it.';
      case 'app-not-authorized':
        return 'This Android build is not authorized for Firebase phone login. Add the debug SHA-1 and SHA-256 fingerprints in Firebase Project settings, then replace google-services.json.';
      case 'invalid-app-credential':
        return 'Firebase could not verify this app. Check the Android SHA fingerprints and the latest google-services.json file.';
      case 'missing-client-identifier':
        return 'Firebase phone verification is not configured for this app build.';
      default:
        return friendlyAuthMessage(error);
    }
  }

  Future<void> sendOtp() async {
    final phone = AuthValidators.normalizePhone(phoneController.text);

    if (!AuthValidators.isValidPhone(phone)) {
      showMessage(
        'Enter a valid international phone number, for example +8801XXXXXXXXX.',
      );
      return;
    }

    phoneController.text = phone;

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
            showMessage(phoneAuthMessage(e));
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
      showMessage(phoneAuthMessage(e));
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
    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      showMessage('Enter the 6-digit OTP.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await webConfirmationResult!.confirm(otp);
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
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
      showMessage(phoneAuthMessage(e));
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

      if (savedRole == 'admin') {
        openHome(const AdminHome());
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FBF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB8E9DF)),
            ),
            child: const Text(
              kIsWeb
                  ? 'For reliable phone-login testing, use the Android emulator or a real phone. Web phone login also needs an authorized domain and reCAPTCHA.'
                  : 'Use international format, for example +8801XXXXXXXXX. For emulator testing, add a Firebase test phone number and code. Also enable the country in Authentication > Settings > SMS region policy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();
    if (!AuthValidators.isValidEmail(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showMessage('Password reset email sent');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showMessage(friendlyAuthMessage(e));
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

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool hidden;

  @override
  void initState() {
    super.initState();
    hidden = widget.obscureText;
  }

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
        controller: widget.controller,
        obscureText: hidden,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(widget.icon, size: 20),
          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: hidden ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                )
              : null,
          hintText: widget.hintText,
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
  const SocialCircleButton({
    super.key,
    this.text,
    this.icon,
    required this.color,
    required this.onTap,
  }) : assert(text != null || icon != null);

  final String? text;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

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
          child: icon != null
              ? Icon(icon, size: 30, color: color)
              : Text(
                  text ?? '',
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
