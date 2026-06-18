import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/patient/screens/book_appointment_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  String sort = 'date_asc';
  String statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            tooltip: 'Book appointment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookAppointmentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort appointments',
            initialValue: sort,
            onSelected: (value) => setState(() => sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'date_asc', child: Text('Date: earliest first')),
              PopupMenuItem(
                  value: 'date_desc', child: Text('Date: latest first')),
              PopupMenuItem(value: 'doctor', child: Text('Doctor name')),
              PopupMenuItem(value: 'status', child: Text('Status')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          var appointments = appData.appointments.where((appointment) {
            return appointment.patientId == appData.currentUserId ||
                appointment.patientName == appData.currentPatientName;
          }).toList();

          if (statusFilter != 'All') {
            appointments = appointments
                .where((appointment) => appointment.status == statusFilter)
                .toList();
          }

          switch (sort) {
            case 'date_desc':
              appointments.sort((a, b) => b.date.compareTo(a.date));
              break;
            case 'doctor':
              appointments.sort((a, b) => a.doctorName.compareTo(b.doctorName));
              break;
            case 'status':
              appointments.sort((a, b) => a.status.compareTo(b.status));
              break;
            default:
              appointments.sort((a, b) => a.date.compareTo(b.date));
          }

          return Column(
            children: [
              SizedBox(
                height: 54,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  children: [
                    'All',
                    'Pending',
                    'Accepted',
                    'Completed',
                    'Cancelled',
                    'Rejected'
                  ]
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: statusFilter == status,
                            onSelected: (_) =>
                                setState(() => statusFilter = status),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'You do not have appointments in this category.'),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BookAppointmentScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Book Appointment'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) =>
                            buildAppointmentCard(context, appointments[index]),
                      ),
              ),
            ],
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

    final availableTimes = availabilityTimesForDate(
      selectedDoctor,
      selectedDate,
    );

    if (availableTimes.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No availability was added for ${formatDate(selectedDate)}.',
          ),
        ),
      );
      return;
    }

    final selectedDoctorId = selectedDoctor.id;

    final selectedTime = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(
            'Select Time • ${formatDate(selectedDate)}',
          ),
          children: availableTimes.map((time) {
            final booked = AppData.instance.isSlotBooked(
              selectedDoctorId,
              selectedDate,
              time,
              excludingAppointmentId: appointment.id,
            );
            return SimpleDialogOption(
              onPressed: booked
                  ? null
                  : () {
                      Navigator.pop(dialogContext, time);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(time)),
                    if (booked)
                      const Text(
                        'Booked',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
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
