import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';
import 'package:docmate/features/doctor/screens/doctor_profile_screen.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  final List<String> symptoms = [
    'Fever',
    'Headache',
    'Cough',
    'Weakness',
    'Chest pain',
    'Breathing difficulty',
    'Fast heartbeat',
    'Skin rash',
    'Skin itching',
    'Joint pain',
    'Back pain',
    'Stomach pain',
    'Vomiting',
  ];

  final Set<String> selectedSymptoms = {};

  String? suggestedDepartment;
  String? healthSuggestion;
  DoctorModel? recommendedDoctor;

  void checkSymptoms() {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom.'),
        ),
      );
      return;
    }

    final appData = AppData.instance;
    final selected = selectedSymptoms.toList();

    final department = appData.suggestDepartment(selected);

    DoctorModel? doctor;

    for (final item in appData.rankedDoctors) {
      if (item.specialty == department) {
        doctor = item;
        break;
      }
    }

    doctor ??=
        appData.rankedDoctors.isNotEmpty ? appData.rankedDoctors.first : null;

    setState(() {
      suggestedDepartment = department;
      healthSuggestion = appData.healthSuggestion(selected);
      recommendedDoctor = doctor;
    });
  }

  void clearSymptoms() {
    setState(() {
      selectedSymptoms.clear();
      suggestedDepartment = null;
      healthSuggestion = null;
      recommendedDoctor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Checker'),
        actions: [
          IconButton(
            onPressed: clearSymptoms,
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildIntroductionCard(),
            const SizedBox(height: 22),
            const Text(
              'Select Your Symptoms',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: symptoms.map((symptom) {
                final selected = selectedSymptoms.contains(symptom);

                return FilterChip(
                  label: Text(symptom),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.dark,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedSymptoms.add(symptom);
                      } else {
                        selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: checkSymptoms,
                icon: const Icon(Icons.psychology),
                label: const Text('Check Symptoms'),
              ),
            ),
            if (suggestedDepartment != null) ...[
              const SizedBox(height: 24),
              buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildIntroductionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Smart Department Suggestion',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Select symptoms to receive a rule-based department '
            'and doctor suggestion.',
          ),
          SizedBox(height: 8),
          Text(
            'This feature is for demonstration only and does not '
            'provide a medical diagnosis.',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultCard() {
    final doctor = recommendedDoctor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'Smart Result',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          buildResultSection(
            title: 'Suggested Department',
            value: suggestedDepartment ?? '',
          ),
          const SizedBox(height: 14),
          buildResultSection(
            title: 'Health Suggestion',
            value: healthSuggestion ?? '',
          ),
          if (doctor != null) ...[
            const Divider(height: 30),
            const Text(
              'Recommended Doctor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.lightMint,
                child: Icon(
                  Icons.medical_services,
                  color: AppColors.primaryDark,
                ),
              ),
              title: Text(
                doctor.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${doctor.specialty}\n'
                'Rating: ${doctor.rating} • '
                'Queue: ${AppData.instance.predictedQueueMinutes(doctor)} minutes',
              ),
              isThreeLine: true,
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return DoctorProfileScreen(
                        doctorId: doctor.id,
                        doctorName: doctor.name,
                        specialty: doctor.specialty,
                        rating: doctor.rating.toString(),
                        available: doctor.availableSlots.join(', '),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget buildResultSection({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
