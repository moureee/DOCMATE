import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class DoctorPatientInfoScreen extends StatelessWidget {
  const DoctorPatientInfoScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Information'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final appointments = appData.appointments.where(
            (appointment) {
              return appointment.doctorId == doctor.id;
            },
          ).toList();

          appointments.sort((first, second) {
            return first.date.compareTo(second.date);
          });

          final patientNames = appointments
              .map((appointment) => appointment.patientName)
              .toSet()
              .toList()
            ..sort();

          if (patientNames.isEmpty) {
            return const Center(
              child: Text('No patient information found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: patientNames.length,
            itemBuilder: (context, index) {
              final patientName = patientNames[index];
              final patientAppointments = appointments.where((appointment) {
                return appointment.patientName == patientName;
              }).toList();

              return buildPatientCard(
                context,
                patientName,
                patientAppointments,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildPatientCard(
    BuildContext context,
    String patientName,
    List<AppointmentModel> appointments,
  ) {
    final latestAppointment = appointments.last;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 29,
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryDark,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${appointments.length} appointment(s)',
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  showPatientDetails(
                    context,
                    patientName,
                    appointments,
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          buildInfoRow(
            Icons.health_and_safety_outlined,
            'Latest Symptoms',
            latestAppointment.symptoms,
          ),
          const SizedBox(height: 10),
          buildInfoRow(
            Icons.calendar_today,
            'Latest Visit',
            '${formatDate(latestAppointment.date)} '
                'at ${latestAppointment.time}',
          ),
        ],
      ),
    );
  }

  void showPatientDetails(
    BuildContext context,
    String patientName,
    List<AppointmentModel> appointments,
  ) {
    final appData = AppData.instance;
    final profile = appData.healthProfileForPatient(patientName);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const CircleAvatar(
                radius: 39,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.person,
                  size: 43,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                patientName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              if (profile != null) ...[
                buildDetailCard(
                  'BMI',
                  profile.bmi == 0
                      ? 'Not available'
                      : '${profile.bmi.toStringAsFixed(1)} '
                          '(${profile.bmiCategory})',
                ),
                buildDetailCard(
                  'Blood Group',
                  profile.bloodGroup.isEmpty
                      ? 'Not recorded'
                      : profile.bloodGroup,
                ),
                buildDetailCard(
                  'Allergies',
                  profile.allergies.isEmpty
                      ? 'No allergies recorded'
                      : profile.allergies.join(', '),
                ),
              ] else ...[
                buildDetailCard(
                  'Health Profile',
                  'The patient has not shared a health profile yet.',
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Appointment History',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...appointments.map((appointment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDate(appointment.date)} '
                        'at ${appointment.time}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Symptoms: ${appointment.symptoms}',
                      ),
                      if (appointment.notes.isNotEmpty)
                        Text(
                          'Notes: ${appointment.notes}',
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: ${appointment.status}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget buildDetailCard(
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
