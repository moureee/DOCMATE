import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String initialFilter;

  const DoctorAppointmentsScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.initialFilter = 'pending',
  });

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends State<DoctorAppointmentsScreen> {
  static const Color mainColor = Color(0xFF00D9B8);
  static const Color lightBg = Color(0xFFE9FFF9);

  late String selectedFilter;

  final List<Map<String, String>> filters = [
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Accepted', 'value': 'accepted'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Rejected', 'value': 'rejected'},
  ];

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
  }

  Future<void> updateStatus(String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get screenTitle {
    if (widget.initialFilter == 'completed') return 'Prescriptions';
    if (widget.initialFilter == 'accepted') return 'Patient Records';
    return 'Appointments';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          screenTitle,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter['label']!),
                      selected: isSelected,
                      selectedColor: mainColor,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.black : Colors.black54,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter['value']!;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Appointment List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: widget.doctorId)
                  .where('status', isEqualTo: selectedFilter)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: mainColor),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No $selectedFilter appointments',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return buildAppointmentCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAppointmentCard(
      String docId, Map<String, dynamic> data) {
    final patientName = data['patientName'] ?? 'Patient';
    final patientEmail = data['patientEmail'] ?? '';
    final date = data['appointmentDate'] ?? '';
    final slot = data['timeSlot'] ?? '';
    final note = data['note'] ?? '';
    final status = data['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE9FFF9),
                child: Icon(Icons.person, color: mainColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      patientEmail,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
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
          const Divider(height: 20),

          // Details
          Row(
            children: [
              const Icon(Icons.calendar_month,
                  size: 16, color: mainColor),
              const SizedBox(width: 6),
              Text(date,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time,
                  size: 16, color: mainColor),
              const SizedBox(width: 6),
              Text(slot,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),

          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note,
                    size: 16, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    style:
                        const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => updateStatus(docId, 'accepted'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => updateStatus(docId, 'rejected'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else if (status == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => updateStatus(docId, 'completed'),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}