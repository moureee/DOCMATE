import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

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
          if (appData.isLoadingDoctors && appData.doctors.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (appData.doctorLoadError != null && appData.doctors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Colors.black54,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appData.doctorLoadError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
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

          if (appData.doctors.isEmpty) {
            return RefreshIndicator(
              onRefresh: appData.refreshDoctors,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.medical_services_outlined,
                    size: 54,
                    color: Colors.black45,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text('No doctors found.'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: appData.refreshDoctors,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: appData.doctors.length,
              itemBuilder: (context, index) {
                final doctor = appData.doctors[index];

                return buildDoctorCard(
                  context,
                  doctor,
                );
              },
            ),
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
                      '⭐ ${doctor.rating.toStringAsFixed(1)} • '
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
                  onPressed: () async {
                    try {
                      final approved =
                          await AppData.instance.toggleDoctorApproval(
                        doctor.id,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            approved
                                ? 'Doctor approved.'
                                : 'Doctor approval removed.',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not update the doctor. Please try again.',
                          ),
                        ),
                      );
                    }
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
            'Are you sure you want to remove ${doctor.name}?',
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

    if (shouldRemove != true || !context.mounted) {
      return;
    }

    try {
      await AppData.instance.removeDoctor(doctor.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor removed.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not remove the doctor. Please try again.',
          ),
        ),
      );
    }
  }
}
