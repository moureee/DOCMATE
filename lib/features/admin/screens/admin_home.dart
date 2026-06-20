import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/admin/screens/admin_doctors_screen.dart';
import 'package:docmate/features/admin/screens/admin_emergency_requests_screen.dart';
import 'package:docmate/features/admin/screens/admin_management_screens.dart';
import 'package:docmate/features/admin/screens/admin_symptom_rules_screen.dart';
import 'package:docmate/features/auth/screens/intro_screen.dart';
import 'package:docmate/features/shared/screens/notifications_screen.dart';
import 'package:docmate/features/shared/screens/overall_analytics_screen.dart';
import 'package:docmate/features/shared/screens/settings_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const IntroScreen()),
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
            final approvedDoctors = appData.doctors.where((doctor) {
              return doctor.approved;
            }).length;

            final pendingDoctors = appData.doctors.where((doctor) {
              return !doctor.approved && doctor.available;
            }).length;

            final now = DateTime.now();
            bool isToday(DateTime date) {
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            }

            final todayBookings = appData.appointments.where((appointment) {
              return isToday(appointment.date);
            }).length;
            final todayEmergencyUsage =
                appData.emergencyRequests.where((request) {
              return isToday(request.createdAt);
            }).length;
            final todayUsers = appData.todayUserCount;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                buildHeader(context),
                const SizedBox(height: 22),
                buildDashboardStats(
                  users: todayUsers,
                  bookings: todayBookings,
                  emergencyUsage: todayEmergencyUsage,
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
          final title = Row(
            children: [
              CircleAvatar(
                radius: compact ? 30 : 36,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primaryDark,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DocMate Administration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Admin Dashboard',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
              const SizedBox(width: 8),
              Expanded(
                child: buildLogoutAction(context),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 18),
              SizedBox(width: 310, child: actions),
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
      onTap: () => openScreen(context, screen),
      child: buildActionContent(
        tooltip: tooltip,
        label: label,
        icon: icon,
        badgeCount: badgeCount,
      ),
    );
  }

  Widget buildLogoutAction(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showLogoutDialog(context),
      child: buildActionContent(
        tooltip: 'Logout',
        label: 'Logout',
        icon: Icons.logout,
        iconColor: AppColors.danger,
      ),
    );
  }

  Widget buildActionContent({
    required String tooltip,
    required String label,
    required IconData icon,
    Color iconColor = AppColors.dark,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
                Icon(icon, color: iconColor, size: 26),
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
                  color: AppColors.dark,
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

  Widget buildDashboardStats({
    required int users,
    required int bookings,
    required int emergencyUsage,
  }) {
    final items = [
      (title: "Today's Users", value: users.toString(), icon: Icons.people),
      (
        title: "Today's Bookings",
        value: bookings.toString(),
        icon: Icons.calendar_month,
      ),
      (
        title: "Today's Emergency",
        value: emergencyUsage.toString(),
        icon: Icons.emergency,
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
                context: context,
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
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF31413F) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
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
              Icon(Icons.medical_services, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Doctor Approval Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
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
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget buildManagementGrid(BuildContext context) {
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
      AdminManagementItem(
        title: 'Emergency Requests',
        icon: Icons.emergency,
        screen: AdminEmergencyRequestsScreen(),
      ),
      AdminManagementItem(
        title: 'Symptom Rules',
        icon: Icons.psychology,
        screen: AdminSymptomRulesScreen(),
      ),
      AdminManagementItem(
        title: 'Overall Analytics',
        icon: Icons.query_stats,
        screen: OverallAnalyticsScreen(),
      ),
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
          itemCount: managementItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 145,
          ),
          itemBuilder: (context, index) {
            final item = managementItems[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => openScreen(context, item.screen),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? const Color(0xFF31413F) : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.lightMint,
                      child: Icon(item.icon, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    if (!context.mounted) return;
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
