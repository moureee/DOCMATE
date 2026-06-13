import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';
import 'admin_doctors_screen.dart';
import 'admin_management_screens.dart';
import 'intro_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

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

  Future<void> logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const IntroScreen();
        },
      ),
      (route) => false,
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
            final approvedDoctors = appData.doctors.where(
              (doctor) {
                return doctor.approved;
              },
            ).length;

            final pendingDoctors = appData.doctors.where(
              (doctor) {
                return !doctor.approved;
              },
            ).length;

            final emergencyUsage = appData.emergencyRequestCount;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                buildHeader(context),
                const SizedBox(height: 22),
                buildDashboardStats(
                  users: appData.totalUserCount > 0
                      ? appData.totalUserCount
                      : appData.patients.length + appData.doctors.length,
                  bookings: appData.appointments.length,
                  emergencyUsage: emergencyUsage,
                ),
                const SizedBox(height: 24),
                buildDoctorSummary(
                  approvedDoctors: approvedDoctors,
                  pendingDoctors: pendingDoctors,
                ),
                const SizedBox(height: 26),
                const Text(
                  'Admin Management',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                buildManagementGrid(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: AppColors.primary,
          child: Icon(
            Icons.admin_panel_settings,
            color: AppColors.dark,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DocMate Administration',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () {
            showLogoutDialog(context);
          },
          icon: const Icon(
            Icons.logout,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Widget buildDashboardStats({
    required int users,
    required int bookings,
    required int emergencyUsage,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildStatCard(
            title: 'Users',
            value: users.toString(),
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildStatCard(
            title: 'Bookings',
            value: bookings.toString(),
            icon: Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildStatCard(
            title: 'Emergency',
            value: emergencyUsage.toString(),
            icon: Icons.emergency,
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
        horizontal: 7,
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
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDoctorSummary({
    required int approvedDoctors,
    required int pendingDoctors,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medical_services,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Doctor Approval Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSummaryValue(
                  title: 'Approved',
                  value: approvedDoctors.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildSummaryValue(
                  title: 'Pending',
                  value: pendingDoctors.toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryValue({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildManagementGrid(
    BuildContext context,
  ) {
    const managementItems = [
      AdminManagementItem(
        title: 'Manage Doctors',
        icon: Icons.medical_services,
        screen: AdminDoctorsScreen(),
      ),
      AdminManagementItem(
        title: 'Manage Patients',
        icon: Icons.people,
        screen: AdminPatientsScreen(),
      ),
      AdminManagementItem(
        title: 'Appointments',
        icon: Icons.calendar_month,
        screen: AdminAppointmentsScreen(),
      ),
      AdminManagementItem(
        title: 'Announcements',
        icon: Icons.campaign,
        screen: AdminAnnouncementsScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: managementItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final item = managementItems[index];

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            openScreen(
              context,
              item.screen,
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
                    item.icon,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showLogoutDialog(
    BuildContext context,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
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
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await logout(context);
  }
}

class AdminManagementItem {
  const AdminManagementItem({
    required this.title,
    required this.icon,
    required this.screen,
  });

  final String title;
  final IconData icon;
  final Widget screen;
}
