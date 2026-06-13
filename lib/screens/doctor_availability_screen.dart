import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class DoctorAvailabilityScreen extends StatelessWidget {
  const DoctorAvailabilityScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  void showAddSlotDialog(BuildContext context) {
    final timeController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Time Slot'),
          content: TextField(
            controller: timeController,
            decoration: const InputDecoration(
              labelText: 'Time',
              hintText: 'Example: 05:30 PM',
              prefixIcon: Icon(Icons.schedule),
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
                final time = timeController.text.trim();

                if (time.isEmpty) {
                  return;
                }

                AppData.instance.addAvailability(
                  doctor.id,
                  time,
                );

                Navigator.pop(dialogContext);
              },
              child: const Text('Add Slot'),
            ),
          ],
        );
      },
    ).whenComplete(
      timeController.dispose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Slot Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        onPressed: () {
          showAddSlotDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (doctor.availableSlots.isEmpty) {
            return const Center(
              child: Text(
                'No available time slots.',
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
            itemCount: doctor.availableSlots.length,
            itemBuilder: (context, index) {
              final time = doctor.availableSlots[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightMint,
                    child: Icon(
                      Icons.schedule,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Available for appointment',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove slot',
                    onPressed: () {
                      appData.removeAvailability(
                        doctor.id,
                        time,
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
