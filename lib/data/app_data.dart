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
  bool isFavorite;
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
  AppData._();

  static final AppData instance = AppData._();

  final String currentPatientName = 'Demo Patient';
  final String currentDoctorName = 'Dr. Sarah Ahmed';

  // ==================== DOCTORS ====================

  final List<DoctorModel> doctors = [
    DoctorModel(
      id: 'doctor_1',
      name: 'Dr. Sarah Ahmed',
      specialty: 'General Medicine',
      rating: 4.8,
      reviews: 120,
      experience: 8,
      availableSlots: [
        '09:00 AM',
        '10:00 AM',
        '11:30 AM',
        '03:00 PM',
      ],
      queueLength: 3,
    ),
    DoctorModel(
      id: 'doctor_2',
      name: 'Dr. Rakib Hasan',
      specialty: 'Cardiology',
      rating: 4.7,
      reviews: 90,
      experience: 10,
      availableSlots: [
        '10:30 AM',
        '12:00 PM',
        '04:00 PM',
      ],
      queueLength: 5,
    ),
    DoctorModel(
      id: 'doctor_3',
      name: 'Dr. Nabila Rahman',
      specialty: 'Dermatology',
      rating: 4.6,
      reviews: 75,
      experience: 6,
      availableSlots: [
        '09:30 AM',
        '01:30 PM',
        '05:00 PM',
      ],
      queueLength: 2,
    ),
    DoctorModel(
      id: 'doctor_4',
      name: 'Dr. Farhan Kabir',
      specialty: 'Orthopedics',
      rating: 4.5,
      reviews: 65,
      experience: 7,
      availableSlots: [
        '11:00 AM',
        '02:00 PM',
      ],
      queueLength: 4,
      approved: false,
    ),
  ];

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
      return doctor.approved;
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

  void addAvailability(
    String doctorId,
    String time,
  ) {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    if (!doctor.availableSlots.contains(time)) {
      doctor.availableSlots.add(time);
    }

    notifyListeners();
  }

  void removeAvailability(
    String doctorId,
    String time,
  ) {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    doctor.availableSlots.remove(time);

    notifyListeners();
  }

  // ==================== ADMIN DOCTOR MANAGEMENT ====================

  void toggleDoctorApproval(String doctorId) {
    final doctor = doctors.firstWhere((doctor) {
      return doctor.id == doctorId;
    });

    doctor.approved = !doctor.approved;

    notifyListeners();
  }

  void removeDoctor(String doctorId) {
    doctors.removeWhere((doctor) {
      return doctor.id == doctorId;
    });

    notifyListeners();
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
}
