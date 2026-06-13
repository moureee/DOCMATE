import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final appointments = appData.appointments.where((appointment) {
            return appointment.patientId == appData.currentUserId ||
                appointment.patientName == appData.currentPatientName;
          }).toList();

          appointments.sort(
            (firstAppointment, secondAppointment) {
              return firstAppointment.date.compareTo(
                secondAppointment.date,
              );
            },
          );

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                'You do not have any appointments.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              return buildAppointmentCard(
                context,
                appointment,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildAppointmentCard(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    final canChange = appointment.status != 'Cancelled' &&
        appointment.status != 'Completed' &&
        appointment.status != 'Rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
                      appointment.doctorName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      appointment.specialty,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              buildStatusBadge(
                appointment.status,
              ),
            ],
          ),
          const Divider(height: 26),
          buildInformationRow(
            Icons.calendar_today,
            formatDate(appointment.date),
          ),
          const SizedBox(height: 8),
          buildInformationRow(
            Icons.schedule,
            appointment.time,
          ),
          const SizedBox(height: 8),
          buildInformationRow(
            Icons.health_and_safety_outlined,
            appointment.symptoms,
          ),
          if (appointment.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            buildInformationRow(
              Icons.notes,
              appointment.notes,
            ),
          ],
          if (canChange) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      rescheduleAppointment(
                        context,
                        appointment,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_calendar,
                    ),
                    label: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: () {
                      confirmCancellation(
                        context,
                        appointment,
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
          if (appointment.status == 'Completed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showReviewDialog(context, appointment);
                },
                icon: const Icon(Icons.star_outline),
                label: const Text('Rate Doctor'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> confirmCancellation(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text(
            'Are you sure you want to cancel this appointment?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        await AppData.instance.cancelAppointment(appointment.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled.')),
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Bad state: ', ''),
            ),
          ),
        );
      }
    }
  }

  Future<void> rescheduleAppointment(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    DoctorModel? selectedDoctor;

    for (final doctor in AppData.instance.doctors) {
      if (doctor.id == appointment.doctorId) {
        selectedDoctor = doctor;
        break;
      }
    }

    if (selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Doctor information was not found.',
          ),
        ),
      );
      return;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: appointment.date.isBefore(DateTime.now())
          ? DateTime.now()
          : appointment.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ),
    );

    if (selectedDate == null) return;

    if (!context.mounted) return;

    final selectedTime = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Select New Time'),
          children: selectedDoctor!.availableSlots.map((slot) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  slot,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                ),
                child: Text(slot),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedTime == null) return;

    try {
      await AppData.instance.rescheduleAppointment(
        appointmentId: appointment.id,
        date: selectedDate,
        time: selectedTime,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> showReviewDialog(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final commentController = TextEditingController();
    var rating = 5;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate ${appointment.doctorName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                setDialogState(() {
                                  rating = starValue;
                                });
                              },
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    enabled: !isSaving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
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
                          setDialogState(() {
                            isSaving = true;
                          });
                          try {
                            await AppData.instance.addReview(
                              appointment: appointment,
                              rating: rating,
                              comment: commentController.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review submitted.'),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    error
                                        .toString()
                                        .replaceFirst('Bad state: ', ''),
                                  ),
                                ),
                              );
                            }
                            setDialogState(() {
                              isSaving = false;
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  Widget buildInformationRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  Widget buildStatusBadge(String status) {
    Color badgeColor;

    switch (status) {
      case 'Accepted':
        badgeColor = Colors.green;
        break;

      case 'Completed':
        badgeColor = Colors.blue;
        break;

      case 'Cancelled':
      case 'Rejected':
        badgeColor = Colors.red;
        break;

      default:
        badgeColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
