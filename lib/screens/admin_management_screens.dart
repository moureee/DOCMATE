import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

// ==================================================
// MANAGE PATIENTS
// ==================================================

class AdminPatientsScreen extends StatelessWidget {
  const AdminPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: appData.patients.length,
        itemBuilder: (context, index) {
          final patient = appData.patients[index];

          final appointmentCount = appData.appointments.where(
            (appointment) {
              return appointment.patientName == patient;
            },
          ).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  Icons.person,
                  color: AppColors.primaryDark,
                ),
              ),
              title: Text(
                patient,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '$appointmentCount appointment(s)',
              ),
              trailing: Text(
                'P${1001 + index}',
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================================================
// MONITOR APPOINTMENTS
// ==================================================

class AdminAppointmentsScreen extends StatelessWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Appointments'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final appointments = List<AppointmentModel>.from(
            appData.appointments,
          );

          appointments.sort(
            (first, second) {
              return first.date.compareTo(second.date);
            },
          );

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No appointments found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              return buildAppointmentCard(
                appointment,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildAppointmentCard(
    AppointmentModel appointment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
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
                  Icons.calendar_month,
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
                      appointment.doctorName,
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
          buildInfoRow(
            Icons.calendar_today,
            formatDate(appointment.date),
          ),
          const SizedBox(height: 7),
          buildInfoRow(
            Icons.schedule,
            appointment.time,
          ),
          const SizedBox(height: 7),
          buildInfoRow(
            Icons.health_and_safety_outlined,
            appointment.symptoms,
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget buildStatusBadge(String status) {
    Color textColor;
    Color backgroundColor;

    switch (status) {
      case 'Accepted':
        textColor = Colors.green.shade700;
        backgroundColor = Colors.green.shade50;
        break;

      case 'Completed':
        textColor = Colors.blue.shade700;
        backgroundColor = Colors.blue.shade50;
        break;

      case 'Rejected':
      case 'Cancelled':
        textColor = Colors.red.shade700;
        backgroundColor = Colors.red.shade50;
        break;

      default:
        textColor = Colors.orange.shade800;
        backgroundColor = Colors.orange.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==================================================
// SEND ANNOUNCEMENTS
// ==================================================

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendAnnouncement() {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please write an announcement.',
          ),
        ),
      );
      return;
    }

    AppData.instance.sendAnnouncement(message);

    messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Announcement sent successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Control'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final adminAnnouncements = appData.notifications.where(
            (notification) {
              return notification.title == 'Admin Announcement';
            },
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send Announcement',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write a message for all users...',
                        prefixIcon: Icon(Icons.campaign),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: sendAnnouncement,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'Send Announcement',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Previous Announcements',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (adminAnnouncements.isEmpty)
                buildEmptyMessage()
              else
                ...adminAnnouncements.map(
                  buildAnnouncementCard,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildAnnouncementCard(
    NotificationModel notification,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.campaign,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 7),
                Text(
                  formatDate(notification.date),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyMessage() {
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
          'No announcements have been sent.',
        ),
      ),
    );
  }
}
