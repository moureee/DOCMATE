import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final TextEditingController symptomsController = TextEditingController();

  final TextEditingController notesController = TextEditingController();

  DateTime selectedDate = DateTime.now().add(
    const Duration(days: 1),
  );

  String? selectedTime;
  bool isSaving = false;

  @override
  void dispose() {
    symptomsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ),
    );

    if (selected != null) {
      setState(() {
        selectedDate = selected;
      });
    }
  }

  Future<void> confirmAppointment() async {
    if (selectedTime == null) {
      showMessage('Please select a time slot.');
      return;
    }

    if (symptomsController.text.trim().isEmpty) {
      showMessage('Please write your symptoms.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await AppData.instance.bookAppointment(
        doctor: widget.doctor,
        date: selectedDate,
        time: selectedTime!,
        symptoms: symptomsController.text.trim(),
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Appointment Booked'),
            content: Text(
              'Your appointment with ${widget.doctor.name} '
              'has been booked for ${formatDate(selectedDate)} '
              'at $selectedTime.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showMessage(
        error.toString().replaceFirst('Bad state: ', ''),
      );
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
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDoctorCard(),
            const SizedBox(height: 24),
            buildTitle('Select Date'),
            const SizedBox(height: 10),
            InkWell(
              onTap: selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: buildWhiteCardDecoration(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDate(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            buildTitle('Select Time Slot'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.doctor.availableSlots.map((time) {
                final isSelected = selectedTime == time;

                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            buildTitle('Symptoms'),
            const SizedBox(height: 10),
            TextField(
              controller: symptomsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Example: fever, headache, cough',
                prefixIcon: Icon(
                  Icons.health_and_safety_outlined,
                ),
              ),
            ),
            const SizedBox(height: 18),
            buildTitle('Pre-visit Notes'),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write extra information for the doctor',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : confirmAppointment,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  isSaving ? 'Booking...' : 'Confirm Appointment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services,
              size: 34,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.doctor.specialty),
                const SizedBox(height: 4),
                Text(
                  '⭐ ${widget.doctor.rating} • '
                  '${widget.doctor.experience} years',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  BoxDecoration buildWhiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade300,
      ),
    );
  }
}
