import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class QueuePredictionScreen extends StatefulWidget {
  const QueuePredictionScreen({super.key});

  @override
  State<QueuePredictionScreen> createState() => _QueuePredictionScreenState();
}

class _QueuePredictionScreenState extends State<QueuePredictionScreen> {
  String? selectedDoctorId;

  DoctorModel? findSelectedDoctor(List<DoctorModel> doctors) {
    if (doctors.isEmpty) return null;

    selectedDoctorId ??= doctors.first.id;

    for (final doctor in doctors) {
      if (doctor.id == selectedDoctorId) return doctor;
    }

    selectedDoctorId = doctors.first.id;
    return doctors.first;
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Time Prediction'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final doctors = appData.approvedDoctors;
          final selectedDoctor = findSelectedDoctor(doctors);

          if (doctors.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No approved doctors are available.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Doctor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedDoctorId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor.id,
                      child: Text(doctor.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDoctorId = value;
                    });
                  },
                ),
                const SizedBox(height: 26),
                if (selectedDoctor != null)
                  buildPredictionCard(appData, selectedDoctor),
                const SizedBox(height: 18),
                buildExplanationCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildPredictionCard(AppData appData, DoctorModel doctor) {
    final predictedMinutes = appData.predictedQueueMinutes(doctor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_bottom, size: 52),
          const SizedBox(height: 12),
          Text(
            '$predictedMinutes minutes',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Estimated Waiting Time',
            style: TextStyle(fontSize: 16),
          ),
          const Divider(height: 32, color: Colors.black26),
          buildInformationRow('Doctor', doctor.name),
          const SizedBox(height: 8),
          buildInformationRow('Specialty', doctor.specialty),
          const SizedBox(height: 8),
          buildInformationRow(
            'Patients Ahead',
            doctor.queueLength.toString(),
          ),
          const SizedBox(height: 8),
          buildInformationRow(
            'Average Consultation',
            '${doctor.averageConsultationMinutes} minutes',
          ),
        ],
      ),
    );
  }

  Widget buildInformationRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget buildExplanationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Estimated wait = active patients in today\'s queue × the doctor\'s average consultation time. This is an estimate, not a guarantee.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
