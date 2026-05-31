import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

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

  Future<int> getCount(String collectionName) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    return snapshot.docs.length;
  }

  Future<void> updateDoctorApproval(String doctorId, bool value) async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .update({
      'approved': value,
    });

    await FirebaseFirestore.instance.collection('users').doc(doctorId).update({
      'approved': value,
    });
  }

  Future<void> deleteDoctor(String doctorId) async {
    await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .delete();
    await FirebaseFirestore.instance.collection('users').doc(doctorId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D9B8),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: CountCard(
                    title: 'Users',
                    icon: Icons.people,
                    future: getCount('users'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CountCard(
                    title: 'Doctors',
                    icon: Icons.medical_services,
                    future: getCount('doctors'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CountCard(
                    title: 'Appointments',
                    icon: Icons.calendar_month,
                    future: getCount('appointments'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CountCard(
                    title: 'Emergency',
                    icon: Icons.emergency,
                    future: getCount('emergencies'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              'Manage Doctors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00D9B8),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No doctors registered yet.');
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    String name = data['name'] ?? 'Doctor';
                    String specialty = data['specialty'] ?? 'Not set';
                    bool approved = data['approved'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF00D9B8),
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(specialty),
                            trailing: Switch(
                              value: approved,
                              activeColor: const Color(0xFF00D9B8),
                              onChanged: (value) {
                                updateDoctorApproval(doc.id, value);
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                approved ? 'Approved' : 'Pending',
                                style: TextStyle(
                                  color:
                                      approved ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 15),
                              TextButton.icon(
                                onPressed: () {
                                  deleteDoctor(doc.id);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<int> future;

  const CountCard({
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
                textAlign: TextAlign.center,
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
