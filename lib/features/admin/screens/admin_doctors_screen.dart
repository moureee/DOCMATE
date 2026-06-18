import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  String sort = 'name';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Requests & Accounts'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Disabled'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort doctors',
            initialValue: sort,
            onSelected: (value) => setState(() => sort = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Name A–Z')),
              PopupMenuItem(value: 'specialty', child: Text('Specialty')),
              PopupMenuItem(value: 'rating', child: Text('Highest rating')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          if (appData.isLoadingDoctors && appData.doctors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: tabController,
            children: [
              _list(appData.doctors
                  .where((d) => !d.approved && d.available)
                  .toList()),
              _list(appData.doctors
                  .where((d) => d.approved && d.available)
                  .toList()),
              _list(appData.doctors.where((d) => !d.available).toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _list(List<DoctorModel> doctors) {
    switch (sort) {
      case 'specialty':
        doctors.sort((a, b) => a.specialty.compareTo(b.specialty));
        break;
      case 'rating':
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        doctors.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    if (doctors.isEmpty) {
      return RefreshIndicator(
        onRefresh: AppData.instance.refreshDoctors,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 170),
            Icon(Icons.inbox_outlined, size: 54, color: Colors.black38),
            SizedBox(height: 12),
            Center(child: Text('No doctors in this category.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: AppData.instance.refreshDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: doctors.length,
        itemBuilder: (context, index) => _card(doctors[index]),
      ),
    );
  }

  Widget _card(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.lightMint,
                child:
                    Icon(Icons.medical_services, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(doctor.specialty),
                    if (doctor.qualification.isNotEmpty)
                      Text(
                        doctor.qualification,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    Text(
                      '${doctor.experience} years • ${doctor.rating.toStringAsFixed(1)} rating',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  !doctor.available
                      ? 'Disabled'
                      : doctor.approved
                          ? 'Approved'
                          : 'Pending',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRemove(doctor),
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.danger),
                  label: const Text('Remove'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !doctor.available
                        ? AppColors.primaryDark
                        : doctor.approved
                            ? Colors.orange
                            : Colors.green,
                  ),
                  onPressed: () =>
                      !doctor.available ? _restore(doctor) : _toggle(doctor),
                  icon: Icon(
                    !doctor.available
                        ? Icons.restore
                        : doctor.approved
                            ? Icons.block
                            : Icons.check,
                  ),
                  label: Text(
                    !doctor.available
                        ? 'Restore'
                        : doctor.approved
                            ? 'Unapprove'
                            : 'Approve',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(DoctorModel doctor) async {
    try {
      final approved = await AppData.instance.toggleDoctorApproval(doctor.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                approved ? 'Doctor approved.' : 'Doctor returned to pending.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update doctor approval.')),
      );
    }
  }

  Future<void> _restore(DoctorModel doctor) async {
    await AppData.instance.restoreDoctor(doctor.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor restored to pending requests.')),
    );
  }

  Future<void> _confirmRemove(DoctorModel doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Doctor'),
        content: Text('Remove ${doctor.name} from DocMate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppData.instance.removeDoctor(doctor.id);
  }
}
