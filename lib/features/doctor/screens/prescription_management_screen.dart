import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

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
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final List<PrescriptionMedicineModel> medicineItems =
      <PrescriptionMedicineModel>[];

  String? selectedPatient;
  DateTime? followUpDate;
  bool isSaving = false;

  @override
  void dispose() {
    diagnosisController.dispose();
    medicineNameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    durationController.dispose();
    instructionsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void addMedicineItem() {
    final name = medicineNameController.text.trim();
    if (name.isEmpty) {
      showMessage('Enter the medicine name.');
      return;
    }

    setState(() {
      medicineItems.add(
        PrescriptionMedicineModel(
          name: name,
          dosage: dosageController.text.trim(),
          frequency: frequencyController.text.trim(),
          duration: durationController.text.trim(),
          instructions: instructionsController.text.trim(),
        ),
      );
      medicineNameController.clear();
      dosageController.clear();
      frequencyController.clear();
      durationController.clear();
      instructionsController.clear();
    });
  }

  Future<void> selectFollowUpDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        followUpDate = selected;
      });
    }
  }

  Future<void> savePrescription() async {
    if (selectedPatient == null || selectedPatient!.isEmpty) {
      showMessage('Select a connected patient.');
      return;
    }

    if (medicineItems.isEmpty) {
      showMessage('Add at least one medicine to the prescription.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await AppData.instance.addPrescription(
        patientName: selectedPatient!,
        doctorName: widget.doctorName,
        medicines: List<PrescriptionMedicineModel>.from(medicineItems),
        diagnosis: diagnosisController.text.trim(),
        notes: notesController.text.trim(),
        followUpDate: followUpDate,
      );

      if (!mounted) return;
      setState(() {
        diagnosisController.clear();
        notesController.clear();
        medicineItems.clear();
        followUpDate = null;
      });
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
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primaryDark),
              SizedBox(width: 9),
              Text(
                'Create Clinical Prescription',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Record diagnosis, dosage, frequency, duration, instructions, and follow-up clearly.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
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
                'Patients appear after they book an appointment with you.',
                textAlign: TextAlign.center,
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedPatient,
              decoration: const InputDecoration(
                labelText: 'Patient',
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
            controller: diagnosisController,
            enabled: hasPatients,
            decoration: const InputDecoration(
              labelText: 'Diagnosis / Clinical Impression',
              hintText: 'Example: Viral fever',
              prefixIcon: Icon(Icons.medical_information_outlined),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Medicine Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: medicineNameController,
            enabled: hasPatients,
            decoration: const InputDecoration(
              labelText: 'Medicine name',
              hintText: 'Example: Paracetamol',
              prefixIcon: Icon(Icons.medication),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dosageController,
                  enabled: hasPatients,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: '500 mg',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: frequencyController,
                  enabled: hasPatients,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    hintText: 'Twice daily',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: durationController,
                  enabled: hasPatients,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: '5 days',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: instructionsController,
                  enabled: hasPatients,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    hintText: 'After food',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasPatients ? addMedicineItem : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine to Prescription'),
            ),
          ),
          if (medicineItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(medicineItems.length, (index) {
              final medicine = medicineItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.medication,
                    color: AppColors.primaryDark,
                  ),
                  title: Text(
                    medicine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      medicine.dosage,
                      medicine.frequency,
                      medicine.duration,
                      medicine.instructions,
                    ].where((value) => value.isNotEmpty).join(' • '),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        medicineItems.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.close, color: AppColors.danger),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            enabled: hasPatients,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Advice / Doctor Notes',
              hintText: 'Rest, hydration, warning signs, tests, etc.',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: hasPatients ? selectFollowUpDate : null,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Follow-up date (optional)',
                prefixIcon: Icon(Icons.event_repeat),
              ),
              child: Text(
                followUpDate == null
                    ? 'No follow-up selected'
                    : formatDate(followUpDate!),
              ),
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
                isSaving ? 'Saving...' : 'Issue Prescription',
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
                      'Issued ${formatDate(prescription.date)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (prescription.diagnosis.isNotEmpty) ...[
            const Divider(height: 25),
            Text(
              'Diagnosis: ${prescription.diagnosis}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const Divider(height: 25),
          ...prescription.medicineItems.map((medicine) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    [
                      medicine.dosage,
                      medicine.frequency,
                      medicine.duration,
                      medicine.instructions,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }),
          if (prescription.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Advice: ${prescription.notes}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          if (prescription.followUpDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Follow-up: ${formatDate(prescription.followUpDate!)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
