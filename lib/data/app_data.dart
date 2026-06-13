import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

// ==================== DOCTOR MODEL ====================

class DoctorModel {
  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experience,
    required this.availableSlots,
    required this.queueLength,
    this.reviews = 0,
    this.approved = true,
    this.available = true,
    this.isFavorite = false,
  });

  final String id;

  String name;
  String specialty;
  double rating;
  int experience;
  int reviews;
  List<String> availableSlots;
  int queueLength;
  bool approved;
  bool available;
  bool isFavorite;

  static double _readDouble(dynamic value, [double fallback = 0]) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _readInt(dynamic value, [int fallback = 0]) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory DoctorModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return DoctorModel(
      id: document.id,
      name: (data['name'] ?? 'Unnamed Doctor').toString(),
      specialty:
          (data['specialty'] ?? data['designation'] ?? 'Not set').toString(),
      rating: _readDouble(data['rating'], 0),
      experience: _readInt(
        data['experienceYears'] ?? data['experience'],
      ),
      reviews: _readInt(data['reviews'] ?? data['ratingCount']),
      availableSlots: _readStringList(data['availableSlots']),
      queueLength: _readInt(data['queueLength']),
      approved: data['approved'] == true,
      available: data['available'] != false,
    );
  }

  void updateFromFirestore(Map<String, dynamic> data) {
    name = (data['name'] ?? name).toString();
    specialty =
        (data['specialty'] ?? data['designation'] ?? specialty).toString();
    rating = _readDouble(data['rating'], rating);
    experience = _readInt(
      data['experienceYears'] ?? data['experience'],
      experience,
    );
    reviews = _readInt(
      data['reviews'] ?? data['ratingCount'],
      reviews,
    );
    availableSlots = _readStringList(data['availableSlots']);
    queueLength = _readInt(data['queueLength'], queueLength);
    approved = data['approved'] == true;
    available = data['available'] != false;
  }
}

// ==================== APPOINTMENT MODEL ====================

class AppointmentModel {
  AppointmentModel({
    required this.id,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.symptoms,
    required this.notes,
    this.status = 'Pending',
  });

  final String id;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;

  DateTime date;
  String time;
  String symptoms;
  String notes;
  String status;
}

// ==================== MEDICINE MODEL ====================

class MedicineModel {
  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.taken = false,
  });

  final String id;

  String name;
  String dosage;
  String time;
  bool taken;
}

// ==================== PRESCRIPTION MODEL ====================

class PrescriptionModel {
  PrescriptionModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.medicines,
    required this.notes,
    required this.date,
  });

  final String id;
  final String patientName;
  final String doctorName;
  final List<String> medicines;
  final String notes;
  final DateTime date;
}

// ==================== HEALTH PROFILE MODEL ====================

class HealthProfileModel {
  HealthProfileModel({
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.allergies,
    required this.lastVisit,
  });

  double heightCm;
  double weightKg;
  String bloodGroup;
  List<String> allergies;
  DateTime lastVisit;

  double get bmi {
    if (heightCm <= 0) {
      return 0;
    }

    final heightInMeters = heightCm / 100;

    return weightKg / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    if (bmi == 0) {
      return 'Not available';
    }

    if (bmi < 18.5) {
      return 'Underweight';
    }

    if (bmi < 25) {
      return 'Healthy';
    }

    if (bmi < 30) {
      return 'Overweight';
    }

    return 'High BMI';
  }
}

// ==================== CHAT MODEL ====================

class ChatMessageModel {
  ChatMessageModel({
    required this.message,
    required this.isPatient,
    required this.time,
  });

  final String message;
  final bool isPatient;
  final DateTime time;
}

// ==================== TIMELINE MODEL ====================

class TimelineItem {
  TimelineItem({
    required this.title,
    required this.details,
    required this.date,
  });

  final String title;
  final String details;
  final DateTime date;
}

// ==================== NOTIFICATION MODEL ====================

class NotificationModel {
  NotificationModel({
    required this.title,
    required this.message,
    required this.date,
    this.read = false,
  });

  final String title;
  final String message;
  final DateTime date;

  bool read;
}

// ==================== MAIN APP DATA ====================

