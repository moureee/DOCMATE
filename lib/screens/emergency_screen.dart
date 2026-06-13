import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> callNumber(
    BuildContext context,
    String number,
  ) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: number,
    );

    final bool opened = await launchUrl(phoneUri);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the phone application.',
          ),
        ),
      );
    }
  }

  void sendEmergencyRequest(BuildContext context) {
    AppData.instance.sendEmergencyRequest();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency request recorded successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hospitals = [
      {
        'name': 'City General Hospital',
        'distance': '1.2 km away',
        'phone': '999',
      },
      {
        'name': 'Central Medical Centre',
        'distance': '2.5 km away',
        'phone': '999',
      },
      {
        'name': 'Community Emergency Clinic',
        'distance': '3.1 km away',
        'phone': '999',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 56,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Emergency Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Use this feature only when immediate help '
                  'is required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () {
                      callNumber(context, '999');
                    },
                    icon: const Icon(Icons.call),
                    label: const Text(
                      'One-Tap Emergency Call',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nearby Hospitals',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...hospitals.map((hospital) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightMint,
                  child: Icon(
                    Icons.local_hospital,
                    color: AppColors.primaryDark,
                  ),
                ),
                title: Text(
                  hospital['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  hospital['distance']!,
                ),
                trailing: IconButton(
                  onPressed: () {
                    callNumber(
                      context,
                      hospital['phone']!,
                    );
                  },
                  icon: const Icon(
                    Icons.call,
                    color: AppColors.danger,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                sendEmergencyRequest(context);
              },
              icon: const Icon(Icons.sos),
              label: const Text(
                'Send Emergency Request',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Note: The hospitals and numbers shown here are '
            'demonstration data. Replace them with verified local '
            'emergency information before real use.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
