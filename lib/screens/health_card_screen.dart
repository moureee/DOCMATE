import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  static const Color mainColor = Color(0xFF00DDB3);
  static const Color lightColor = Color(0xFFE8FFF8);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  String selectedBloodGroup = 'A+';
  double? bmi;
  String bmiCategory = '';
  bool isLoading = true;
  bool isSaving = false;

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    loadHealthCard();
  }

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  Future<void> loadHealthCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('health_cards')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        ageController.text = data['age']?.toString() ?? '';
        weightController.text = data['weight']?.toString() ?? '';
        heightController.text = data['height']?.toString() ?? '';
        allergiesController.text = data['allergies']?.toString() ?? '';
        selectedBloodGroup = data['bloodGroup']?.toString() ?? 'A+';
        calculateBMI();
      }
    } catch (e) {
      debugPrint("Load health card error: $e");
    }

    setState(() => isLoading = false);
  }

  void calculateBMI() {
    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);

    if (weight != null && height != null && height > 0) {
      final heightInMeters = height / 100;
      final calculatedBMI = weight / (heightInMeters * heightInMeters);

      String category;
      if (calculatedBMI < 18.5) {
        category = 'Underweight';
      } else if (calculatedBMI < 25) {
        category = 'Normal';
      } else if (calculatedBMI < 30) {
        category = 'Overweight';
      } else {
        category = 'Obese';
      }

      setState(() {
        bmi = calculatedBMI;
        bmiCategory = category;
      });
    } else {
      setState(() {
        bmi = null;
        bmiCategory = '';
      });
    }
  }

  Future<void> saveHealthCard() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showMessage("Please login first");
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('health_cards')
          .doc(user.uid)
          .set({
        'patientId': user.uid,
        'age': ageController.text.trim(),
        'weight': weightController.text.trim(),
        'height': heightController.text.trim(),
        'bloodGroup': selectedBloodGroup,
        'allergies': allergiesController.text.trim(),
        'bmi': bmi?.toStringAsFixed(1) ?? '',
        'bmiCategory': bmiCategory,
        'updatedAt': Timestamp.now(),
      });

      showMessage("Health Card saved successfully!");
    } catch (e) {
      debugPrint("Save error: $e");
      showMessage("Could not save. Try again.");
    }

    setState(() => isSaving = false);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color getBMIColor() {
    if (bmiCategory == 'Normal') return Colors.green;
    if (bmiCategory == 'Underweight') return Colors.blue;
    if (bmiCategory == 'Overweight') return Colors.orange;
    if (bmiCategory == 'Obese') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text(
          "Health Card",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: mainColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: mainColor,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "My Health Card",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Keep your health info updated",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // BMI Result Card
                    if (bmi != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: getBMIColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: getBMIColor(), width: 2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: getBMIColor(),
                              radius: 28,
                              child: Text(
                                bmi!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Your BMI",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  bmiCategory,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: getBMIColor(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Personal Info Section
                    buildSectionTitle("Personal Info"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: ageController,
                            label: "Age",
                            hint: "e.g. 25",
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (int.tryParse(val) == null) return "Invalid";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildBloodGroupDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Weight & Height
                    buildSectionTitle("Body Measurements"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: weightController,
                            label: "Weight (kg)",
                            hint: "e.g. 65",
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculateBMI(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (double.tryParse(val) == null) return "Invalid";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildTextField(
                            controller: heightController,
                            label: "Height (cm)",
                            hint: "e.g. 170",
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => calculateBMI(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (double.tryParse(val) == null) return "Invalid";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Allergies
                    buildSectionTitle("Allergies"),
                    const SizedBox(height: 12),
                    buildTextField(
                      controller: allergiesController,
                      label: "Known Allergies",
                      hint: "e.g. Penicillin, Peanuts, Dust...",
                      icon: Icons.warning_amber_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveHealthCard,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isSaving ? "Saving..." : "Save Health Card",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: mainColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: mainColor, width: 2),
        ),
      ),
    );
  }

  Widget buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBloodGroup,
      decoration: InputDecoration(
        labelText: "Blood Group",
        prefixIcon: const Icon(Icons.bloodtype_outlined, color: mainColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: mainColor, width: 2),
        ),
      ),
      items: bloodGroups.map((group) {
        return DropdownMenuItem(value: group, child: Text(group));
      }).toList(),
      onChanged: (value) {
        setState(() => selectedBloodGroup = value!);
      },
    );
  }
}