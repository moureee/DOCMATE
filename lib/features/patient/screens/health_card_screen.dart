import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class HealthCardScreen extends StatelessWidget {
  const HealthCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Health Card'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final profile = appData.healthProfile;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              buildMainCard(profile),
              const SizedBox(height: 18),
              buildInformationCard(
                icon: Icons.monitor_weight_outlined,
                title: 'BMI',
                value: '${profile.bmi.toStringAsFixed(1)} '
                    '(${profile.bmiCategory})',
              ),
              buildInformationCard(
                icon: Icons.bloodtype,
                title: 'Blood Group',
                value: profile.bloodGroup,
              ),
              buildInformationCard(
                icon: Icons.warning_amber,
                title: 'Allergies',
                value: profile.allergies.isEmpty
                    ? 'No allergies recorded'
                    : profile.allergies.join(', '),
              ),
              buildInformationCard(
                icon: Icons.medication,
                title: 'Current Medicines',
                value: appData.medicines.isEmpty
                    ? 'No medicines recorded'
                    : appData.medicines.map((medicine) {
                        return '${medicine.name} '
                            '${medicine.dosage}';
                      }).join(', '),
              ),
              buildInformationCard(
                icon: Icons.history,
                title: 'Last Visit',
                value: formatDate(profile.lastVisit),
              ),
              const SizedBox(height: 14),
              buildHealthSuggestion(profile),
            ],
          );
        },
      ),
    );
  }

  Widget buildMainCard(HealthProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF9FF5E5),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 48,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Demo Patient',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'DocMate Digital Health Card',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildSmallValue(
                  title: 'Height',
                  value: '${profile.heightCm.toStringAsFixed(0)} cm',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildSmallValue(
                  title: 'Weight',
                  value: '${profile.weightKg.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSmallValue({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInformationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          CircleAvatar(
            backgroundColor: AppColors.lightMint,
            child: Icon(
              icon,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
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
      ),
    );
  }

  Widget buildHealthSuggestion(
    HealthProfileModel profile,
  ) {
    String suggestion;

    if (profile.bmi < 18.5) {
      suggestion = 'Your BMI is below the healthy range. Consider '
          'discussing nutrition with a healthcare professional.';
    } else if (profile.bmi < 25) {
      suggestion = 'Your BMI is within the healthy range. Continue '
          'balanced meals, activity, and regular check-ups.';
    } else if (profile.bmi < 30) {
      suggestion = 'Your BMI is above the healthy range. Consider '
          'healthy food choices and regular physical activity.';
    } else {
      suggestion = 'Your BMI is high. Consider consulting a qualified '
          'healthcare professional for guidance.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Smart Health Suggestion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            suggestion,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
