import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class MedicineScreen extends StatelessWidget {
  const MedicineScreen({super.key});

  void showAddMedicineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final timeController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine name',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'Example: 500 mg',
                    prefixIcon: Icon(Icons.medical_information),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Reminder time',
                    hintText: 'Example: After dinner',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final medicineName = nameController.text.trim();

                if (medicineName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter the medicine name.',
                      ),
                    ),
                  );
                  return;
                }

                AppData.instance.addMedicine(
                  name: medicineName,
                  dosage: dosageController.text.trim(),
                  time: timeController.text.trim(),
                );

                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      dosageController.dispose();
      timeController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines and Reminders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        onPressed: () {
          showAddMedicineDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (appData.medicines.isEmpty) {
            return const Center(
              child: Text(
                'No medicines have been added.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              90,
            ),
            itemCount: appData.medicines.length,
            itemBuilder: (context, index) {
              final medicine = appData.medicines[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: medicine.taken
                          ? Colors.green.shade50
                          : AppColors.lightMint,
                      child: Icon(
                        medicine.taken ? Icons.check : Icons.medication,
                        color: medicine.taken
                            ? Colors.green
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              decoration: medicine.taken
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medicine.dosage.isEmpty
                                ? 'Dosage not entered'
                                : medicine.dosage,
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  medicine.time.isEmpty
                                      ? 'No reminder time'
                                      : medicine.time,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        appData.toggleMedicineTaken(
                          medicine.id,
                        );
                      },
                      tooltip: medicine.taken
                          ? 'Mark as not taken'
                          : 'Mark as taken',
                      icon: Icon(
                        medicine.taken
                            ? Icons.undo
                            : Icons.check_circle_outline,
                        color: medicine.taken ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
