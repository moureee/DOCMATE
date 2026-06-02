import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String rating;
  final String available;

  const AppointmentScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.rating,
    required this.available,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  String? selectedSlot;
  String? editingAppointmentId;

  bool isSaving = false;

  final List<String> timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
  ];

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String twoDigit(int number) {
    return number.toString().padLeft(2, "0");
  }

  String dateKey(DateTime date) {
    return "${date.year}-${twoDigit(date.month)}-${twoDigit(date.day)}";
  }

  DateTime? parseDateKey(String value) {
    try {
      final parts = value.split("-");
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  String prettyDate(DateTime date) {
    return "${twoDigit(date.day)}-${twoDigit(date.month)}-${date.year}";
  }

  String shortDate(DateTime date) {
    return "${twoDigit(date.day)}/${twoDigit(date.month)}";
  }

  bool isActiveAppointment(Map<String, dynamic> data) {
    final status = data["status"]?.toString().toLowerCase() ?? "pending";

    if (status == "canceled") return false;
    if (status == "rejected") return false;
    if (status == "completed") return false;

    return true;
  }

  bool isSlotBooked(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime date,
    String slot,
  ) {
    final dateText = dateKey(date);

    for (final doc in docs) {
      final data = doc.data();

      if (!isActiveAppointment(data)) {
        continue;
      }

      if (editingAppointmentId != null && doc.id == editingAppointmentId) {
        continue;
      }

      final bookedDate = data["appointmentDate"]?.toString() ?? "";
      final bookedSlot = data["timeSlot"]?.toString() ?? "";

      if (bookedDate == dateText && bookedSlot == slot) {
        return true;
      }
    }

    return false;
  }

  bool isDateAvailable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime date,
  ) {
    final today = todayOnly();
    final lastDate = today.add(const Duration(days: 30));

    final cleanDate = DateTime(date.year, date.month, date.day);

    if (cleanDate.isBefore(today)) {
      return false;
    }

    if (cleanDate.isAfter(lastDate)) {
      return false;
    }

    // Demo availability rule:
    // Friday is closed. Other days are available if at least one slot is free.
    if (cleanDate.weekday == DateTime.friday) {
      return false;
    }

    int bookedCount = 0;

    for (final slot in timeSlots) {
      if (isSlotBooked(docs, cleanDate, slot)) {
        bookedCount++;
      }
    }

    return bookedCount < timeSlots.length;
  }

  DateTime? firstAvailableDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final today = todayOnly();

    for (int i = 0; i <= 30; i++) {
      final date = today.add(Duration(days: i));

      if (isDateAvailable(docs, date)) {
        return date;
      }
    }

    return null;
  }

  Future<void> saveAppointment(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> doctorAppointments,
    DateTime activeDate,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("Please login first");
      return;
    }

    if (selectedSlot == null) {
      showMessage("Please select a time slot");
      return;
    }

    if (isSlotBooked(doctorAppointments, activeDate, selectedSlot!)) {
      showMessage("This slot is already booked");
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final patientName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : user.email?.split("@")[0] ?? "Patient";

      if (editingAppointmentId == null) {
        await FirebaseFirestore.instance.collection("appointments").add({
          "patientId": user.uid,
          "patientName": patientName,
          "patientEmail": user.email ?? "",
          "doctorName": widget.doctorName,
          "specialty": widget.specialty,
          "appointmentDate": dateKey(activeDate),
          "timeSlot": selectedSlot,
          "note": noteController.text.trim(),
          "status": "pending",
          "createdAt": Timestamp.now(),
          "updatedAt": Timestamp.now(),
        });

        showMessage("Appointment booked successfully");
      } else {
        await FirebaseFirestore.instance
            .collection("appointments")
            .doc(editingAppointmentId)
            .update({
          "appointmentDate": dateKey(activeDate),
          "timeSlot": selectedSlot,
          "note": noteController.text.trim(),
          "status": "pending",
          "updatedAt": Timestamp.now(),
        });

        showMessage("Appointment rescheduled successfully");
      }

      clearForm();
    } catch (e) {
      debugPrint("Appointment save error: $e");
      showMessage("Could not save appointment");
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(appointmentId)
          .update({
        "status": "canceled",
        "updatedAt": Timestamp.now(),
      });

      if (editingAppointmentId == appointmentId) {
        clearForm();
      }

      showMessage("Appointment canceled");
    } catch (e) {
      debugPrint("Cancel appointment error: $e");
      showMessage("Could not cancel appointment");
    }
  }

  Future<void> deleteAppointmentRecord(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("appointments")
          .doc(appointmentId)
          .delete();

      showMessage("Appointment record deleted");
    } catch (e) {
      debugPrint("Delete appointment error: $e");
      showMessage("Could not delete appointment");
    }
  }

  void startReschedule(
    QueryDocumentSnapshot<Map<String, dynamic>> appointmentDoc,
  ) {
    final data = appointmentDoc.data();

    final oldDate = parseDateKey(data["appointmentDate"]?.toString() ?? "");

    setState(() {
      editingAppointmentId = appointmentDoc.id;
      selectedDate = oldDate;
      selectedSlot = data["timeSlot"]?.toString();
      noteController.text = data["note"]?.toString() ?? "";
    });

    showMessage("Choose new date/time and press Update Appointment");
  }

  void clearForm() {
    setState(() {
      selectedDate = null;
      selectedSlot = null;
      editingAppointmentId = null;
      noteController.clear();
    });
  }

  Color statusColor(String status) {
    final value = status.toLowerCase();

    if (value == "accepted") return Colors.green;
    if (value == "completed") return Colors.blue;
    if (value == "canceled") return Colors.red;
    if (value == "rejected") return Colors.red;

    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("Appointment"),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(
              child: Text("Please login first"),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDoctorSummary(),
                  const SizedBox(height: 18),
                  buildBookingArea(),
                  const SizedBox(height: 24),
                  buildSectionTitle("My Appointments"),
                  const SizedBox(height: 12),
                  buildMyAppointments(user.uid),
                ],
              ),
            ),
    );
  }

  Widget buildDoctorSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services,
              color: mainColor,
              size: 35,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.specialty),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(widget.rating),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingArea() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("appointments")
          .where("doctorName", isEqualTo: widget.doctorName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildInfoBox(
            title: "Could not load appointment slots",
            subtitle: "Check your internet or Firestore rules.",
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

        final doctorAppointments = snapshot.data?.docs ?? [];
        final firstDate = firstAvailableDate(doctorAppointments);

        if (firstDate == null) {
          return buildInfoBox(
            title: "No available dates",
            subtitle: "All appointment dates are currently booked.",
          );
        }

        DateTime activeDate = selectedDate ?? firstDate;

        if (!isDateAvailable(doctorAppointments, activeDate)) {
          activeDate = firstDate;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle(
                editingAppointmentId == null
                    ? "Book Appointment"
                    : "Reschedule Appointment",
              ),
              const SizedBox(height: 8),
              const Text(
                "Only available dates can be selected. Fully booked dates are disabled.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 14),
              buildAvailableDateChips(doctorAppointments),
              const SizedBox(height: 12),
              CalendarDatePicker(
                initialDate: activeDate,
                firstDate: todayOnly(),
                lastDate: todayOnly().add(const Duration(days: 30)),
                currentDate: DateTime.now(),
                selectableDayPredicate: (date) {
                  return isDateAvailable(doctorAppointments, date);
                },
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                    selectedSlot = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                "Selected Date: ${prettyDate(activeDate)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              buildTimeSlots(doctorAppointments, activeDate),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Pre-visit note / symptoms",
                  hintText: "Example: fever, headache, chest pain...",
                  filled: true,
                  fillColor: lightColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (editingAppointmentId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: clearForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text("Cancel Reschedule"),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () {
                          saveAppointment(doctorAppointments, activeDate);
                        },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    isSaving
                        ? "Saving..."
                        : editingAppointmentId == null
                            ? "Confirm Appointment"
                            : "Update Appointment",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildAvailableDateChips(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final today = todayOnly();
    final List<DateTime> availableDates = [];

    for (int i = 0; i <= 14; i++) {
      final date = today.add(Duration(days: i));

      if (isDateAvailable(docs, date)) {
        availableDates.add(date);
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableDates.map((date) {
        final isSelected =
            selectedDate != null && dateKey(selectedDate!) == dateKey(date);

        return ChoiceChip(
          label: Text(shortDate(date)),
          selected: isSelected,
          selectedColor: mainColor,
          onSelected: (value) {
            setState(() {
              selectedDate = date;
              selectedSlot = null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget buildTimeSlots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime activeDate,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: timeSlots.map((slot) {
        final booked = isSlotBooked(docs, activeDate, slot);
        final selected = selectedSlot == slot;

        return InkWell(
          onTap: booked
              ? null
              : () {
                  setState(() {
                    selectedDate = activeDate;
                    selectedSlot = slot;
                  });
                },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 105,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: booked
                  ? Colors.grey.shade300
                  : selected
                      ? mainColor
                      : lightColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? mainColor : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Text(
                  slot,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: booked ? Colors.black45 : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booked ? "Booked" : "Available",
                  style: TextStyle(
                    fontSize: 11,
                    color: booked ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildMyAppointments(String patientId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("appointments")
          .where("patientId", isEqualTo: patientId)
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
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final appointments = snapshot.data?.docs ?? [];

        if (appointments.isEmpty) {
          return buildInfoBox(
            title: "No appointments yet",
            subtitle: "Your booked appointments will appear here.",
          );
        }

        return Column(
          children: appointments.map((doc) {
            return buildAppointmentCard(doc);
          }).toList(),
        );
      },
    );
  }

  Widget buildAppointmentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> appointmentDoc,
  ) {
    final data = appointmentDoc.data();

    final doctorName = data["doctorName"]?.toString() ?? "Doctor";
    final specialty = data["specialty"]?.toString() ?? "General";
    final appointmentDate = data["appointmentDate"]?.toString() ?? "";
    final timeSlot = data["timeSlot"]?.toString() ?? "";
    final note = data["note"]?.toString() ?? "";
    final status = data["status"]?.toString() ?? "pending";

    final active = isActiveAppointment(data);

    return Container(
      width: double.infinity,
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
                child: Icon(
                  Icons.calendar_month,
                  color: mainColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.15),
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
          const SizedBox(height: 10),
          Text("Specialty: $specialty"),
          Text("Date: $appointmentDate"),
          Text("Time: $timeSlot"),
          if (note.isNotEmpty) Text("Note: $note"),
          const SizedBox(height: 12),
          if (active)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      startReschedule(appointmentDoc);
                    },
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
                    onPressed: () {
                      cancelAppointment(appointmentDoc.id);
                    },
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
                onPressed: () {
                  deleteAppointmentRecord(appointmentDoc.id);
                },
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
}
