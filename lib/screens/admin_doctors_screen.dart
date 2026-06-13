import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class AdminDoctorsScreen extends StatelessWidget {
  const AdminDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Doctors'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (appData.doctors.isEmpty) {
            return const Center(
              child: Text('No doctors found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: appData.doctors.length,
            itemBuilder: (context, index) {
              final doctor = appData.doctors[index];

              return buildDoctorCard(
                context,
                doctor,
              );
            },
          );
        },
      ),
    );
  }

  Widget buildDoctorCard(
    BuildContext context,
    DoctorModel doctor,
  ) {
    final statusColor =
        doctor.approved ? Colors.green.shade50 : Colors.orange.shade50;

    final statusTextColor =
        doctor.approved ? Colors.green.shade700 : Colors.orange.shade800;

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
                radius: 30,
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  Icons.medical_services,
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
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '⭐ ${doctor.rating} • '
                      '${doctor.experience} years',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doctor.approved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    confirmRemoveDoctor(
                      context,
                      doctor,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        doctor.approved ? Colors.orange : Colors.green,
                  ),
                  onPressed: () {
                    AppData.instance.toggleDoctorApproval(
                      doctor.id,
                    );

                    final message = doctor.approved
                        ? 'Doctor approved.'
                        : 'Doctor approval removed.';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                      ),
                    );
                  },
                  icon: Icon(
                    doctor.approved ? Icons.block : Icons.check,
                  ),
                  label: Text(
                    doctor.approved ? 'Unapprove' : 'Approve',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> confirmRemoveDoctor(
    BuildContext context,
    DoctorModel doctor,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Doctor'),
          content: Text(
            'Are you sure you want to remove '
            '${doctor.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    AppData.instance.removeDoctor(
      doctor.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doctor removed.'),
      ),
    );
  }
}
