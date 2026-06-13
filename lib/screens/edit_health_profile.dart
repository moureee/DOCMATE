import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditHealthProfile extends StatefulWidget {
  final String uid;

  const EditHealthProfile({
    super.key,
    required this.uid,
  });

  @override
  State<EditHealthProfile> createState() => _EditHealthProfileState();
}

class _EditHealthProfileState extends State<EditHealthProfile> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final allergiesController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHealthProfile();
  }

  Future<void> loadHealthProfile() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('health_profiles')
        .doc(widget.uid)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      heightController.text = data['height'] ?? '';
      weightController.text = data['weight'] ?? '';
      bloodGroupController.text = data['bloodGroup'] ?? '';
      allergiesController.text = data['allergies'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveHealthProfile() async {
    await FirebaseFirestore.instance
        .collection('health_profiles')
        .doc(widget.uid)
        .set({
      'uid': widget.uid,
      'height': heightController.text.trim(),
      'weight': weightController.text.trim(),
      'bloodGroup': bloodGroupController.text.trim(),
      'allergies': allergiesController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health profile updated')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    bloodGroupController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FFF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D9B8),
        title: const Text('Edit Health Profile'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D9B8),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  profileField(
                    controller: heightController,
                    label: 'Height in cm',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  profileField(
                    controller: weightController,
                    label: 'Weight in kg',
                    icon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  profileField(
                    controller: bloodGroupController,
                    label: 'Blood Group',
                    icon: Icons.bloodtype,
                  ),
                  const SizedBox(height: 15),
                  profileField(
                    controller: allergiesController,
                    label: 'Allergies',
                    icon: Icons.warning_amber,
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saveHealthProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(
                            color: Color(0xFF00D9B8),
                            width: 3,
                          ),
                        ),
                      ),
                      child: const Text(
                        'SAVE HEALTH PROFILE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00D9B8)),
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
