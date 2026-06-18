import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/patient/screens/appointment_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final normalized = query.trim().toLowerCase();
          final doctors = appData.rankedDoctors.where((doctor) {
            if (!doctor.approved || !doctor.available) return false;
            if (normalized.isEmpty) return true;
            return doctor.name.toLowerCase().contains(normalized) ||
                doctor.specialty.toLowerCase().contains(normalized) ||
                doctor.hospitalName.toLowerCase().contains(normalized);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a doctor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Search by doctor, specialty or hospital.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Cardiology, Dr Ahmed, hospital...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => query = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 52, color: Colors.black45),
                      SizedBox(height: 12),
                      Text('No approved doctors match your search.'),
                    ],
                  ),
                )
              else
                ...doctors.map((doctor) => _doctorCard(context, doctor)),
            ],
          );
        },
      ),
    );
  }

  Widget _doctorCard(BuildContext context, DoctorModel doctor) {
    final nextDate = _nextAvailableDate(doctor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.lightMint,
            child: Icon(Icons.medical_services, color: AppColors.primaryDark),
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
                Text(doctor.specialty),
                if (doctor.hospitalName.isNotEmpty)
                  Text(
                    doctor.hospitalName,
                    style: const TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 5),
                Text(
                  nextDate == null
                      ? 'No upcoming schedule'
                      : 'Next availability: ${formatDate(nextDate)}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: nextDate == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentScreen(doctor: doctor),
                      ),
                    );
                  },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }

  DateTime? _nextAvailableDate(DoctorModel doctor) {
    final today = DateTime.now();
    for (var offset = 0; offset < 60; offset++) {
      final date = DateTime(today.year, today.month, today.day)
          .add(Duration(days: offset));
      final times = availabilityTimesForDate(doctor, date);
      if (times.any(
        (time) => !AppData.instance.isSlotBooked(doctor.id, date, time),
      )) {
        return date;
      }
    }
    return null;
  }
}
