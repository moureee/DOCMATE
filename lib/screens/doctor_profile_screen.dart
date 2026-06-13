import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';
import 'appointment_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.available,
  });

  final String doctorId;
  final String doctorName;
  final String specialty;
  final String rating;
  final String available;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  DoctorModel get doctor {
    return AppData.instance.doctors.firstWhere(
      (doctor) {
        return doctor.id == widget.doctorId;
      },
      orElse: () {
        return DoctorModel(
          id: widget.doctorId,
          name: widget.doctorName,
          specialty: widget.specialty,
          rating: double.tryParse(widget.rating) ?? 0,
          reviews: 0,
          experience: 5,
          availableSlots: [
            '10:00 AM',
            '12:00 PM',
          ],
          queueLength: 0,
        );
      },
    );
  }

  void openAppointmentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AppointmentScreen(
            doctor: doctor,
          );
        },
      ),
    );
  }

  void toggleFavorite() {
    AppData.instance.toggleFavorite(
      doctor.id,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentDoctor = doctor;

    final queueMinutes = AppData.instance.predictedQueueMinutes(currentDoctor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        actions: [
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(
              currentDoctor.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: currentDoctor.isFavorite ? Colors.red : AppColors.dark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildProfileHeader(currentDoctor),
            const SizedBox(height: 18),
            buildInformationCard(
              icon: Icons.workspace_premium,
              title: 'Experience',
              value: '${currentDoctor.experience} years',
            ),
            buildInformationCard(
              icon: Icons.star,
              title: 'Rating and Reviews',
              value: '${currentDoctor.rating} rating from '
                  '${currentDoctor.reviews} reviews',
            ),
            buildInformationCard(
              icon: Icons.schedule,
              title: 'Available Slots',
              value: currentDoctor.availableSlots.join(', '),
            ),
            buildInformationCard(
              icon: Icons.hourglass_bottom,
              title: 'Estimated Queue Time',
              value: 'Approximately $queueMinutes minutes',
            ),
            const SizedBox(height: 6),
            buildReviewCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openAppointmentScreen,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader(
    DoctorModel currentDoctor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 52,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            currentDoctor.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            currentDoctor.specialty,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⭐ ${currentDoctor.rating} • '
            '${currentDoctor.reviews} reviews',
          ),
        ],
      ),
    );
  }

  Widget buildInformationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightMint,
            child: Icon(
              icon,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient Review',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"The doctor was friendly and explained everything clearly."',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
