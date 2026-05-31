import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_screen.dart';
import 'edit_health_profile.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D9B8),
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(
              child: Text('No patient logged in'),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D9B8),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('Patient data not found'),
                  );
                }

                Map<String, dynamic> userData =
                    snapshot.data!.data() as Map<String, dynamic>;

                String name = userData['name'] ?? 'Patient';
                String email = userData['email'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFF00D9B8),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $name',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Quick Health Card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QuickHealthCard(uid: currentUser.uid),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditHealthProfile(
                                  uid: currentUser.uid,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Health Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: const BorderSide(
                                color: Color(0xFF00D9B8),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Patient Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        children: [
                          FeatureCard(
                            title: 'Book Appointment',
                            icon: Icons.calendar_month,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          FeatureCard(
                            title: 'Find Doctors',
                            icon: Icons.medical_services,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          FeatureCard(
                            title: 'AI Symptom Checker',
                            icon: Icons.psychology,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          FeatureCard(
                            title: 'Emergency Mode',
                            icon: Icons.emergency,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          FeatureCard(
                            title: 'Prescriptions',
                            icon: Icons.medication,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          FeatureCard(
                            title: 'Health Timeline',
                            icon: Icons.timeline,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be added next'),
      ),
    );
  }
}

class QuickHealthCard extends StatelessWidget {
  final String uid;

  const QuickHealthCard({
    super.key,
    required this.uid,
  });

  String calculateBmi(String heightText, String weightText) {
    double? heightCm = double.tryParse(heightText);
    double? weightKg = double.tryParse(weightText);

    if (heightCm == null || weightKg == null || heightCm == 0) {
      return 'Not set';
    }

    double heightM = heightCm / 100;
    double bmi = weightKg / (heightM * heightM);

    return bmi.toStringAsFixed(1);
  }

  String bmiStatus(String bmiText) {
    double? bmi = double.tryParse(bmiText);

    if (bmi == null) {
      return 'Update profile';
    }

    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'High risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('health_profiles')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        String height = '';
        String weight = '';
        String allergies = 'Not set';
        String bloodGroup = 'Not set';

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          height = data['height'] ?? '';
          weight = data['weight'] ?? '';
          allergies = data['allergies'] == '' ? 'Not set' : data['allergies'];
          bloodGroup =
              data['bloodGroup'] == '' ? 'Not set' : data['bloodGroup'];
        }

        String bmi = calculateBmi(height, weight);
        String status = bmiStatus(bmi);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF00D9B8),
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              healthRow('BMI', bmi),
              healthRow('Status', status),
              healthRow('Blood Group', bloodGroup),
              healthRow('Allergies', allergies),
            ],
          ),
        );
      },
    );
  }

  Widget healthRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF9FF5E5),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF00D9B8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
