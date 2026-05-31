import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_screen.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

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

  Future<int> getAppointmentCount(String doctorId, String status) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: status)
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D9B8),
        title: const Text('Doctor Dashboard'),
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
              child: Text('No doctor logged in'),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
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
                    child: Text('Doctor profile not found'),
                  );
                }

                Map<String, dynamic> doctorData =
                    snapshot.data!.data() as Map<String, dynamic>;

                String name = doctorData['name'] ?? 'Doctor';
                String specialty = doctorData['specialty'] ?? 'Specialist';
                String email = doctorData['email'] ?? '';
                bool approved = doctorData['approved'] ?? false;
                bool available = doctorData['available'] ?? true;

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
                                Icons.medical_services,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. $name',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    specialty,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: approved
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: approved ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Text(
                          approved
                              ? 'Account Status: Approved by Admin'
                              : 'Account Status: Pending Admin Approval',
                          style: TextStyle(
                            color: approved
                                ? Colors.green.shade800
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Doctor Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DoctorCountCard(
                              title: 'Pending',
                              icon: Icons.pending_actions,
                              future: getAppointmentCount(
                                currentUser.uid,
                                'pending',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DoctorCountCard(
                              title: 'Completed',
                              icon: Icons.check_circle,
                              future: getAppointmentCount(
                                currentUser.uid,
                                'completed',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Doctor Services',
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
                          DoctorFeatureCard(
                            title: 'Appointments',
                            icon: Icons.calendar_month,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          DoctorFeatureCard(
                            title: 'Set Availability',
                            icon: Icons.access_time,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          DoctorFeatureCard(
                            title: 'Prescriptions',
                            icon: Icons.medication,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                          DoctorFeatureCard(
                            title: 'Patient Records',
                            icon: Icons.folder_shared,
                            onTap: () {
                              showComingSoon(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF00D9B8),
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              available ? Icons.check_circle : Icons.cancel,
                              color: const Color(0xFF9FF5E5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                available
                                    ? 'You are currently available for appointments'
                                    : 'You are currently unavailable',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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

class DoctorCountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> future;

  const DoctorCountCard({
    super.key,
    required this.title,
    required this.icon,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        String count = '0';

        if (snapshot.hasData) {
          count = snapshot.data.toString();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF00D9B8),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF9FF5E5),
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DoctorFeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DoctorFeatureCard({
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
