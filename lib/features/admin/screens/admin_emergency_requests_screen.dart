import 'package:flutter/material.dart';

import 'package:docmate/core/theme/app_theme.dart';
import 'package:docmate/data/app_data.dart';

class AdminEmergencyRequestsScreen extends StatelessWidget {
  const AdminEmergencyRequestsScreen({super.key});

  Future<void> updateStatus(
    BuildContext context,
    EmergencyRequestModel request,
    String status,
  ) async {
    try {
      await AppData.instance.updateEmergencyRequestStatus(
        requestId: request.id,
        status: status,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency request marked $status.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency request could not be updated.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Requests')),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final requests = appData.emergencyRequests;
          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No emergency requests have been recorded.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _EmergencyRequestCard(
                request: request,
                onStatusSelected: (status) {
                  updateStatus(context, request, status);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmergencyRequestCard extends StatelessWidget {
  const _EmergencyRequestCard({
    required this.request,
    required this.onStatusSelected,
  });

  final EmergencyRequestModel request;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final isOpen = request.status.toLowerCase() == 'open';
    final location = request.latitude == null || request.longitude == null
        ? 'Location unavailable'
        : '${request.latitude!.toStringAsFixed(5)}, '
            '${request.longitude!.toStringAsFixed(5)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? AppColors.danger : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isOpen ? const Color(0xFFFFECEB) : AppColors.lightMint,
                child: Icon(
                  Icons.emergency,
                  color: isOpen ? AppColors.danger : AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      request.role.isEmpty ? 'User' : request.role,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      isOpen ? const Color(0xFFFFECEB) : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    color: isOpen ? AppColors.danger : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Text('Created: ${formatDate(request.createdAt)}'),
          const SizedBox(height: 6),
          Text('Location: $location'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: request.status == 'In Progress'
                      ? null
                      : () => onStatusSelected('In Progress'),
                  icon: const Icon(Icons.pending_actions),
                  label: const Text('In Progress'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: request.status == 'Resolved'
                      ? null
                      : () => onStatusSelected('Resolved'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Resolve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
