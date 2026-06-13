import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String rating;
  final String available;

  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
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

  String todayDateKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return "${now.year}-$month-$day";
  }

  Future<int> getTodayQueueCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate', isEqualTo: todayDateKey())
          .get();

      final activeCount = snapshot.docs.where((doc) {
        final status = doc.data()['status']?.toString().toLowerCase() ?? '';
        return status != 'canceled' && status != 'rejected' && status != 'completed';
      }).length;

      return activeCount;
    } catch (e) {
      debugPrint("Queue count error: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          "Doctor Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildDoctorHeader(),
            const SizedBox(height: 18),
            buildQueueCard(),
            const SizedBox(height: 18),
            buildStatusCard(),
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
            child: Icon(Icons.medical_services, size: 48, color: mainColor),
          ),
          const SizedBox(height: 14),
          Text(
            doctorName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            specialty,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Real Queue Prediction Card
  Widget buildQueueCard() {
    return FutureBuilder<int>(
      future: getTodayQueueCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: mainColor),
            ),
          );
        }

        final queueCount = snapshot.data ?? 0;
        final waitingMinutes = queueCount * 15;

        Color queueColor;
        String queueStatus;
        if (queueCount == 0) {
          queueColor = Colors.green;
          queueStatus = "No waiting!";
        } else if (queueCount <= 3) {
          queueColor = Colors.orange;
          queueStatus = "Short wait";
        } else {
          queueColor = Colors.red;
          queueStatus = "Long wait";
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: queueColor.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: queueColor, size: 26),
                  const SizedBox(width: 10),
                  const Text(
                    "Queue Prediction (Today)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: buildQueueStat(
                      label: "Patients in Queue",
                      value: "$queueCount",
                      icon: Icons.people,
                      color: queueColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildQueueStat(
                      label: "Est. Wait Time",
                      value: queueCount == 0 ? "0 min" : "~$waitingMinutes min",
                      icon: Icons.hourglass_empty,
                      color: queueColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: queueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: queueColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      queueStatus,
                      style: TextStyle(
                        color: queueColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      queueCount == 0
                          ? "— You can book now!"
                          : "— Each slot ~15 min",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildQueueStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: mainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Availability",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                available,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
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
        border: Border.all(color: mainColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Doctor",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "$doctorName is a specialist in $specialty. Patients can view availability, estimated queue time, and book appointments from this profile.",
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
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
                    doctorId: doctorId,
                    doctorName: doctorName,
                    specialty: specialty,
                    doctorData: {
                      "name": doctorName,
                      "specialty": specialty,
                      "rating": rating,
                      "slots": [],
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text("Book Appointment"),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              showMessage(context, "Pre-visit notes are included in appointment booking");
            },
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text("Add Pre-Visit Note"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: mainColor, width: 2),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}