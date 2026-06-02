import 'package:flutter/material.dart';
import 'appointment_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String rating;
  final String available;

  const DoctorProfileScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.available,
  });

  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int predictQueueTime() {
    if (available.toLowerCase().contains("today")) {
      return 25;
    } else if (available.toLowerCase().contains("tomorrow")) {
      return 10;
    } else {
      return 40;
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueTime = predictQueueTime();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("Doctor Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildDoctorHeader(),
            const SizedBox(height: 18),
            buildInfoCards(queueTime),
            const SizedBox(height: 18),
            buildAboutSection(),
            const SizedBox(height: 18),
            buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget buildDoctorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services,
              size: 48,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            doctorName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            specialty,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInfoCards(int queueTime) {
    return Row(
      children: [
        Expanded(
          child: buildSmallInfoCard(
            icon: Icons.calendar_month,
            title: "Status",
            value: available,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildSmallInfoCard(
            icon: Icons.timer,
            title: "Queue",
            value: "$queueTime min",
          ),
        ),
      ],
    );
  }

  Widget buildSmallInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: mainColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mainColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Doctor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$doctorName is a specialist in $specialty. Patients can view availability, estimated queue time, and book appointments from this profile.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentScreen(
                    doctorName: doctorName,
                    specialty: specialty,
                    rating: rating,
                    available: available,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text("Book Appointment"),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              showMessage(context,
                  "Pre-visit notes are included in appointment booking");
            },
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text("Add Pre-Visit Note"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: mainColor, width: 2),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
