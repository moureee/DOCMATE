import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final prescriptions = appData.prescriptions.where(
            (prescription) {
              return prescription.patientName == appData.currentPatientName;
            },
          ).toList();

          if (prescriptions.isEmpty) {
            return const Center(
              child: Text('No prescriptions found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final prescription = prescriptions[index];

              return buildPrescriptionCard(prescription);
            },
          );
        },
      ),
    );
  }

  Widget buildPrescriptionCard(
    PrescriptionModel prescription,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.doctorName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatDate(prescription.date),
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          const Text(
            'Medicines',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...prescription.medicines.map((medicine) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.medication,
                    size: 19,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(medicine),
                  ),
                ],
              ),
            );
          }),
          if (prescription.notes.isNotEmpty) ...[
            const Divider(height: 28),
            const Text(
              'Doctor Notes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              prescription.notes,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
