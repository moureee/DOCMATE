import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/firebase_options.dart';
import 'package:docmate/features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DocMateApp());
}

class DocMateApp extends StatelessWidget {
  const DocMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
