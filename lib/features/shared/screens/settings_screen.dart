import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/auth/screens/intro_screen.dart';
import 'package:docmate/features/patient/screens/health_card_screen.dart';
import 'package:docmate/features/patient/screens/health_profile_screen.dart';
import 'package:docmate/features/patient/screens/patient_profile_screen.dart';
import 'package:docmate/features/shared/screens/edit_account_profile_screen.dart';
import 'package:docmate/features/shared/screens/notifications_screen.dart';
import 'package:docmate/features/shared/screens/overall_analytics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout from DocMate?'),
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

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IntroScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final role = appData.currentUserRole;
          final unreadCount =
              appData.notifications.where((item) => !item.read).length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.settings,
                        color: AppColors.primaryDark,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appData.currentDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.isEmpty
                                ? 'DocMate account'
                                : '${role[0].toUpperCase()}${role.substring(1)} settings',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              buildTile(
                context: context,
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: unreadCount == 0
                    ? 'No unread notifications'
                    : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                screen: const NotificationsScreen(),
              ),
              if (role == 'patient') ...[
                buildTile(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Patient Profile',
                  subtitle: 'View profile, prescriptions and quick actions',
                  screen: const PatientProfileScreen(),
                ),
                buildTile(
                  context: context,
                  icon: Icons.monitor_heart_outlined,
                  title: 'Health Profile',
                  subtitle: 'Height, weight, allergies and blood group',
                  screen: const HealthProfileScreen(),
                ),
                buildTile(
                  context: context,
                  icon: Icons.badge_outlined,
                  title: 'Quick Health Card',
                  subtitle: 'Emergency-ready health summary',
                  screen: const HealthCardScreen(),
                ),
              ] else ...[
                buildTile(
                  context: context,
                  icon: Icons.manage_accounts_outlined,
                  title: role == 'admin' ? 'Admin Profile' : 'Doctor Profile',
                  subtitle: 'Edit name, phone and professional details',
                  screen: const EditAccountProfileScreen(),
                ),
                buildTile(
                  context: context,
                  icon: Icons.query_stats,
                  title: 'Overall Analytics',
                  subtitle: 'View total, weekly and monthly activity',
                  screen: const OverallAnalyticsScreen(),
                ),
              ],
              const SizedBox(height: 10),
              buildInformationCard(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightMint,
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 17),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }

  Widget buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                'Security & Privacy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'DocMate keeps role-based access for patient, doctor and admin features. Do not share test account passwords or Firebase credentials.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
