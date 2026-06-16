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
  final Set<String> selectedSymptoms = <String>{};
  final TextEditingController symptomSearchController = TextEditingController();

  String symptomQuery = '';

  String? suggestedDepartment;
  String? urgency;
  String? healthSuggestion;
  DoctorModel? recommendedDoctor;

  @override
  void dispose() {
    symptomSearchController.dispose();
    super.dispose();
  }

  void searchSymptoms() {
    setState(() {
      symptomQuery = symptomSearchController.text.trim().toLowerCase();
    });
  }

  void checkSymptoms(AppData appData) {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom.'),
        ),
      );
      return;
    }

    final selected = selectedSymptoms.toList();
    final department = appData.suggestDepartment(selected);

    DoctorModel? doctor;
    for (final item in appData.rankedDoctors) {
      if (item.specialty.toLowerCase() == department.toLowerCase()) {
        doctor = item;
        break;
      }
    }
    doctor ??=
        appData.rankedDoctors.isNotEmpty ? appData.rankedDoctors.first : null;

    setState(() {
      suggestedDepartment = department;
      urgency = appData.symptomUrgency(selected);
      healthSuggestion = appData.healthSuggestion(selected);
      recommendedDoctor = doctor;
    });
  }

  void clearSymptoms() {
    setState(() {
      selectedSymptoms.clear();
      symptomSearchController.clear();
      symptomQuery = '';
      suggestedDepartment = null;
      urgency = null;
      healthSuggestion = null;
      recommendedDoctor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

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
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final allSymptoms = appData.availableSymptoms;
          final symptoms = symptomQuery.isEmpty
              ? allSymptoms
              : allSymptoms.where((symptom) {
                  return symptom.toLowerCase().contains(symptomQuery);
                }).toList();
          selectedSymptoms.removeWhere(
            (symptom) => !allSymptoms.contains(symptom),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildIntroductionCard(appData),
                const SizedBox(height: 22),
                const Text(
                  'Select Your Symptoms',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: symptomSearchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => searchSymptoms(),
                        decoration: InputDecoration(
                          hintText: 'Search symptoms, e.g. fever',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: symptomSearchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    symptomSearchController.clear();
                                    searchSymptoms();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: searchSymptoms,
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (symptoms.isEmpty)
                  Text(symptomQuery.isEmpty
                      ? 'No symptom rules are currently available.'
                      : 'No symptoms match your search.')
                else
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
                    onPressed:
                        symptoms.isEmpty ? null : () => checkSymptoms(appData),
                    icon: const Icon(Icons.psychology),
                    label: const Text('Check Symptoms'),
                  ),
                ),
                if (suggestedDepartment != null) ...[
                  const SizedBox(height: 24),
                  buildResultCard(appData),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildIntroductionCard(AppData appData) {
    final usingFirestoreRules = appData.symptomRules.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.smart_toy_outlined,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart Department Suggestion',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Select symptoms to receive a rule-based department, urgency, '
            'and doctor suggestion.',
          ),
          const SizedBox(height: 8),
          Text(
            usingFirestoreRules
                ? 'Rules are loaded from the DocMate database.'
                : 'Default rules are being used until an administrator adds database rules.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Educational decision support only. This is not a medical diagnosis.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildResultCard(AppData appData) {
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
            title: 'Urgency',
            value: urgency ?? 'Routine',
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
              style: TextStyle(fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${doctor.specialty}\n'
                'Rating: ${doctor.rating.toStringAsFixed(1)} • '
                'Queue: ${appData.predictedQueueMinutes(doctor)} minutes',
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
                        available: doctor.availableSlots
                            .map(availabilitySlotLabel)
                            .join(', '),
                      );
                    },
                  ),
                );
              },
            ),
          ] else ...[
            const Divider(height: 30),
            const Text(
              'No approved doctor currently matches this suggestion.',
              style: TextStyle(color: Colors.black54),
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
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
