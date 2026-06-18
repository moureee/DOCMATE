import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String sort = 'date_asc';
  String statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appointments'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort appointments',
            initialValue: sort,
            onSelected: (value) => setState(() => sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'date_asc', child: Text('Date: earliest first')),
              PopupMenuItem(
                  value: 'date_desc', child: Text('Date: latest first')),
              PopupMenuItem(value: 'patient', child: Text('Patient name')),
              PopupMenuItem(value: 'status', child: Text('Status')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final doctor = appData.currentDoctor;
          if (doctor == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var appointments = appData.appointments
              .where((appointment) => appointment.doctorId == doctor.id)
              .toList();
          if (statusFilter != 'All') {
            appointments = appointments
                .where((appointment) => appointment.status == statusFilter)
                .toList();
          }

          switch (sort) {
            case 'date_desc':
              appointments.sort((a, b) => b.date.compareTo(a.date));
              break;
            case 'patient':
              appointments
                  .sort((a, b) => a.patientName.compareTo(b.patientName));
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
                    ? const Center(child: Text('No appointments found.'))
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${formatDate(appointment.date)} at '
                      '${appointment.time}',
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              buildStatusBadge(appointment.status),
            ],
          ),
          const Divider(height: 28),
          buildInformationRow(
            Icons.health_and_safety_outlined,
            'Symptoms',
            appointment.symptoms,
          ),
          if (appointment.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            buildInformationRow(
              Icons.notes,
              'Pre-visit Notes',
              appointment.notes,
            ),
          ],
          const SizedBox(height: 16),
          buildActionButtons(
            context,
            appointment,
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons(
    BuildContext context,
    AppointmentModel appointment,
  ) {
    if (appointment.status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              onPressed: () {
                changeStatus(
                  context,
                  appointment,
                  'Rejected',
                );
              },
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                changeStatus(
                  context,
                  appointment,
                  'Accepted',
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
            ),
          ),
        ],
      );
    }

    if (appointment.status == 'Accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            changeStatus(
              context,
              appointment,
              'Completed',
            );
          },
          icon: const Icon(Icons.task_alt),
          label: const Text('Mark as Completed'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'No action required. Appointment is '
        '${appointment.status.toLowerCase()}.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black54,
        ),
      ),
    );
  }

  Future<void> changeStatus(
    BuildContext context,
    AppointmentModel appointment,
    String status,
  ) async {
    try {
      await AppData.instance.updateAppointmentStatus(
        appointmentId: appointment.id,
        status: status,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment marked as $status.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment status could not be updated.'),
        ),
      );
    }
  }

  Widget buildInformationRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
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
              const SizedBox(height: 3),
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
        horizontal: 10,
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
