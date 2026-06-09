import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'doctor_profile_screen.dart';
import 'patient_appointments_screen.dart';
import 'ai_symptom_checker_screen.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatientHomeScreen();
  }
}

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String patientName = "Patient";

  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  @override
  void initState() {
    super.initState();
    loadPatientName();
  }

  Future<void> loadPatientName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        patientName = "Patient";
      });
      return;
    }

    String name = "Patient";

    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection("patients")
          .doc(user.uid)
          .get();

      if (patientDoc.exists) {
        final data = patientDoc.data();

        if (data != null) {
          if (data["name"] != null &&
              data["name"].toString().trim().isNotEmpty) {
            name = data["name"].toString();
          } else if (data["fullName"] != null &&
              data["fullName"].toString().trim().isNotEmpty) {
            name = data["fullName"].toString();
          } else if (data["patientName"] != null &&
              data["patientName"].toString().trim().isNotEmpty) {
            name = data["patientName"].toString();
          }
        }
      }

      if (name == "Patient") {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();

          if (data != null) {
            if (data["name"] != null &&
                data["name"].toString().trim().isNotEmpty) {
              name = data["name"].toString();
            } else if (data["fullName"] != null &&
                data["fullName"].toString().trim().isNotEmpty) {
              name = data["fullName"].toString();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Could not load patient name: $e");
    }

    if (name == "Patient") {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        name = user.displayName!;
      } else if (user.email != null && user.email!.trim().isNotEmpty) {
        name = user.email!.split("@")[0];
      }
    }

    if (!mounted) return;

    setState(() {
      patientName = name;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getDoctorName(Map<String, dynamic> data) {
    if (data["name"] != null && data["name"].toString().trim().isNotEmpty) {
      return data["name"].toString();
    }

    if (data["fullName"] != null &&
        data["fullName"].toString().trim().isNotEmpty) {
      return data["fullName"].toString();
    }

    if (data["doctorName"] != null &&
        data["doctorName"].toString().trim().isNotEmpty) {
      return data["doctorName"].toString();
    }

    return "Doctor";
  }

  String getDoctorSpecialty(Map<String, dynamic> data) {
    if (data["specialty"] != null &&
        data["specialty"].toString().trim().isNotEmpty) {
      return data["specialty"].toString();
    }

    if (data["department"] != null &&
        data["department"].toString().trim().isNotEmpty) {
      return data["department"].toString();
    }

    return "General";
  }

  String getDoctorRating(Map<String, dynamic> data) {
    if (data["rating"] == null) {
      return "0.0";
    }

    return data["rating"].toString();
  }

  String getDoctorAvailableText(Map<String, dynamic> data) {
    if (data["available"] != null &&
        data["available"].toString().trim().isNotEmpty) {
      return data["available"].toString();
    }

    if (data["availability"] != null &&
        data["availability"].toString().trim().isNotEmpty) {
      return data["availability"].toString();
    }

    return "Availability not set";
  }

  bool isDoctorApproved(Map<String, dynamic> data) {
    if (data["approved"] == true) {
      return true;
    }

    if (data["isApproved"] == true) {
      return true;
    }

    if (data["status"] != null &&
        data["status"].toString().toLowerCase() == "approved") {
      return true;
    }

    return false;
  }

  bool matchesSearch(Map<String, dynamic> data) {
    final searchText = _searchController.text.toLowerCase().trim();

    if (searchText.isEmpty) {
      return true;
    }

    final name = getDoctorName(data).toLowerCase();
    final specialty = getDoctorSpecialty(data).toLowerCase();

    return name.contains(searchText) || specialty.contains(searchText);
  }

  void openDoctorProfile(Map<String, dynamic> doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(
          doctorName: getDoctorName(doctor),
          specialty: getDoctorSpecialty(doctor),
          rating: getDoctorRating(doctor),
          available: getDoctorAvailableText(doctor),
        ),
      ),
    );
  }

  void openBookingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientAppointmentsScreen(),
      ),
    );
  }

  void openAiSymptomChecker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AiSymptomCheckerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            openBookingsScreen();
          } else if (index == 2) {
            showMessage("Chat screen will be added later");
          } else if (index == 3) {
            showMessage("Profile screen will be added later");
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTopHeader(),
              const SizedBox(height: 20),
              buildSearchBox(),
              const SizedBox(height: 24),
              buildSectionTitle("Top Doctors"),
              const SizedBox(height: 12),
              buildDynamicDoctorList(),
              const SizedBox(height: 24),
              buildSectionTitle("Smart Healthcare Features"),
              const SizedBox(height: 12),
              buildSmartFeatureGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome,",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                showMessage("Notifications will be added later");
              },
              icon: const Icon(Icons.notifications_none),
            ),
            IconButton(
              onPressed: () {
                showMessage("Settings will be added later");
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's Find Your Specialist",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: "Search doctor or specialty...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDynamicDoctorList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("doctors").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildInfoBox(
            title: "Could not load doctors",
            subtitle: "Check Firestore rules or internet connection.",
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final approvedDoctors = docs.where((doc) {
          final data = doc.data();
          return isDoctorApproved(data) && matchesSearch(data);
        }).toList();

        if (approvedDoctors.isEmpty) {
          return buildInfoBox(
            title: "No approved doctors available",
            subtitle:
                "Doctors must be added and approved by admin before patients can book appointments.",
          );
        }

        return Column(
          children: approvedDoctors.map((doc) {
            final data = doc.data();
            return buildDoctorCard(data);
          }).toList(),
        );
      },
    );
  }

  Widget buildInfoBox({
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: mainColor,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildDoctorCard(Map<String, dynamic> doctor) {
    final doctorName = getDoctorName(doctor);
    final specialty = getDoctorSpecialty(doctor);
    final rating = getDoctorRating(doctor);
    final available = getDoctorAvailableText(doctor);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services,
              color: mainColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(specialty),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  available,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  showMessage("$doctorName added to favorite");
                },
                icon: const Icon(Icons.favorite_border),
              ),
              ElevatedButton(
                onPressed: () {
                  openDoctorProfile(doctor);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text("View"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSmartFeatureGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildFeatureCard(
                icon: Icons.psychology,
                title: "AI Symptom Checker",
                subtitle: "Rule-based engine",
                onTap: openAiSymptomChecker,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildFeatureCard(
                icon: Icons.timer,
                title: "Queue Prediction",
                subtitle: "Waiting time",
                onTap: () {
                  showMessage("Queue prediction appears in doctor profile");
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildFeatureCard(
                icon: Icons.emergency,
                title: "Emergency Mode",
                subtitle: "Quick help",
                onTap: () {
                  showMessage("Emergency screen will be added later");
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildFeatureCard(
                icon: Icons.health_and_safety,
                title: "Health Card",
                subtitle: "BMI & allergies",
                onTap: () {
                  showMessage("Quick health card will be added later");
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 125,
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: mainColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: mainColor, size: 32),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
