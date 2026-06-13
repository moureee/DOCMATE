import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/doctor/screens/doctor_appointments_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_availability_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_insights_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_patient_info_screen.dart';
import 'package:docmate/features/doctor/screens/prescription_management_screen.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

  void openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return screen;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appData,
          builder: (context, child) {
            if (appData.isLoadingDoctors) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (appData.doctorLoadError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appData.doctorLoadError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: appData.refreshDoctors,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final doctor = appData.currentDoctor;

            if (doctor == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Your doctor profile was not found. Please contact the admin.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final appointments = appData.appointments.where((appointment) {
              return appointment.doctorId == doctor.id;
            }).toList();

            final pendingCount = appointments.where((appointment) {
              return appointment.status == 'Pending';
            }).length;

            final completedCount = appointments.where((appointment) {
              return appointment.status == 'Completed';
            }).length;

            return RefreshIndicator(
              onRefresh: appData.refreshDoctors,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  buildHeader(doctor),
                  const SizedBox(height: 22),
                  buildStatistics(
                    totalAppointments: appointments.length,
                    pendingAppointments: pendingCount,
                    completedAppointments: completedCount,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Doctor Services',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildServiceGrid(
                    context,
                    doctor,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildUpcomingAppointments(
                    context,
                    appointments,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildHeader(DoctorModel doctor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.medical_services,
              size: 40,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(doctor.specialty),
                const SizedBox(height: 4),
                Text(
                  '⭐ ${doctor.rating} • '
                  '${doctor.experience} years',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatistics({
    required int totalAppointments,
    required int pendingAppointments,
    required int completedAppointments,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildStatCard(
            title: 'Patients',
            value: totalAppointments.toString(),
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildStatCard(
            title: 'Pending',
            value: pendingAppointments.toString(),
            icon: Icons.pending_actions,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildStatCard(
            title: 'Completed',
            value: completedAppointments.toString(),
            icon: Icons.task_alt,
          ),
        ),
      ],
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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

  Widget buildServiceGrid(
    BuildContext context,
    DoctorModel doctor,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        buildServiceCard(
          context: context,
          title: 'Appointments',
          icon: Icons.calendar_month,
          screen: const DoctorAppointmentsScreen(),
        ),
        buildServiceCard(
          context: context,
          title: 'Time Slots',
          icon: Icons.schedule,
          screen: DoctorAvailabilityScreen(
            doctor: doctor,
          ),
        ),
        buildServiceCard(
          context: context,
          title: 'Prescriptions',
          icon: Icons.receipt_long,
          screen: PrescriptionManagementScreen(
            doctorName: doctor.name,
          ),
        ),
        buildServiceCard(
          context: context,
          title: 'Patient Information',
          icon: Icons.folder_shared_outlined,
          screen: DoctorPatientInfoScreen(
            doctor: doctor,
          ),
        ),
        buildServiceCard(
          context: context,
          title: 'Basic Insights',
          icon: Icons.analytics_outlined,
          screen: DoctorInsightsScreen(
            doctor: doctor,
          ),
        ),
        buildAverageTimeCard(doctor),
      ],
    );
  }

  Widget buildServiceCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        openScreen(
          context,
          screen,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAverageTimeCard(DoctorModel doctor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.timer_outlined,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Average Time',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${doctor.averageConsultationMinutes} minutes',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUpcomingAppointments(
    BuildContext context,
    List<AppointmentModel> appointments,
  ) {
    final activeAppointments = appointments.where((appointment) {
      return appointment.status == 'Pending' ||
          appointment.status == 'Accepted';
    }).toList();

    activeAppointments.sort((first, second) {
      return first.date.compareTo(second.date);
    });

    if (activeAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: const Center(
          child: Text(
            'No upcoming appointments.',
          ),
        ),
      );
    }

    final displayedAppointments = activeAppointments.take(3);

    return Column(
      children: [
        ...displayedAppointments.map(
          buildUpcomingCard,
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              openScreen(
                context,
                const DoctorAppointmentsScreen(),
              );
            },
            child: const Text(
              'View All Appointments',
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUpcomingCard(
    AppointmentModel appointment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
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
          const CircleAvatar(
            backgroundColor: AppColors.lightMint,
            child: Icon(
              Icons.person,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${formatDate(appointment.date)} • '
                  '${appointment.time}',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                Text(
                  appointment.symptoms,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            appointment.status,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
