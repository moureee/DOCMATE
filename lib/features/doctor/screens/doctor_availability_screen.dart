import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class DoctorAvailabilityScreen extends StatelessWidget {
  const DoctorAvailabilityScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  Future<void> showAddSlotDialog(BuildContext context) async {
    final timeController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Time Slot'),
              content: TextField(
                controller: timeController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'Example: 05:30 PM',
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final time = timeController.text.trim();

                          if (time.isEmpty) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await AppData.instance.addAvailability(
                              doctor.id,
                              time,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isSaving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not add the time slot. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(
                    isSaving ? 'Saving...' : 'Add Slot',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    timeController.dispose();
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
                    onPressed: () async {
                      try {
                        await appData.removeAvailability(
                          doctor.id,
                          time,
                        );
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not remove the time slot. Please try again.',
                            ),
                          ),
                        );
                      }
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
