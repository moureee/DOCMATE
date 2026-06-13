import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  static const Color mainColor = Color(0xFF00DDB3);
  static const Color redColor = Color(0xFFE53935);
  static const Color lightRed = Color(0xFFFFEBEE);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoadingHealth = true;
  bool isSavingContact = false;
  Map<String, dynamic> healthData = {};
  List<Map<String, dynamic>> emergencyContacts = [];

  final List<Map<String, dynamic>> fixedContacts = [
    {"name": "Police", "number": "999", "icon": Icons.local_police, "color": Color(0xFF1565C0)},
    {"name": "Fire Service", "number": "199", "icon": Icons.local_fire_department, "color": Color(0xFFE53935)},
    {"name": "Ambulance", "number": "10655", "icon": Icons.emergency, "color": Color(0xFFE53935)},
    {"name": "Health Helpline", "number": "16789", "icon": Icons.health_and_safety, "color": Color(0xFF2E7D32)},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => isLoadingHealth = false); return; }
    try {
      final healthDoc = await FirebaseFirestore.instance.collection('health_cards').doc(user.uid).get();
      if (healthDoc.exists) healthData = healthDoc.data() ?? {};
      final contactsDoc = await FirebaseFirestore.instance.collection('emergency_contacts').doc(user.uid).get();
      if (contactsDoc.exists) {
        final data = contactsDoc.data() ?? {};
        emergencyContacts = List<Map<String, dynamic>>.from(data['contacts'] ?? []);
      }
    } catch (e) { debugPrint("Load error: $e"); }
    setState(() => isLoadingHealth = false);
  }

  Future<Position?> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showMessage("Location permission denied");
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showMessage("Location permission permanently denied. Enable from Settings.");
      return null;
    }
    showMessage("Getting your location...");
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> shareLocationViaGoogleMaps() async {
    final position = await _getLocation();
    if (position == null) return;
    final uri = Uri.parse("https://www.google.com/maps?q=${position.latitude},${position.longitude}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showMessage("Could not open Google Maps");
    }
  }

  Future<void> shareLocationViaWhatsApp() async {
    final position = await _getLocation();
    if (position == null) return;
    final message = Uri.encodeComponent(
      "🚨 Emergency! My current location:\nhttps://www.google.com/maps?q=${position.latitude},${position.longitude}",
    );
    final uri = Uri.parse("https://wa.me/?text=$message");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showMessage("Could not open WhatsApp");
    }
  }

  Future<void> makeCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else showMessage("Could not make call to $number");
  }

  Future<void> sendSMS(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    else showMessage("Could not send SMS to $number");
  }

  Future<void> saveContact() async {
    if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
      showMessage("Please enter name and phone number"); return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isSavingContact = true);
    final newContact = {"name": nameController.text.trim(), "number": phoneController.text.trim()};
    emergencyContacts.add(newContact);
    try {
      await FirebaseFirestore.instance.collection('emergency_contacts').doc(user.uid).set({'contacts': emergencyContacts});
      nameController.clear(); phoneController.clear();
      showMessage("Contact saved!");
    } catch (e) {
      emergencyContacts.removeLast();
      showMessage("Could not save contact");
    }
    setState(() => isSavingContact = false);
  }

  Future<void> deleteContact(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    emergencyContacts.removeAt(index);
    try {
      await FirebaseFirestore.instance.collection('emergency_contacts').doc(user.uid).set({'contacts': emergencyContacts});
      setState(() {});
      showMessage("Contact removed");
    } catch (e) { showMessage("Could not remove contact"); }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get firstEmergencyNumber {
    if (emergencyContacts.isNotEmpty) return emergencyContacts[0]['number'] ?? '999';
    return '999';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: redColor,
        title: const Text("Emergency Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoadingHealth
          ? const Center(child: CircularProgressIndicator(color: mainColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSOSButton(),
                  const SizedBox(height: 22),
                  buildHealthSummary(),
                  const SizedBox(height: 22),
                  buildSectionTitle("Emergency Numbers (Bangladesh)"),
                  const SizedBox(height: 12),
                  buildFixedContacts(),
                  const SizedBox(height: 22),
                  buildSectionTitle("My Emergency Contacts"),
                  const SizedBox(height: 12),
                  buildPersonalContacts(),
                  const SizedBox(height: 14),
                  buildAddContactForm(),
                  const SizedBox(height: 22),
                  buildLocationCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget buildSOSButton() {
    return GestureDetector(
      onTap: () => makeCall(firstEmergencyNumber),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: redColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: redColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            const Icon(Icons.sos, color: Colors.white, size: 64),
            const SizedBox(height: 10),
            const Text("SOS — TAP TO CALL", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
              emergencyContacts.isNotEmpty
                  ? "Calls: ${emergencyContacts[0]['name']} (${emergencyContacts[0]['number']})"
                  : "Calls: 999 (Police)",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHealthSummary() {
    if (healthData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
        child: const Row(
          children: [
            Icon(Icons.health_and_safety, color: mainColor, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text("No Health Card found. Please fill your Health Card first.", style: TextStyle(color: Colors.black54, fontSize: 13))),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: mainColor.withValues(alpha: 0.5), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.health_and_safety, color: mainColor, size: 24), SizedBox(width: 8), Text("Health Card Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: buildHealthItem("Blood Group", healthData['bloodGroup'] ?? 'N/A', Icons.bloodtype)),
            const SizedBox(width: 10),
            Expanded(child: buildHealthItem("BMI", healthData['bmi'] ?? 'N/A', Icons.monitor_weight)),
            const SizedBox(width: 10),
            Expanded(child: buildHealthItem("Age", healthData['age'] ?? 'N/A', Icons.cake)),
          ]),
          if ((healthData['allergies'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: lightRed, borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber, color: redColor, size: 20), const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Allergies", style: TextStyle(fontWeight: FontWeight.bold, color: redColor, fontSize: 13)),
                  Text(healthData['allergies'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ])),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildHealthItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFE8FFF8), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: mainColor, size: 22), const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }

  Widget buildFixedContacts() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
      children: fixedContacts.map((contact) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(contact['icon'], color: contact['color'], size: 22), const SizedBox(width: 6),
              Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => makeCall(contact['number']),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: contact['color'], borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.call, color: Colors.white, size: 14), const SizedBox(width: 4),
                  Text(contact['number'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget buildPersonalContacts() {
    if (emergencyContacts.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
        child: const Text("No personal contacts added yet.", style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
      );
    }
    return Column(
      children: emergencyContacts.asMap().entries.map((entry) {
        final index = entry.key; final contact = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
          child: Row(children: [
            const CircleAvatar(backgroundColor: Color(0xFFE8FFF8), child: Icon(Icons.person, color: mainColor)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(contact['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(contact['number'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ])),
            IconButton(onPressed: () => makeCall(contact['number']), icon: const Icon(Icons.call, color: Colors.green)),
            IconButton(onPressed: () => sendSMS(contact['number']), icon: const Icon(Icons.sms, color: mainColor)),
            IconButton(onPressed: () => deleteContact(index), icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ]),
        );
      }).toList(),
    );
  }

  Widget buildAddContactForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Add Emergency Contact", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Name", hintText: "e.g. Mom, Dad",
            prefixIcon: const Icon(Icons.person_outline, color: mainColor),
            filled: true, fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: mainColor, width: 2)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: phoneController, keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Phone Number", hintText: "e.g. 01XXXXXXXXX",
            prefixIcon: const Icon(Icons.phone, color: mainColor),
            filled: true, fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: mainColor, width: 2)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: isSavingContact ? null : saveContact,
            icon: const Icon(Icons.add),
            label: Text(isSavingContact ? "Saving..." : "Add Contact"),
            style: ElevatedButton.styleFrom(backgroundColor: mainColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }

  // ✅ নতুন Location Card — Google Maps + WhatsApp দুটো button
  Widget buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.location_on, color: mainColor, size: 22),
            SizedBox(width: 8),
            Text("Share My Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          const Text("Share your live GPS location instantly", style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: shareLocationViaGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF4285F4), borderRadius: BorderRadius.circular(12)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.map, color: Colors.white, size: 18), SizedBox(width: 6),
                    Text("Google Maps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: shareLocationViaWhatsApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(12)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat, color: Colors.white, size: 18), SizedBox(width: 6),
                    Text("WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}