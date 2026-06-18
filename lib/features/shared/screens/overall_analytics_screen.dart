import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class OverallAnalyticsScreen extends StatelessWidget {
  const OverallAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Overall Analytics')),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final now = DateTime.now();
          final role = appData.currentUserRole;
          final appointments = appData.appointments.where((appointment) {
            if (role == 'doctor') {
              return appointment.doctorId == appData.currentUserId;
            }
            return true;
          }).toList();

          bool sameDay(DateTime a, DateTime b) =>
              a.year == b.year && a.month == b.month && a.day == b.day;
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month);

          final today =
              appointments.where((item) => sameDay(item.date, now)).length;
          final thisWeek = appointments
              .where((item) => !item.date.isBefore(startOfWeek))
              .length;
          final thisMonth = appointments
              .where((item) => !item.date.isBefore(startOfMonth))
              .length;
          final completed =
              appointments.where((item) => item.status == 'Completed').length;
          final pending = appointments
              .where((item) =>
                  item.status == 'Pending' ||
                  item.status == 'Accepted' ||
                  item.status == 'In Consultation')
              .length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  role == 'doctor'
                      ? 'Your complete appointment performance'
                      : 'System-wide historical totals',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _grid([
                _Metric('Today', today, Icons.today),
                _Metric('This Week', thisWeek, Icons.date_range),
                _Metric('This Month', thisMonth, Icons.calendar_month),
                _Metric(
                    'All Appointments', appointments.length, Icons.event_note),
                _Metric('Completed', completed, Icons.task_alt),
                _Metric('Active / Pending', pending, Icons.pending_actions),
                if (role == 'admin')
                  _Metric('All Users', appData.totalUserCount, Icons.people),
                if (role == 'admin')
                  _Metric('All Doctors', appData.doctors.length,
                      Icons.medical_services),
                if (role == 'admin')
                  _Metric('Emergency Requests', appData.emergencyRequestCount,
                      Icons.emergency),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _grid(List<_Metric> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: AppColors.primaryDark),
              const SizedBox(height: 8),
              Text(
                item.value.toString(),
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}
