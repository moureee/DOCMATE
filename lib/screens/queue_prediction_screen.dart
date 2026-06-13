import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class QueuePredictionScreen extends StatefulWidget {
  const QueuePredictionScreen({super.key});

  @override
  State<QueuePredictionScreen> createState() => _QueuePredictionScreenState();
}

class _QueuePredictionScreenState extends State<QueuePredictionScreen> {
  String? selectedDoctorId;

  @override
  void initState() {
    super.initState();

    final doctors = AppData.instance.approvedDoctors;

    if (doctors.isNotEmpty) {
      selectedDoctorId = doctors.first.id;
    }
  }

  DoctorModel? findSelectedDoctor() {
    for (final doctor in AppData.instance.approvedDoctors) {
      if (doctor.id == selectedDoctorId) {
        return doctor;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final doctors = AppData.instance.approvedDoctors;
    final selectedDoctor = findSelectedDoctor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Time Prediction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: doctors.isEmpty
            ? const Center(
                child: Text(
                  'No approved doctors are available.',
                ),
              )
            : Column(
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
                      prefixIcon: Icon(
                        Icons.medical_services,
                      ),
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
                    buildPredictionCard(selectedDoctor),
                  const SizedBox(height: 18),
                  buildExplanationCard(),
                ],
              ),
      ),
    );
  }

  Widget buildPredictionCard(DoctorModel doctor) {
    final predictedMinutes = AppData.instance.predictedQueueMinutes(doctor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_bottom,
            size: 52,
          ),
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
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const Divider(
            height: 32,
            color: Colors.black26,
          ),
          buildInformationRow(
            'Doctor',
            doctor.name,
          ),
          const SizedBox(height: 8),
          buildInformationRow(
            'Specialty',
            doctor.specialty,
          ),
          const SizedBox(height: 8),
          buildInformationRow(
            'Patients Ahead',
            doctor.queueLength.toString(),
          ),
        ],
      ),
    );
  }

  Widget buildInformationRow(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'How prediction works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Estimated time = number of patients ahead × '
            '12 minutes average consultation time + '
            '5 minutes delay buffer.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This is a simple prediction for the university project.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
