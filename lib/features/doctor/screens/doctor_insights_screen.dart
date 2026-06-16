import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class DoctorInsightsScreen extends StatelessWidget {
  const DoctorInsightsScreen({
    super.key,
    required this.doctor,
  });

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final appointments = AppData.instance.appointments.where(
      (appointment) {
        final isToday = appointment.date.year == now.year &&
            appointment.date.month == now.month &&
            appointment.date.day == now.day;
        return appointment.doctorId == doctor.id && isToday;
      },
    ).toList();

    final uniquePatients = appointments
        .map((appointment) => appointment.patientName)
        .toSet()
        .length;

    final pendingAppointments = appointments.where((appointment) {
      return appointment.status == 'Pending';
    }).length;

    final completedAppointments = appointments.where((appointment) {
      return appointment.status == 'Completed';
    }).length;

    final completionRate = appointments.isEmpty
        ? 0
        : (completedAppointments / appointments.length * 100).round();
    final measuredTimes = appointments
        .map((appointment) => appointment.consultationMinutes)
        .whereType<int>()
        .toList();
    final averageConsultationMinutes = measuredTimes.isEmpty
        ? doctor.averageConsultationMinutes
        : (measuredTimes.reduce((a, b) => a + b) / measuredTimes.length)
            .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Insights"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(doctor.specialty),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              buildInsightCard(
                title: "Today's Patients",
                value: uniquePatients.toString(),
                icon: Icons.people,
              ),
              buildInsightCard(
                title: "Today's Appointments",
                value: appointments.length.toString(),
                icon: Icons.calendar_month,
              ),
              buildInsightCard(
                title: "Today's Pending",
                value: pendingAppointments.toString(),
                icon: Icons.pending_actions,
              ),
              buildInsightCard(
                title: "Today's Completed",
                value: completedAppointments.toString(),
                icon: Icons.task_alt,
              ),
              buildInsightCard(
                title: 'Average Time',
                value: '$averageConsultationMinutes min',
                icon: Icons.timer_outlined,
              ),
              buildInsightCard(
                title: 'Completion Rate',
                value: '$completionRate%',
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'About These Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Text(
                  'The values show today only and are calculated from live appointment '
                  'records stored in Firestore. Average time uses completed '
                  'consultations when timing data is available.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightMint,
            child: Icon(
              icon,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
