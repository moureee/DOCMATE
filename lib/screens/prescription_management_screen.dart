import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  const PrescriptionManagementScreen({
    super.key,
    required this.doctorName,
  });

  final String doctorName;

  @override
  State<PrescriptionManagementScreen> createState() =>
      _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState
    extends State<PrescriptionManagementScreen> {
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedPatient;
  bool isSaving = false;

  @override
  void dispose() {
    medicineController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> savePrescription() async {
    final medicineText = medicineController.text.trim();

    if (selectedPatient == null || selectedPatient!.isEmpty) {
      showMessage('No connected patient is available.');
      return;
    }

    if (medicineText.isEmpty) {
      showMessage('Please enter at least one medicine.');
      return;
    }

    final medicines = medicineText
        .split(',')
        .map((medicine) => medicine.trim())
        .where((medicine) => medicine.isNotEmpty)
        .toList();

    setState(() {
      isSaving = true;
    });

    try {
      await AppData.instance.addPrescription(
        patientName: selectedPatient!,
        doctorName: widget.doctorName,
        medicines: medicines,
        notes: notesController.text.trim(),
      );

      medicineController.clear();
      notesController.clear();

      if (!mounted) return;
      showMessage('Prescription saved successfully.');
    } catch (error) {
      if (!mounted) return;
      showMessage(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Management'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (selectedPatient != null &&
              !appData.patients.contains(selectedPatient)) {
            selectedPatient = null;
          }
          selectedPatient ??=
              appData.patients.isEmpty ? null : appData.patients.first;

          final doctorPrescriptions = appData.prescriptions.where(
            (prescription) {
              return prescription.doctorId == appData.currentUserId ||
                  prescription.doctorName == widget.doctorName;
            },
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              buildPrescriptionForm(appData),
              const SizedBox(height: 28),
              const Text(
                'Recent Prescriptions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (doctorPrescriptions.isEmpty)
                buildEmptyMessage()
              else
                ...doctorPrescriptions.map(buildPrescriptionCard),
            ],
          );
        },
      ),
    );
  }

  Widget buildPrescriptionForm(AppData appData) {
    final hasPatients = appData.patients.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightMint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Prescription',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasPatients)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Patients appear here after they book an appointment with you.',
                textAlign: TextAlign.center,
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedPatient,
              decoration: const InputDecoration(
                labelText: 'Select Patient',
                prefixIcon: Icon(Icons.person),
              ),
              items: appData.patients.map((patient) {
                return DropdownMenuItem<String>(
                  value: patient,
                  child: Text(patient),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPatient = value;
                });
              },
            ),
          const SizedBox(height: 14),
          TextField(
            controller: medicineController,
            enabled: hasPatients,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Medicines',
              hintText: 'Example: Paracetamol 500 mg, Vitamin D',
              prefixIcon: Icon(Icons.medication),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            enabled: hasPatients,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Doctor Notes',
              hintText: 'Example: Take rest and drink water',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !hasPatients || isSaving ? null : savePrescription,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                isSaving ? 'Saving...' : 'Save Prescription',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPrescriptionCard(PrescriptionModel prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatDate(prescription.date),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Text(
            prescription.medicines.join(', '),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (prescription.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              prescription.notes,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildEmptyMessage() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text('No prescriptions created yet.'),
      ),
    );
  }
}
