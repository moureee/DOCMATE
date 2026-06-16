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
    var selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay? selectedTime;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            String timeLabel() {
              if (selectedTime == null) return 'Select time';
              return selectedTime!.format(context);
            }

            return AlertDialog(
              title: const Text('Add Dated Time Slot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Appointment date'),
                    subtitle: Text(formatDate(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 180),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Appointment time'),
                    subtitle: Text(timeLabel()),
                    trailing: const Icon(Icons.access_time),
                    onTap: isSaving
                        ? null
                        : () async {
                            final picked = await showTimePicker(
                              context: dialogContext,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This slot will be available only on the selected date.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
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
                          if (selectedTime == null) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a time.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await AppData.instance.addAvailability(
                              doctor.id,
                              selectedDate,
                              selectedTime!.format(context),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isSaving = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not add the slot. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(isSaving ? 'Saving...' : 'Add Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability by Date'),
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
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No availability added. Add a date and time for patients to book.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final slots = List<String>.from(doctor.availableSlots)
            ..sort((first, second) {
              final firstDate = availabilitySlotDate(first);
              final secondDate = availabilitySlotDate(second);
              if (firstDate == null && secondDate == null) {
                return first.compareTo(second);
              }
              if (firstDate == null) return 1;
              if (secondDate == null) return -1;
              final dateComparison = firstDate.compareTo(secondDate);
              if (dateComparison != 0) return dateComparison;
              return availabilitySlotTime(first).compareTo(
                availabilitySlotTime(second),
              );
            });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final date = availabilitySlotDate(slot);
              final time = availabilitySlotTime(slot);

              return Container(
                margin: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightMint,
                    child: Icon(
                      Icons.event_available,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    time,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    date == null
                        ? 'Legacy recurring slot • available every day'
                        : '${formatDate(date)} • Available for booking',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove slot',
                    onPressed: () async {
                      try {
                        await appData.removeAvailability(doctor.id, slot);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not remove the slot. Please try again.',
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
