import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';
import 'ai_symptom_checker_screen.dart';
import 'chat_screen.dart';
import 'doctor_profile_screen.dart';
import 'emergency_screen.dart';
import 'health_card_screen.dart';
import 'health_profile_screen.dart';
import 'medicine_screen.dart';
import 'notifications_screen.dart';
import 'patient_appointments_screen.dart';
import 'patient_profile_screen.dart';
import 'prescription_screen.dart';
import 'queue_prediction_screen.dart';
import 'timeline_screen.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return screen;
        },
      ),
    ).then((_) {
      setState(() {});
    });
  }

  List<DoctorModel> filteredDoctors() {
    final doctors = AppData.instance.rankedDoctors;

    if (searchText.trim().isEmpty) {
      return doctors;
    }

    final query = searchText.toLowerCase().trim();

    return doctors.where((doctor) {
      return doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == 1) {
            openScreen(
              const PatientAppointmentsScreen(),
            );
          } else if (index == 2) {
            openScreen(
              const ChatScreen(),
            );
          } else if (index == 3) {
            openScreen(
              const PatientProfileScreen(),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appData,
          builder: (context, child) {
            return RefreshIndicator(
              onRefresh: appData.refreshDoctors,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  buildHeader(),
                  const SizedBox(height: 18),
                  buildSearchSection(),
                  const SizedBox(height: 24),
                  buildSectionTitle(
                    'Smart Healthcare Features',
                  ),
                  const SizedBox(height: 12),
                  buildFeatureGrid(),
                  const SizedBox(height: 26),
                  buildSectionTitle(
                    searchText.isEmpty
                        ? 'Recommended Doctors'
                        : 'Search Results',
                  ),
                  const SizedBox(height: 12),
                  buildDoctorList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildHeader() {
    final unreadCount = AppData.instance.notifications.where((notification) {
      return !notification.read;
    }).length;

    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.person,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Text(
                AppData.instance.currentPatientName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                openScreen(
                  const NotificationsScreen(),
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                size: 28,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 7,
                top: 5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Specialist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by doctor name or specialty',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cardiology, Dermatology...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();

                        setState(() {
                          searchText = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeatureGrid() {
    final features = [
      const HomeFeature(
        title: 'Symptom Checker',
        icon: Icons.psychology,
        screen: AiSymptomCheckerScreen(),
      ),
      const HomeFeature(
        title: 'Queue Prediction',
        icon: Icons.hourglass_bottom,
        screen: QueuePredictionScreen(),
      ),
      const HomeFeature(
        title: 'Emergency',
        icon: Icons.emergency,
        screen: EmergencyScreen(),
        danger: true,
      ),
      const HomeFeature(
        title: 'Medicines',
        icon: Icons.medication,
        screen: MedicineScreen(),
      ),
      const HomeFeature(
        title: 'Health Profile',
        icon: Icons.monitor_heart_outlined,
        screen: HealthProfileScreen(),
      ),
      const HomeFeature(
        title: 'Health Card',
        icon: Icons.badge_outlined,
        screen: HealthCardScreen(),
      ),
      const HomeFeature(
        title: 'Prescriptions',
        icon: Icons.receipt_long,
        screen: PrescriptionScreen(),
      ),
      const HomeFeature(
        title: 'Timeline',
        icon: Icons.timeline,
        screen: TimelineScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final feature = features[index];

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            openScreen(feature.screen);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: feature.danger ? const Color(0xFFFFECEB) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: feature.danger ? AppColors.danger : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor:
                      feature.danger ? AppColors.danger : AppColors.lightMint,
                  child: Icon(
                    feature.icon,
                    color:
                        feature.danger ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDoctorList() {
    final appData = AppData.instance;

    if (appData.isLoadingDoctors) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (appData.doctorLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(
              appData.doctorLoadError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: appData.refreshDoctors,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final doctors = filteredDoctors();

    if (doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.search_off,
              size: 42,
              color: Colors.black54,
            ),
            SizedBox(height: 10),
            Text(
              'No matching doctors found.',
            ),
          ],
        ),
      );
    }

    return Column(
      children: doctors.map((doctor) {
        return buildDoctorCard(doctor);
      }).toList(),
    );
  }

  Widget buildDoctorCard(DoctorModel doctor) {
    final queueTime = AppData.instance.predictedQueueMinutes(doctor);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.lightMint,
            child: Icon(
              Icons.medical_services,
              size: 31,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '⭐ ${doctor.rating}  •  '
                  '$queueTime min wait',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  AppData.instance.toggleFavorite(
                    doctor.id,
                  );
                },
                icon: Icon(
                  doctor.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: doctor.isFavorite ? Colors.red : Colors.black45,
                ),
              ),
              IconButton(
                onPressed: () {
                  openScreen(
                    DoctorProfileScreen(
                      doctorId: doctor.id,
                      doctorName: doctor.name,
                      specialty: doctor.specialty,
                      rating: doctor.rating.toString(),
                      available: doctor.availableSlots.join(', '),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                ),
              ),
            ],
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
}

class HomeFeature {
  const HomeFeature({
    required this.title,
    required this.icon,
    required this.screen,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final Widget screen;
  final bool danger;
}
