import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  late final TextEditingController heightController;
  late final TextEditingController weightController;
  late final TextEditingController bloodGroupController;
  late final TextEditingController allergiesController;

  @override
  void initState() {
    super.initState();

    final profile = AppData.instance.healthProfile;

    heightController = TextEditingController(
      text: profile.heightCm.toStringAsFixed(0),
    );

    weightController = TextEditingController(
      text: profile.weightKg.toStringAsFixed(0),
    );

    bloodGroupController = TextEditingController(
      text: profile.bloodGroup,
    );

    allergiesController = TextEditingController(
      text: profile.allergies.join(', '),
    );
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    bloodGroupController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  void saveHealthProfile() {
    final height = double.tryParse(
      heightController.text.trim(),
    );

    final weight = double.tryParse(
      weightController.text.trim(),
    );

    if (height == null || height <= 0) {
      showMessage('Please enter a valid height.');
      return;
    }

    if (weight == null || weight <= 0) {
      showMessage('Please enter a valid weight.');
      return;
    }

    final allergies = allergiesController.text
        .split(',')
        .map((allergy) => allergy.trim())
        .where((allergy) => allergy.isNotEmpty)
        .toList();

    AppData.instance.updateHealthProfile(
      heightCm: height,
      weightKg: weight,
      bloodGroup: bloodGroupController.text.trim(),
      allergies: allergies,
    );

    setState(() {});

    showMessage('Health profile updated successfully.');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppData.instance.healthProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profile and BMI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            buildBmiCard(profile),
            const SizedBox(height: 20),
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Height in centimetres',
                prefixIcon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Weight in kilograms',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bloodGroupController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Blood group',
                hintText: 'Example: B+',
                prefixIcon: Icon(Icons.bloodtype),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: allergiesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                hintText: 'Separate allergies using commas',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveHealthProfile,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Health Profile',
                ),
              ),
            ),
            const SizedBox(height: 18),
            buildSuggestionCard(profile),
          ],
        ),
      ),
    );
  }

  Widget buildBmiCard(HealthProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite,
            size: 42,
          ),
          const SizedBox(height: 8),
          const Text(
            'Current BMI',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.bmi.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            profile.bmiCategory,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestionCard(
    HealthProfileModel profile,
  ) {
    String suggestion;

    if (profile.bmi < 18.5) {
      suggestion = 'Your BMI is below the healthy range. '
          'Consider discussing nutrition with a '
          'healthcare professional.';
    } else if (profile.bmi < 25) {
      suggestion = 'Your BMI is in the healthy range. '
          'Continue balanced meals and regular activity.';
    } else if (profile.bmi < 30) {
      suggestion = 'Your BMI is above the healthy range. '
          'Consider balanced food and regular activity.';
    } else {
      suggestion = 'Your BMI is high. Consider discussing '
          'your health plan with a qualified professional.';
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