class AppData extends ChangeNotifier {
  AppData._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          _handleAuthenticationChanged,
        );
  }

  static final AppData instance = AppData._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _currentUserSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _doctorSubscription;

  final Set<String> _favoriteDoctorIds = <String>{};

  String currentUserId = '';
  String currentUserRole = '';
  String currentPatientName = 'Patient';
  String currentDoctorName = 'Doctor';
  bool isLoadingDoctors = true;
  String? doctorLoadError;

  // ==================== DOCTORS ====================

  final List<DoctorModel> doctors = <DoctorModel>[];

  DoctorModel? get currentDoctor {
    if (currentUserId.isEmpty) {
      return null;
    }

    for (final doctor in doctors) {
      if (doctor.id == currentUserId) {
        return doctor;
      }
    }

    return null;
  }

  Future<void> _handleAuthenticationChanged(User? user) async {
    await _currentUserSubscription?.cancel();
    await _doctorSubscription?.cancel();
    _currentUserSubscription = null;
    _doctorSubscription = null;

    if (user == null) {
      currentUserId = '';
      currentUserRole = '';
      currentPatientName = 'Patient';
      currentDoctorName = 'Doctor';
      doctors.clear();
      isLoadingDoctors = false;
      doctorLoadError = null;
      notifyListeners();
      return;
    }

    currentUserId = user.uid;

    _currentUserSubscription =
        _firestore.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final name = (data['name'] ?? user.displayName ?? '').toString().trim();
        currentUserRole = (data['role'] ?? '').toString();

        if (currentUserRole == 'doctor') {
          currentDoctorName = name.isEmpty ? 'Doctor' : name;
        } else if (currentUserRole == 'patient') {
          currentPatientName = name.isEmpty ? 'Patient' : name;
        }

        notifyListeners();
      },
      onError: (_) {
        currentUserRole = '';
        notifyListeners();
      },
    );

    _startDoctorListener();
  }

  void _startDoctorListener() {
    if (_doctorSubscription != null) {
      return;
    }

    isLoadingDoctors = true;
    doctorLoadError = null;
    notifyListeners();

    _doctorSubscription = _firestore.collection('doctors').snapshots().listen(
      _applyDoctorSnapshot,
      onError: (Object error) {
        isLoadingDoctors = false;
        doctorLoadError = 'Unable to load doctors. Please try again.';
        notifyListeners();
      },
    );
  }

  void _applyDoctorSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final existingDoctors = <String, DoctorModel>{
      for (final doctor in doctors) doctor.id: doctor,
    };

    final updatedDoctors = <DoctorModel>[];

    for (final document in snapshot.docs) {
      final existingDoctor = existingDoctors[document.id];

      if (existingDoctor == null) {
        final doctor = DoctorModel.fromFirestore(document);
        doctor.isFavorite = _favoriteDoctorIds.contains(doctor.id);
        updatedDoctors.add(doctor);
      } else {
        existingDoctor.updateFromFirestore(document.data());
        existingDoctor.isFavorite =
            _favoriteDoctorIds.contains(existingDoctor.id);
        updatedDoctors.add(existingDoctor);
      }
    }

    updatedDoctors.sort((first, second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    doctors
      ..clear()
      ..addAll(updatedDoctors);

    isLoadingDoctors = false;
    doctorLoadError = null;
    notifyListeners();
  }

  Future<void> refreshDoctors() async {
    isLoadingDoctors = true;
    doctorLoadError = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('doctors').get();
      _applyDoctorSnapshot(snapshot);
    } catch (_) {
      isLoadingDoctors = false;
      doctorLoadError = 'Unable to refresh doctors. Please try again.';
      notifyListeners();
    }
  }

  // ==================== APPOINTMENTS ====================

  final List<AppointmentModel> appointments = [
    AppointmentModel(
      id: 'appointment_1',
      patientName: 'Demo Patient',
      doctorId: 'doctor_1',
      doctorName: 'Dr. Sarah Ahmed',
      specialty: 'General Medicine',
      date: DateTime.now().add(
        const Duration(days: 1),
      ),
      time: '10:00 AM',
      symptoms: 'Fever and headache',
      notes: 'Fever for two days',
      status: 'Accepted',
    ),
    AppointmentModel(
      id: 'appointment_2',
      patientName: 'Ayesha Khan',
      doctorId: 'doctor_1',
      doctorName: 'Dr. Sarah Ahmed',
      specialty: 'General Medicine',
      date: DateTime.now().add(
        const Duration(days: 2),
      ),
      time: '11:30 AM',
      symptoms: 'Cough and weakness',
      notes: 'Dry cough',
    ),
  ];

  // ==================== MEDICINES ====================

  final List<MedicineModel> medicines = [
    MedicineModel(
      id: 'medicine_1',
      name: 'Paracetamol',
      dosage: '500 mg',
      time: 'After dinner',
    ),
    MedicineModel(
      id: 'medicine_2',
      name: 'Vitamin D',
      dosage: '1 tablet',
      time: 'After breakfast',
    ),
  ];

  // ==================== PRESCRIPTIONS ====================

  final List<PrescriptionModel> prescriptions = [
    PrescriptionModel(
      id: 'prescription_1',
      patientName: 'Demo Patient',
      doctorName: 'Dr. Sarah Ahmed',
      medicines: [
        'Paracetamol 500 mg',
        'Vitamin D',
      ],
      notes: 'Take rest and drink enough water.',
      date: DateTime.now().subtract(
        const Duration(days: 10),
      ),
    ),
  ];

  // ==================== HEALTH PROFILE ====================

  HealthProfileModel healthProfile = HealthProfileModel(
    heightCm: 165,
    weightKg: 62,
    bloodGroup: 'B+',
    allergies: [
      'Dust',
      'Pollen',
    ],
    lastVisit: DateTime.now().subtract(
      const Duration(days: 10),
    ),
  );

  // ==================== PATIENTS ====================

  final List<String> patients = [
    'Demo Patient',
    'Ayesha Khan',
    'Rahim Ahmed',
    'Nusrat Jahan',
  ];

  // ==================== CHAT ====================

  final List<ChatMessageModel> chatMessages = [
    ChatMessageModel(
      message: 'Hello doctor, I have had a fever since yesterday.',
      isPatient: true,
      time: DateTime.now().subtract(
        const Duration(minutes: 15),
      ),
    ),
    ChatMessageModel(
      message: 'Please drink water and monitor your temperature.',
      isPatient: false,
      time: DateTime.now().subtract(
        const Duration(minutes: 12),
      ),
    ),
  ];

  // ==================== HEALTH TIMELINE ====================

  final List<TimelineItem> timeline = [
    TimelineItem(
      title: 'Doctor Visit',
      details: 'Visited Dr. Sarah Ahmed for fever and headache.',
      date: DateTime.now().subtract(
        const Duration(days: 10),
      ),
    ),
    TimelineItem(
      title: 'Prescription Added',
      details: 'Paracetamol and Vitamin D were prescribed.',
      date: DateTime.now().subtract(
        const Duration(days: 10),
      ),
    ),
    TimelineItem(
      title: 'Follow-up Reminder',
      details: 'Follow-up recommended after two weeks.',
      date: DateTime.now().subtract(
        const Duration(days: 3),
      ),
    ),
  ];

  // ==================== NOTIFICATIONS ====================

  final List<NotificationModel> notifications = [
    NotificationModel(
      title: 'Appointment Reminder',
      message: 'Your appointment is tomorrow at 10:00 AM.',
      date: DateTime.now(),
    ),
    NotificationModel(
      title: 'Medicine Reminder',
      message: 'Remember to take Paracetamol after dinner.',
      date: DateTime.now(),
    ),
  ];

  // ==================== DOCTOR FILTERING ====================

  List<DoctorModel> get approvedDoctors {
    return doctors.where((doctor) {
      return doctor.approved && doctor.available;
    }).toList();
  }

  double doctorScore(DoctorModel doctor) {
    return (doctor.rating * 20) +
        (doctor.availableSlots.length * 2) -
        (doctor.queueLength * 1.5);
  }

  List<DoctorModel> get rankedDoctors {
    final result = List<DoctorModel>.from(
      approvedDoctors,
    );

    result.sort((firstDoctor, secondDoctor) {
      return doctorScore(secondDoctor).compareTo(
        doctorScore(firstDoctor),
      );
    });

    return result;
  }

  // ==================== QUEUE PREDICTION ====================

  int predictedQueueMinutes(DoctorModel doctor) {
    const averageConsultationTime = 12;
    const delayBuffer = 5;

    return (doctor.queueLength * averageConsultationTime) + delayBuffer;
  }

  // ==================== SYMPTOM CHECKER ====================

  String suggestDepartment(
    List<String> selectedSymptoms,
  ) {
    if (selectedSymptoms.isEmpty) {
      return 'Please select symptoms';
    }

    final symptoms = selectedSymptoms.map((symptom) {
      return symptom.toLowerCase();
    }).toList();

    if (symptoms.any((symptom) {
      return symptom.contains('chest') || symptom.contains('heartbeat');
    })) {
      return 'Cardiology';
    }

    if (symptoms.any((symptom) {
      return symptom.contains('skin') ||
          symptom.contains('rash') ||
          symptom.contains('itch');
    })) {
      return 'Dermatology';
    }

    if (symptoms.any((symptom) {
      return symptom.contains('joint') ||
          symptom.contains('bone') ||
          symptom.contains('back');
    })) {
      return 'Orthopedics';
    }

    if (symptoms.any((symptom) {
      return symptom.contains('stomach') ||
          symptom.contains('vomit') ||
          symptom.contains('digestion');
    })) {
      return 'Gastroenterology';
    }

    return 'General Medicine';
  }

  String healthSuggestion(
    List<String> selectedSymptoms,
  ) {
    final symptoms = selectedSymptoms.map((symptom) {
      return symptom.toLowerCase();
    }).toList();

    if (symptoms.any((symptom) {
      return symptom.contains('chest pain') || symptom.contains('breathing');
    })) {
      return 'Urgent attention may be required. Contact emergency support or a qualified doctor.';
    }

    if (healthProfile.bmi >= 30) {
      return 'Your BMI is high. Discuss healthy food and physical activity with a healthcare professional.';
    }

    if (healthProfile.bmi < 18.5) {
      return 'Your BMI is below the healthy range. Consider discussing nutrition with a healthcare professional.';
    }

    return 'Your basic health indicators appear stable. Continue healthy habits and regular check-ups.';
  }

  // ==================== FAVORITE DOCTOR ====================

  void toggleFavorite(String doctorId) {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    doctor.isFavorite = !doctor.isFavorite;

    if (doctor.isFavorite) {
      _favoriteDoctorIds.add(doctorId);
    } else {
      _favoriteDoctorIds.remove(doctorId);
    }

    notifyListeners();
  }

  // ==================== BOOK APPOINTMENT ====================

  void bookAppointment({
    required DoctorModel doctor,
    required DateTime date,
    required String time,
    required String symptoms,
    required String notes,
  }) {
    appointments.add(
      AppointmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientName: currentPatientName,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: doctor.specialty,
        date: date,
        time: time,
        symptoms: symptoms,
        notes: notes,
      ),
    );

    timeline.insert(
      0,
      TimelineItem(
        title: 'Appointment Booked',
        details: 'Appointment booked with ${doctor.name} at $time.',
        date: DateTime.now(),
      ),
    );

    notifications.insert(
      0,
      NotificationModel(
        title: 'Booking Successful',
        message: 'Your appointment with ${doctor.name} was booked.',
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== CANCEL APPOINTMENT ====================

  void cancelAppointment(String appointmentId) {
    final appointment = appointments.firstWhere((appointment) {
      return appointment.id == appointmentId;
    });

    appointment.status = 'Cancelled';

    notifyListeners();
  }

  // ==================== RESCHEDULE APPOINTMENT ====================

  void rescheduleAppointment({
    required String appointmentId,
    required DateTime date,
    required String time,
  }) {
    final appointment = appointments.firstWhere((appointment) {
      return appointment.id == appointmentId;
    });

    appointment.date = date;
    appointment.time = time;
    appointment.status = 'Pending';

    notifications.insert(
      0,
      NotificationModel(
        title: 'Appointment Rescheduled',
        message: 'Your appointment was moved to ${formatDate(date)} at $time.',
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== DOCTOR APPOINTMENT STATUS ====================

  void updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) {
    final appointment = appointments.firstWhere((appointment) {
      return appointment.id == appointmentId;
    });

    appointment.status = status;

    if (status == 'Completed') {
      timeline.insert(
        0,
        TimelineItem(
          title: 'Appointment Completed',
          details: 'Consultation completed with ${appointment.doctorName}.',
          date: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  // ==================== MEDICINE FUNCTIONS ====================

  void addMedicine({
    required String name,
    required String dosage,
    required String time,
  }) {
    medicines.add(
      MedicineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        dosage: dosage,
        time: time,
      ),
    );

    notifications.insert(
      0,
      NotificationModel(
        title: 'Medicine Added',
        message: '$name reminder was added.',
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void toggleMedicineTaken(String medicineId) {
    final medicine = medicines.firstWhere((medicine) {
      return medicine.id == medicineId;
    });

    medicine.taken = !medicine.taken;

    notifyListeners();
  }

  // ==================== HEALTH PROFILE ====================

  void updateHealthProfile({
    required double heightCm,
    required double weightKg,
    required String bloodGroup,
    required List<String> allergies,
  }) {
    healthProfile.heightCm = heightCm;
    healthProfile.weightKg = weightKg;
    healthProfile.bloodGroup = bloodGroup;
    healthProfile.allergies = allergies;

    notifyListeners();
  }

  // ==================== CHAT ====================

  void sendChatMessage(String message) {
    if (message.trim().isEmpty) {
      return;
    }

    chatMessages.add(
      ChatMessageModel(
        message: message.trim(),
        isPatient: true,
        time: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== PRESCRIPTION ====================

  void addPrescription({
    required String patientName,
    required String doctorName,
    required List<String> medicines,
    required String notes,
  }) {
    prescriptions.insert(
      0,
      PrescriptionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientName: patientName,
        doctorName: doctorName,
        medicines: medicines,
        notes: notes,
        date: DateTime.now(),
      ),
    );

    timeline.insert(
      0,
      TimelineItem(
        title: 'New Prescription',
        details: 'A prescription was added by $doctorName.',
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== DOCTOR AVAILABILITY ====================

  Future<void> addAvailability(
    String doctorId,
    String time,
  ) async {
    final normalizedTime = time.trim();

    if (normalizedTime.isEmpty) {
      return;
    }

    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    if (doctor.availableSlots.contains(normalizedTime)) {
      return;
    }

    doctor.availableSlots.add(normalizedTime);
    doctor.availableSlots.sort();
    notifyListeners();

    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'availableSlots': FieldValue.arrayUnion(<String>[normalizedTime]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      doctor.availableSlots.remove(normalizedTime);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeAvailability(
    String doctorId,
    String time,
  ) async {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    final hadSlot = doctor.availableSlots.remove(time);

    if (!hadSlot) {
      return;
    }

    notifyListeners();

    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'availableSlots': FieldValue.arrayRemove(<String>[time]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      doctor.availableSlots.add(time);
      doctor.availableSlots.sort();
      notifyListeners();
      rethrow;
    }
  }

  // ==================== ADMIN DOCTOR MANAGEMENT ====================

  Future<bool> toggleDoctorApproval(String doctorId) async {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    final previousValue = doctor.approved;
    final newValue = !previousValue;

    doctor.approved = newValue;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final doctorReference = _firestore.collection('doctors').doc(doctorId);
      final userReference = _firestore.collection('users').doc(doctorId);

      batch.update(doctorReference, {
        'approved': newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(userReference, {
        'approved': newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return newValue;
    } catch (_) {
      doctor.approved = previousValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeDoctor(String doctorId) async {
    final doctorIndex = doctors.indexWhere((doctor) {
      return doctor.id == doctorId;
    });

    if (doctorIndex == -1) {
      return;
    }

    final removedDoctor = doctors.removeAt(doctorIndex);
    notifyListeners();

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('doctors').doc(doctorId));
      batch.delete(_firestore.collection('users').doc(doctorId));
      await batch.commit();
    } catch (_) {
      doctors.insert(doctorIndex, removedDoctor);
      notifyListeners();
      rethrow;
    }
  }

  // ==================== ADMIN ANNOUNCEMENT ====================

  void sendAnnouncement(String message) {
    if (message.trim().isEmpty) {
      return;
    }

    notifications.insert(
      0,
      NotificationModel(
        title: 'Admin Announcement',
        message: message.trim(),
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== EMERGENCY REQUEST ====================

  void sendEmergencyRequest() {
    notifications.insert(
      0,
      NotificationModel(
        title: 'Emergency Request Sent',
        message: 'Your demo emergency request was recorded.',
        date: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  // ==================== READ NOTIFICATION ====================

  void markNotificationRead(
    NotificationModel notification,
  ) {
    notification.read = true;

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _currentUserSubscription?.cancel();
    _doctorSubscription?.cancel();
    super.dispose();
  }
}
