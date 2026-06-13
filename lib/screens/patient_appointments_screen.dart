import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_screen.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool isActiveAppointment(Map<String, dynamic> data) {
    final status = data["status"]?.toString().toLowerCase() ?? "pending";
    if (status == "canceled") return false;
    if (status == "rejected") return false;
    if (status == "completed") return false;
    return true;
  }

  Color statusColor(String status) {
    final value = status.toLowerCase();
    if (value == "accepted") return Colors.green;
    if (value == "completed") return Colors.blue;
    if (value == "canceled") return Colors.red;
    if (value == "rejected") return Colors.red;
    return Colors.orange;
  }

  Future<void> cancelAppointment(
    BuildContext context,
    String appointmentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(appointmentId)
          .update({
        "status": "canceled",
        "updatedAt": Timestamp.now(),
      });
      showMessage(context, "Appointment canceled");
    } catch (e) {
      debugPrint("Cancel error: $e");
      showMessage(context, "Could not cancel appointment");
    }
  }

  Future<void> deleteAppointment(
    BuildContext context,
    String appointmentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(appointmentId)
          .delete();
      showMessage(context, "Appointment record deleted");
    } catch (e) {
      debugPrint("Delete error: $e");
      showMessage(context, "Could not delete appointment");
    }
  }

  void openRescheduleScreen(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String docId = data["doctorId"]?.toString() ?? "";

    if (docId.isEmpty) {
      showMessage(context, "Error: Doctor ID not found!");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentScreen(
          doctorId: docId,
          doctorName: data["doctorName"]?.toString() ?? "Doctor",
          specialty: data["specialty"]?.toString() ?? "General",
          doctorData: {
            "name": data["doctorName"] ?? "Doctor",
            "specialty": data["specialty"] ?? "General",
            "slots": data["slots"] ?? [],
            "rating": data["rating"] ?? "0.0",
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          "My Appointments",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("appointments")
                  .where("patientId", isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return buildInfoBox(
                    title: "Could not load appointments",
                    subtitle: "Check your internet or Firestore rules.",
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: mainColor),
                  );
                }

                final appointments = snapshot.data?.docs ?? [];

                if (appointments.isEmpty) {
                  return buildInfoBox(
                    title: "No appointments yet",
                    subtitle: "Your booked appointments will appear here.",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final doc = appointments[index];
                    final data = doc.data();
                    return buildAppointmentCard(
                      context: context,
                      appointmentId: doc.id,
                      data: data,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget buildAppointmentCard({
    required BuildContext context,
    required String appointmentId,
    required Map<String, dynamic> data,
  }) {
    final doctorName = data["doctorName"]?.toString() ?? "Doctor";
    final specialty = data["specialty"]?.toString() ?? "General";
    final appointmentDate = data["appointmentDate"]?.toString() ?? "";
    final timeSlot = data["timeSlot"]?.toString() ?? "";
    final note = data["note"]?.toString() ?? "";
    final status = data["status"]?.toString() ?? "pending";
    final active = isActiveAppointment(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: lightColor,
                child: Icon(Icons.calendar_month, color: mainColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Specialty: $specialty",
              style: const TextStyle(color: Colors.black87)),
          Text("Date: $appointmentDate",
              style: const TextStyle(color: Colors.black87)),
          Text("Time: $timeSlot",
              style: const TextStyle(color: Colors.black87)),
          if (note.isNotEmpty)
            Text("Note: $note",
                style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          if (active)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openRescheduleScreen(context, data),
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text("Reschedule"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: mainColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => cancelAppointment(context, appointmentId),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => deleteAppointment(context, appointmentId),
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete Record"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildInfoBox({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: mainColor, size: 34),
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
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}