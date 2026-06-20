import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/doctor/screens/doctor_appointments_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_availability_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_insights_screen.dart';
import 'package:docmate/features/doctor/screens/doctor_patient_info_screen.dart';
import 'package:docmate/features/doctor/screens/prescription_management_screen.dart';
import 'package:docmate/features/shared/screens/chat_screen.dart';
import 'package:docmate/features/shared/screens/overall_analytics_screen.dart';
import 'package:docmate/features/shared/screens/notifications_screen.dart';
import 'package:docmate/features/shared/screens/settings_screen.dart';

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

            final now = DateTime.now();
            bool isToday(DateTime date) {
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            }

            final todayAppointments = appointments.where((appointment) {
              return isToday(appointment.date);
            }).toList();

            final todayPatientCount = todayAppointments
                .map((appointment) => appointment.patientId.isEmpty
                    ? appointment.patientName
                    : appointment.patientId)
                .toSet()
                .length;

            final pendingCount = todayAppointments.where((appointment) {
              return appointment.status == 'Pending' ||
                  appointment.status == 'Accepted' ||
                  appointment.status == 'In Consultation';
            }).length;

            final completedCount = todayAppointments.where((appointment) {
              return appointment.status == 'Completed';
            }).length;

            return RefreshIndicator(
              onRefresh: appData.refreshDoctors,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  buildHeader(context, doctor),
                  const SizedBox(height: 22),
                  buildStatistics(
                    todayPatients: todayPatientCount,
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

  Widget buildHeader(BuildContext context, DoctorModel doctor) {
    final unreadCount = AppData.instance.notifications.where((notification) {
      return !notification.read;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final doctorInfo = Row(
            children: [
              CircleAvatar(
                radius: compact ? 30 : 38,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.medical_services,
                  size: 38,
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
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      doctor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 19 : 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doctor.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐ ${doctor.rating} • ${doctor.experience} years',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Row(
            children: [
              Expanded(
                child: buildHeaderAction(
                  context: context,
                  tooltip: 'Notifications',
                  label: 'Alerts',
                  icon: Icons.notifications_none,
                  screen: const NotificationsScreen(),
                  badgeCount: unreadCount,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildHeaderAction(
                  context: context,
                  tooltip: 'Settings',
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  screen: const SettingsScreen(),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                doctorInfo,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: doctorInfo),
              const SizedBox(width: 18),
              SizedBox(
                width: 220,
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildHeaderAction({
    required BuildContext context,
    required String tooltip,
    required String label,
    required IconData icon,
    required Widget screen,
    int badgeCount = 0,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        openScreen(context, screen);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xEFFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: AppColors.dark,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatistics({
    required int todayPatients,
    required int pendingAppointments,
    required int completedAppointments,
  }) {
    final items = [
      (
        title: "Today's Patients",
        value: todayPatients.toString(),
        icon: Icons.people,
      ),
      (
        title: "Today's Pending",
        value: pendingAppointments.toString(),
        icon: Icons.pending_actions,
      ),
      (
        title: "Today's Completed",
        value: completedAppointments.toString(),
        icon: Icons.task_alt,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 350
                ? 2
                : 1;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: buildStatCard(
                title: item.title,
                value: item.value,
                icon: item.icon,
              ),
            );
          }).toList(),
        );
      },
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
    final services = <Widget>[
      buildServiceCard(
        context: context,
        title: 'Appointments',
        icon: Icons.calendar_month,
        screen: const DoctorAppointmentsScreen(),
      ),
      buildServiceCard(
        context: context,
        title: 'Weekly Availability',
        icon: Icons.schedule,
        screen: DoctorAvailabilityScreen(doctor: doctor),
      ),
      buildServiceCard(
        context: context,
        title: 'Prescriptions',
        icon: Icons.receipt_long,
        screen: PrescriptionManagementScreen(doctorName: doctor.name),
      ),
      buildServiceCard(
        context: context,
        title: 'Patient Information',
        icon: Icons.folder_shared_outlined,
        screen: DoctorPatientInfoScreen(doctor: doctor),
      ),
      buildServiceCard(
        context: context,
        title: 'Patient Chat',
        icon: Icons.chat_bubble_outline,
        screen: const ChatScreen(),
      ),
      buildServiceCard(
        context: context,
        title: 'Today Insights',
        icon: Icons.analytics_outlined,
        screen: DoctorInsightsScreen(doctor: doctor),
      ),
      buildServiceCard(
        context: context,
        title: 'Overall Analytics',
        icon: Icons.query_stats,
        screen: const OverallAnalyticsScreen(),
      ),
      buildAverageTimeCard(doctor),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 700
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 145,
          ),
          itemBuilder: (context, index) => services[index],
        );
      },
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
