import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentScreen extends StatefulWidget {
  final String doctorId; 
  final Map<String, dynamic> doctorData;
  final String doctorName; 
  final String specialty; // 👈 ১. এখানে specialty ভেরিয়েবল যোগ করা হয়েছে

  const AppointmentScreen({
    super.key,
    required this.doctorId,
    required this.doctorData,
    required this.doctorName, 
    required this.specialty, // 👈 ২. কনস্ট্রাক্টরে রিকোয়ার্ড করা হয়েছে
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
 
  static const Color mainColor = Color(0xFF00D9B8); 
  static const Color lightColor = Color(0xFFE9FFF9);

  final TextEditingController noteController = TextEditingController();

  DateTime? selectedDate;
  String? selectedSlot;
  String? editingAppointmentId;

  bool isSaving = false;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream;

  List<String> get dynamicTimeSlots {
    if (widget.doctorData['slots'] != null) {
      return List<String>.from(widget.doctorData['slots']);
    }
    return []; 
  }

  @override
  void initState() {
    super.initState();
    // Firestore-এর স্ট্রিমটি initState-এ ইনিশিয়ালাইজ করা হয়েছে পারফরম্যান্স বুস্ট করতে
    _appointmentsStream = FirebaseFirestore.instance
        .collection("appointments")
        .where("doctorId", isEqualTo: widget.doctorId) 
        .snapshots();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
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
    if (status == "canceled" || status == "rejected" || status == "completed") {
      return false;
    }
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

      if (!isActiveAppointment(data)) continue;

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

    if (cleanDate.isBefore(today) || cleanDate.isAfter(lastDate)) return false;
    if (cleanDate.weekday == DateTime.friday) return false;
    if (dynamicTimeSlots.isEmpty) return false;

    int bookedCount = 0;
    for (final slot in dynamicTimeSlots) {
      if (isSlotBooked(docs, cleanDate, slot)) {
        bookedCount++;
      }
    }
    return bookedCount < dynamicTimeSlots.length;
  }

  DateTime? firstAvailableDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final today = todayOnly();
    for (int i = 0; i <= 30; i++) {
      final date = today.add(Duration(days: i));
      if (isDateAvailable(docs, date)) return date;
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

      // 👈 পাস করা doctorName এবং specialty এখানে হ্যান্ডেল করা হয়েছে
      final String docName = widget.doctorName.isNotEmpty 
          ? widget.doctorName 
          : (widget.doctorData['name'] ?? widget.doctorData['doctorName'] ?? 'Unknown Doctor');
      
      final String docSpecialty = widget.specialty.isNotEmpty 
          ? widget.specialty 
          : (widget.doctorData['specialty'] ?? 'General');

      if (editingAppointmentId == null) {
        await FirebaseFirestore.instance.collection("appointments").add({
          "patientId": user.uid,
          "patientName": patientName,
          "patientEmail": user.email ?? "",
          "doctorId": widget.doctorId, 
          "doctorName": docName,
          "specialty": docSpecialty,
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
      if (editingAppointmentId == appointmentId) clearForm();
      showMessage("Appointment canceled");
    } catch (e) {
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
    if (value == "accepted" || value == "approved") return Colors.green;
    if (value == "completed") return Colors.blue;
    if (value == "canceled" || value == "rejected") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("Appointment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: user == null
          ? const Center(child: Text("Please login first"))
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
    final String docName = widget.doctorName.isNotEmpty 
        ? widget.doctorName 
        : (widget.doctorData['name'] ?? widget.doctorData['doctorName'] ?? 'Unknown Doctor');
    
    final String docSpecialty = widget.specialty.isNotEmpty 
        ? widget.specialty 
        : (widget.doctorData['specialty'] ?? 'General');
        
    final String docRating = widget.doctorData['rating']?.toString() ?? '0.0';

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
            child: Icon(Icons.medical_services, color: mainColor, size: 35),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(docSpecialty, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(docRating, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
    if (dynamicTimeSlots.isEmpty) {
      return buildInfoBox(
        title: "No Time Slots Available",
        subtitle: "This doctor hasn't added any schedule yet.",
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appointmentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildInfoBox(title: "Error loading slots", subtitle: "Please check your internet connection.");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: mainColor)));
        }

        final doctorAppointments = snapshot.data?.docs ?? [];
        final firstDate = firstAvailableDate(doctorAppointments);

        if (firstDate == null) {
          return buildInfoBox(title: "No available dates", subtitle: "All slots are full for the next 30 days.");
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
              buildSectionTitle(editingAppointmentId == null ? "Book Appointment" : "Reschedule Appointment"),
              const SizedBox(height: 14),
              buildAvailableDateChips(doctorAppointments),
              const SizedBox(height: 12),
              // 👈 ক্যালেন্ডার রি-বিল্ড বা স্টেট সোয়াপ এরর ঠিক করতে ValueKey(activeDate) দেওয়া হয়েছে
              CalendarDatePicker(
                key: ValueKey(activeDate), 
                initialDate: activeDate,
                firstDate: todayOnly(),
                lastDate: todayOnly().add(const Duration(days: 30)),
                currentDate: DateTime.now(),
                selectableDayPredicate: (date) => isDateAvailable(doctorAppointments, date),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                    selectedSlot = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text("Selected Date: ${prettyDate(activeDate)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              buildTimeSlots(doctorAppointments, activeDate),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Pre-visit note / symptoms",
                  hintText: "Example: fever, headache...",
                  filled: true,
                  fillColor: lightColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.transparent)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: mainColor)),
                ),
              ),
              const SizedBox(height: 16),
              if (editingAppointmentId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: clearForm,
                    child: const Text("Cancel Reschedule", style: TextStyle(color: Colors.black)),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : () => saveAppointment(doctorAppointments, activeDate),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(isSaving ? "Saving..." : editingAppointmentId == null ? "Confirm Appointment" : "Update Appointment"),
                  style: ElevatedButton.styleFrom(backgroundColor: mainColor, foregroundColor: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildAvailableDateChips(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final today = todayOnly();
    final List<DateTime> availableDates = [];

    for (int i = 0; i <= 14; i++) {
      final date = today.add(Duration(days: i));
      if (isDateAvailable(docs, date)) availableDates.add(date);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableDates.map((date) {
        final isSelected = selectedDate != null && dateKey(selectedDate!) == dateKey(date);
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

  Widget buildTimeSlots(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, DateTime activeDate) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: dynamicTimeSlots.map((slot) {
        final booked = isSlotBooked(docs, activeDate, slot);
        final selected = selectedSlot == slot;

        return InkWell(
          onTap: booked ? null : () {
            setState(() {
              selectedDate = activeDate;
              selectedSlot = slot;
            });
          },
          child: Container(
            width: 105,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: booked ? Colors.grey.shade300 : selected ? mainColor : lightColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? mainColor : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Text(slot, style: TextStyle(fontWeight: FontWeight.bold, color: booked ? Colors.black45 : Colors.black)),
                const SizedBox(height: 4),
                Text(booked ? "Booked" : "Available", style: TextStyle(fontSize: 11, color: booked ? Colors.red : Colors.green)),
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
        if (snapshot.hasError) return buildInfoBox(title: "Error loading", subtitle: "Could not load your appointments.");
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: mainColor));

        final appointments = snapshot.data?.docs ?? [];
        if (appointments.isEmpty) {
          return buildInfoBox(title: "No appointments yet", subtitle: "Your appointments will appear here.");
        }

        return Column(children: appointments.map((doc) => buildAppointmentCard(doc)).toList());
      },
    );
  }

  Widget buildAppointmentCard(QueryDocumentSnapshot<Map<String, dynamic>> appointmentDoc) {
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: lightColor, child: Icon(Icons.calendar_month, color: mainColor)),
              const SizedBox(width: 12),
              Expanded(child: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor(status))),
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
                    onPressed: () => startReschedule(appointmentDoc),
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text("Reschedule"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: mainColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => cancelAppointment(appointmentDoc.id),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text("Cancel"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => deleteAppointmentRecord(appointmentDoc.id),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text("Delete Record"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold));
  }

  Widget buildInfoBox({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: mainColor, size: 34),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }
}