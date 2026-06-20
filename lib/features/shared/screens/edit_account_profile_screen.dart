import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class EditAccountProfileScreen extends StatefulWidget {
  const EditAccountProfileScreen({super.key});

  @override
  State<EditAccountProfileScreen> createState() =>
      _EditAccountProfileScreenState();
}

class _EditAccountProfileScreenState extends State<EditAccountProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final specialtyController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceController = TextEditingController();
  final hospitalController = TextEditingController();
  final bioController = TextEditingController();
  final consultationController = TextEditingController();

  bool loading = true;
  bool saving = false;

  bool get isDoctor => AppData.instance.currentUserRole == 'doctor';

  String get screenTitle {
    final role = AppData.instance.currentUserRole;
    if (role == 'doctor') return 'Edit Doctor Profile';
    if (role == 'admin') return 'Edit Admin Profile';
    return 'Edit Account Profile';
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    specialtyController.dispose();
    qualificationController.dispose();
    experienceController.dispose();
    hospitalController.dispose();
    bioController.dispose();
    consultationController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    nameController.text = (userData['name'] ?? '').toString();
    phoneController.text = (userData['phone'] ?? '').toString();

    if (isDoctor) {
      final doctorDoc =
          await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
      final data = doctorDoc.data() ?? <String, dynamic>{};
      specialtyController.text =
          (data['specialty'] ?? data['designation'] ?? '').toString();
      qualificationController.text = (data['qualification'] ?? '').toString();
      experienceController.text =
          (data['experienceYears'] ?? data['experience'] ?? 0).toString();
      hospitalController.text = (data['hospitalName'] ?? '').toString();
      bioController.text = (data['bio'] ?? '').toString();
      consultationController.text =
          (data['averageConsultationMinutes'] ?? 30).toString();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await AppData.instance.updateAccountProfile(
        name: nameController.text,
        phone: phoneController.text,
        specialty: specialtyController.text,
        qualification: qualificationController.text,
        experienceYears: int.tryParse(experienceController.text) ?? 0,
        hospitalName: hospitalController.text,
        bio: bioController.text,
        averageConsultationMinutes:
            int.tryParse(consultationController.text) ?? 30,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightMint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        isDoctor
                            ? 'Update your professional information. Approval status, rating and account role are protected.'
                            : 'Update your account contact information. Account role and UID are protected.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      enabled: false,
                      initialValue:
                          FirebaseAuth.instance.currentUser?.email ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Email (cannot be changed here)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (isDoctor) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Professional details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: specialtyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Specialty / designation',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qualificationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Qualifications',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Experience (years)',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hospitalController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Hospital / clinic',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: consultationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Average consultation time (minutes)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bioController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Professional biography',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Saving...' : 'Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
