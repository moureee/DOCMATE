import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

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
              return prescription.patientId == appData.currentUserId ||
                  prescription.patientName == appData.currentPatientName;
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
              return buildPrescriptionCard(prescriptions[index]);
            },
          );
        },
      ),
    );
  }

  Widget buildPrescriptionCard(PrescriptionModel prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.medical_services,
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
                      Text('Issued ${formatDate(prescription.date)}'),
                    ],
                  ),
                ),
                const Text(
                  'Rx',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabelValue('Patient', prescription.patientName),
                if (prescription.diagnosis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  buildLabelValue('Diagnosis', prescription.diagnosis),
                ],
                const Divider(height: 30),
                const Text(
                  'Medicines',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...prescription.medicineItems.asMap().entries.map((entry) {
                  final number = entry.key + 1;
                  final medicine = entry.value;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$number. ${medicine.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (medicine.dosage.isNotEmpty)
                              buildMedicineChip('Dose', medicine.dosage),
                            if (medicine.frequency.isNotEmpty)
                              buildMedicineChip(
                                'Frequency',
                                medicine.frequency,
                              ),
                            if (medicine.duration.isNotEmpty)
                              buildMedicineChip(
                                'Duration',
                                medicine.duration,
                              ),
                          ],
                        ),
                        if (medicine.instructions.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            'Instructions: ${medicine.instructions}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (prescription.notes.isNotEmpty) ...[
                  const Divider(height: 30),
                  buildLabelValue('Doctor Advice', prescription.notes),
                ],
                if (prescription.followUpDate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_repeat, color: Colors.orange),
                        const SizedBox(width: 9),
                        Text(
                          'Follow-up: '
                          '${formatDate(prescription.followUpDate!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Use medicines only as directed by your healthcare professional.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget buildMedicineChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
