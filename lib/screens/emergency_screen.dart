import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../data/app_data.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Position? currentPosition;
  bool isLoadingLocation = false;
  bool isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        currentPosition = position;
      });
    } catch (_) {
      if (!mounted) return;
      showMessage(
          'Location is unavailable. Hospitals are shown without distance.');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> callNumber(String number) async {
    final phoneUri = Uri(scheme: 'tel', path: number);
    final opened = await launchUrl(phoneUri);
    if (!opened && mounted) {
      showMessage('Could not open the phone application.');
    }
  }

  Future<void> sendEmergencyRequest() async {
    if (isSendingRequest) return;
    setState(() {
      isSendingRequest = true;
    });

    try {
      await AppData.instance.sendEmergencyRequest();
      if (!mounted) return;
      showMessage('Emergency request recorded successfully.');
    } catch (_) {
      if (!mounted) return;
      showMessage('Emergency request could not be sent. Please call directly.');
    } finally {
      if (mounted) {
        setState(() {
          isSendingRequest = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? distanceTo(HospitalModel hospital) {
    if (currentPosition == null ||
        hospital.latitude == 0 ||
        hospital.longitude == 0) {
      return null;
    }

    return Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          hospital.latitude,
          hospital.longitude,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Support'),
        actions: [
          IconButton(
            onPressed: isLoadingLocation ? null : loadLocation,
            tooltip: 'Refresh location',
            icon: isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final hospitals = List<HospitalModel>.from(appData.hospitals);
          hospitals.sort((first, second) {
            final firstDistance = distanceTo(first) ?? double.infinity;
            final secondDistance = distanceTo(second) ?? double.infinity;
            return firstDistance.compareTo(secondDistance);
          });

          return ListView(
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
                      'Use this feature only when immediate help is required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
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
                          callNumber('999');
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('One-Tap Emergency Call'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        onPressed:
                            isSendingRequest ? null : sendEmergencyRequest,
                        icon: isSendingRequest
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          isSendingRequest
                              ? 'Sending Request...'
                              : 'Send Emergency Request',
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
              if (hospitals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'No hospitals have been added by the administrator yet. Emergency calling remains available.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...hospitals.map(buildHospitalCard),
              const SizedBox(height: 18),
              const Text(
                'Emergency information must be verified for the country where the app is used. Queue and location estimates may not be exact.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildHospitalCard(HospitalModel hospital) {
    final distance = distanceTo(hospital);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.lightMint,
            child: Icon(
              Icons.local_hospital,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (hospital.address.isNotEmpty)
                  Text(
                    hospital.address,
                    style: const TextStyle(color: Colors.black54),
                  ),
                Text(
                  distance == null
                      ? (hospital.isOpen24Hours
                          ? 'Open 24 hours'
                          : 'Distance unavailable')
                      : '${distance.toStringAsFixed(1)} km away',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {
              callNumber(hospital.phone);
            },
            icon: const Icon(Icons.call),
          ),
        ],
      ),
    );
  }
}
