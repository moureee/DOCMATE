import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

DateTime _readDate(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

double _readDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

String _dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year$month$day';
}

String _safeKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

DateTime _combineDateAndTime(DateTime date, String timeText) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(timeText.trim());

  if (match == null) {
    return DateTime(date.year, date.month, date.day, 9);
  }

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!.toUpperCase();

  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  return DateTime(date.year, date.month, date.day, hour, minute);
}

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
    this.averageConsultationMinutes = 12,
    this.phone = '',
    this.hospitalName = '',
    this.qualification = '',
    this.bio = '',
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
  int averageConsultationMinutes;
  String phone;
  String hospitalName;
  String qualification;
  String bio;

  factory DoctorModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return DoctorModel(
      id: document.id,
      name: (data['name'] ?? 'Unnamed Doctor').toString(),
      specialty:
          (data['specialty'] ?? data['designation'] ?? 'Not set').toString(),
      rating: _readDouble(data['ratingAverage'] ?? data['rating'], 0),
      experience: _readInt(data['experienceYears'] ?? data['experience']),
      reviews: _readInt(data['ratingCount'] ?? data['reviews']),
      availableSlots: _readStringList(data['availableSlots']),
      queueLength: _readInt(data['queueLength']),
      approved: data['approved'] == true,
      available: data['available'] != false,
      averageConsultationMinutes:
          _readInt(data['averageConsultationMinutes'], 12),
      phone: (data['phone'] ?? '').toString(),
      hospitalName: (data['hospitalName'] ?? '').toString(),
      qualification: (data['qualification'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
    );
  }

  void updateFromFirestore(Map<String, dynamic> data) {
    name = (data['name'] ?? name).toString();
    specialty =
        (data['specialty'] ?? data['designation'] ?? specialty).toString();
    rating = _readDouble(data['ratingAverage'] ?? data['rating'], rating);
    experience = _readInt(
      data['experienceYears'] ?? data['experience'],
      experience,
    );
    reviews = _readInt(data['ratingCount'] ?? data['reviews'], reviews);
    availableSlots = _readStringList(data['availableSlots']);
    averageConsultationMinutes =
        _readInt(data['averageConsultationMinutes'], 12);
    approved = data['approved'] == true;
    available = data['available'] != false;
    phone = (data['phone'] ?? phone).toString();
    hospitalName = (data['hospitalName'] ?? hospitalName).toString();
    qualification = (data['qualification'] ?? qualification).toString();
    bio = (data['bio'] ?? bio).toString();
  }
}

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
    this.patientId = '',
    this.slotId = '',
    this.queueNumber = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String slotId;
  final int queueNumber;
  final DateTime createdAt;
  DateTime date;
  String time;
  String symptoms;
  String notes;
  String status;

  factory AppointmentModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return AppointmentModel(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      patientName: (data['patientName'] ?? 'Patient').toString(),
      doctorId: (data['doctorId'] ?? '').toString(),
      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
      specialty: (data['specialty'] ?? 'Not set').toString(),
      date: _readDate(
        data['appointmentDate'] ?? data['scheduledAt'] ?? data['date'],
        fallback: DateTime.now(),
      ),
      time: (data['time'] ?? '').toString(),
      symptoms: (data['symptoms'] ?? '').toString(),
      notes: (data['notes'] ?? data['preVisitNotes'] ?? '').toString(),
      status: (data['status'] ?? 'Pending').toString(),
      slotId: (data['slotId'] ?? '').toString(),
      queueNumber: _readInt(data['queueNumber']),
      createdAt: _readDate(data['createdAt'], fallback: DateTime.now()),
    );
  }
}

class MedicineModel {
  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.taken = false,
    this.patientId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String patientId;
  final DateTime createdAt;
  String name;
  String dosage;
  String time;
  bool taken;

  factory MedicineModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return MedicineModel(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      name: (data['name'] ?? 'Medicine').toString(),
      dosage: (data['dosage'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
      taken: data['taken'] == true,
      createdAt: _readDate(data['createdAt'], fallback: DateTime.now()),
    );
  }
}

class PrescriptionModel {
  PrescriptionModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.medicines,
    required this.notes,
    required this.date,
    this.patientId = '',
    this.doctorId = '',
    this.appointmentId = '',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final List<String> medicines;
  final String notes;
  final DateTime date;

  factory PrescriptionModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return PrescriptionModel(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      doctorId: (data['doctorId'] ?? '').toString(),
      appointmentId: (data['appointmentId'] ?? '').toString(),
      patientName: (data['patientName'] ?? 'Patient').toString(),
      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
      medicines: _readStringList(data['medicines']),
      notes: (data['notes'] ?? data['doctorNotes'] ?? '').toString(),
      date: _readDate(data['createdAt'] ?? data['date'],
          fallback: DateTime.now()),
    );
  }
}

class HealthProfileModel {
  HealthProfileModel({
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.allergies,
    required this.lastVisit,
    this.conditions = const <String>[],
    this.emergencyContact = '',
  });

  double heightCm;
  double weightKg;
  String bloodGroup;
  List<String> allergies;
  DateTime lastVisit;
  List<String> conditions;
  String emergencyContact;

  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    if (bmi == 0) return 'Not available';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'High BMI';
  }

  factory HealthProfileModel.fromMap(Map<String, dynamic> data) {
    return HealthProfileModel(
      heightCm: _readDouble(data['heightCm'] ?? data['height']),
      weightKg: _readDouble(data['weightKg'] ?? data['weight']),
      bloodGroup: (data['bloodGroup'] ?? '').toString(),
      allergies: _readStringList(data['allergies']),
      lastVisit: _readDate(data['lastVisit'], fallback: DateTime.now()),
      conditions: _readStringList(data['conditions']),
      emergencyContact: (data['emergencyContact'] ?? '').toString(),
    );
  }
}

class ChatMessageModel {
  ChatMessageModel({
    required this.message,
    required this.isPatient,
    required this.time,
    this.id = '',
    this.senderId = '',
    this.receiverId = '',
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isPatient;
  final DateTime time;

  factory ChatMessageModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String currentUserId,
    String currentUserRole,
  ) {
    final data = document.data();
    final senderId = (data['senderId'] ?? '').toString();
    final senderRole = (data['senderRole'] ?? '').toString();
    return ChatMessageModel(
      id: document.id,
      senderId: senderId,
      receiverId: (data['receiverId'] ?? '').toString(),
      message: (data['text'] ?? data['message'] ?? '').toString(),
      isPatient: senderRole == 'patient' ||
          (senderRole.isEmpty &&
              ((currentUserRole == 'patient' && senderId == currentUserId) ||
                  (currentUserRole == 'doctor' && senderId != currentUserId))),
      time: _readDate(data['sentAt'], fallback: DateTime.now()),
    );
  }
}

class TimelineItem {
  TimelineItem({
    required this.title,
    required this.details,
    required this.date,
    this.id = '',
    this.patientId = '',
  });

  final String id;
  final String patientId;
  final String title;
  final String details;
  final DateTime date;

  factory TimelineItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return TimelineItem(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      title: (data['title'] ?? data['type'] ?? 'Health Event').toString(),
      details: (data['details'] ?? '').toString(),
      date: _readDate(data['createdAt'], fallback: DateTime.now()),
    );
  }
}

class NotificationModel {
  NotificationModel({
    required this.title,
    required this.message,
    required this.date,
    this.read = false,
    this.id = '',
    this.userId = '',
    this.isAnnouncement = false,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime date;
  final bool isAnnouncement;
  bool read;

  factory NotificationModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    bool isAnnouncement = false,
  }) {
    final data = document.data();
    return NotificationModel(
      id: document.id,
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ??
              (isAnnouncement ? 'Admin Announcement' : 'Notification'))
          .toString(),
      message: (data['message'] ?? '').toString(),
      date: _readDate(data['createdAt'], fallback: DateTime.now()),
      read: data['read'] == true,
      isAnnouncement: isAnnouncement,
    );
  }
}

class HospitalModel {
  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.isOpen24Hours,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpen24Hours;

  factory HospitalModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return HospitalModel(
      id: document.id,
      name: (data['name'] ?? 'Hospital').toString(),
      address: (data['address'] ?? '').toString(),
      phone: (data['phone'] ?? '999').toString(),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      isOpen24Hours: data['isOpen24Hours'] == true,
    );
  }
}

class AppData extends ChangeNotifier {
  AppData._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          _handleAuthenticationChanged,
        );
  }

  static final AppData instance = AppData._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  String currentUserId = '';
  String currentUserRole = '';
  String currentPatientName = 'Patient';
  String currentDoctorName = 'Doctor';
  String currentUserEmail = '';
  bool isLoadingDoctors = true;
  String? doctorLoadError;
  String? lastActionError;

  final List<DoctorModel> doctors = <DoctorModel>[];
  final List<AppointmentModel> appointments = <AppointmentModel>[];
  final List<MedicineModel> medicines = <MedicineModel>[];
  final List<PrescriptionModel> prescriptions = <PrescriptionModel>[];
  final List<String> patients = <String>[];
  final List<ChatMessageModel> chatMessages = <ChatMessageModel>[];
  final List<TimelineItem> timeline = <TimelineItem>[];
  final List<NotificationModel> notifications = <NotificationModel>[];
  final List<HospitalModel> hospitals = <HospitalModel>[];

  final Set<String> _favoriteDoctorIds = <String>{};
  final Map<String, String> _patientIdByName = <String, String>{};
  final Map<String, HealthProfileModel> _profilesByPatientId =
      <String, HealthProfileModel>{};
  final Set<String> _listeningPatientProfileIds = <String>{};
  final Map<String, List<double>> _reviewRatingsByDoctor =
      <String, List<double>>{};
  final List<NotificationModel> _directNotifications = <NotificationModel>[];
  final List<NotificationModel> _announcements = <NotificationModel>[];

  HealthProfileModel healthProfile = HealthProfileModel(
    heightCm: 0,
    weightKg: 0,
    bloodGroup: '',
    allergies: <String>[],
    lastVisit: DateTime.now(),
  );

  String activeChatPartnerId = '';
  String activeChatPartnerName = 'Healthcare Contact';
  String activeChatPartnerSubtitle = '';
  int emergencyRequestCount = 0;
  int totalUserCount = 0;

  DoctorModel? get currentDoctor {
    for (final doctor in doctors) {
      if (doctor.id == currentUserId) return doctor;
    }
    return null;
  }

  String get currentDisplayName {
    if (currentUserRole == 'doctor') return currentDoctorName;
    if (currentUserRole == 'patient') return currentPatientName;
    return 'Admin';
  }

  Future<void> _handleAuthenticationChanged(User? user) async {
    await _cancelDataSubscriptions();
    _clearDynamicData();

    if (user == null) {
      currentUserId = '';
      currentUserRole = '';
      currentPatientName = 'Patient';
      currentDoctorName = 'Doctor';
      currentUserEmail = '';
      isLoadingDoctors = false;
      notifyListeners();
      return;
    }

    currentUserId = user.uid;
    currentUserRole = '';
    currentPatientName = 'Patient';
    currentDoctorName = 'Doctor';
    currentUserEmail = user.email ?? '';
    isLoadingDoctors = true;
    notifyListeners();

    final userSubscription =
        _firestore.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return;

        final role = (data['role'] ?? '').toString();
        final name = (data['name'] ?? user.displayName ?? '').toString().trim();
        final roleChanged = currentUserRole != role;

        currentUserRole = role;
        if (role == 'doctor') {
          currentDoctorName = name.isEmpty ? 'Doctor' : name;
        } else if (role == 'patient') {
          currentPatientName = name.isEmpty ? 'Patient' : name;
        }

        if (roleChanged) {
          unawaited(_startRoleListeners());
        }
        notifyListeners();
      },
      onError: (Object error) {
        lastActionError = 'Unable to load the signed-in user profile.';
        notifyListeners();
      },
    );
    _subscriptions.add(userSubscription);

    _startDoctorListener();
    _startHospitalListener();
    _startReviewListener();
  }

  Future<void> _cancelDataSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _clearDynamicData() {
    doctors.clear();
    appointments.clear();
    medicines.clear();
    prescriptions.clear();
    patients.clear();
    chatMessages.clear();
    timeline.clear();
    notifications.clear();
    hospitals.clear();
    _favoriteDoctorIds.clear();
    _patientIdByName.clear();
    _profilesByPatientId.clear();
    _listeningPatientProfileIds.clear();
    _reviewRatingsByDoctor.clear();
    _directNotifications.clear();
    _announcements.clear();
    activeChatPartnerId = '';
    activeChatPartnerName = 'Healthcare Contact';
    activeChatPartnerSubtitle = '';
    emergencyRequestCount = 0;
    totalUserCount = 0;
    healthProfile = HealthProfileModel(
      heightCm: 0,
      weightKg: 0,
      bloodGroup: '',
      allergies: <String>[],
      lastVisit: DateTime.now(),
    );
  }

  Future<void> _startRoleListeners() async {
    if (currentUserId.isEmpty || currentUserRole.isEmpty) return;

    _startAppointmentsListener();
    _startPrescriptionsListener();
    _startNotificationsListener();

    if (currentUserRole == 'patient') {
      _startFavoritesListener();
      _startHealthProfileListener();
      _startMedicinesListener();
      _startTimelineListener();
    }

    if (currentUserRole == 'admin') {
      _startAdminUsersListener();
      _startEmergencyCountListener();
    }
  }

  void _startDoctorListener() {
    final subscription = _firestore.collection('doctors').snapshots().listen(
      (snapshot) {
        final existing = <String, DoctorModel>{
          for (final doctor in doctors) doctor.id: doctor,
        };
        final updated = <DoctorModel>[];

        for (final document in snapshot.docs) {
          final current = existing[document.id];
          if (current == null) {
            final doctor = DoctorModel.fromFirestore(document);
            doctor.isFavorite = _favoriteDoctorIds.contains(doctor.id);
            updated.add(doctor);
          } else {
            current.updateFromFirestore(document.data());
            current.isFavorite = _favoriteDoctorIds.contains(current.id);
            updated.add(current);
          }
        }

        updated.sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );
        doctors
          ..clear()
          ..addAll(updated);
        _applyReviewAggregates();
        _recalculateDoctorQueues();
        isLoadingDoctors = false;
        doctorLoadError = null;
        _chooseChatPartner();
        notifyListeners();
      },
      onError: (Object error) {
        isLoadingDoctors = false;
        doctorLoadError = 'Unable to load doctors. Please try again.';
        notifyListeners();
      },
    );
    _subscriptions.add(subscription);
  }

  void _startReviewListener() {
    final subscription = _firestore.collection('reviews').snapshots().listen(
      (snapshot) {
        _reviewRatingsByDoctor.clear();
        for (final document in snapshot.docs) {
          final data = document.data();
          final doctorId = (data['doctorId'] ?? '').toString();
          final rating = _readDouble(data['rating']);
          if (doctorId.isEmpty || rating <= 0) continue;
          _reviewRatingsByDoctor
              .putIfAbsent(doctorId, () => <double>[])
              .add(rating);
        }
        _applyReviewAggregates();
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  void _applyReviewAggregates() {
    for (final doctor in doctors) {
      final ratings = _reviewRatingsByDoctor[doctor.id];
      if (ratings == null || ratings.isEmpty) continue;
      final total =
          ratings.fold<double>(0, (runningTotal, item) => runningTotal + item);
      doctor.rating = total / ratings.length;
      doctor.reviews = ratings.length;
    }
  }

  void _startHospitalListener() {
    final subscription = _firestore.collection('hospitals').snapshots().listen(
      (snapshot) {
        hospitals
          ..clear()
          ..addAll(snapshot.docs.map(HospitalModel.fromFirestore));
        hospitals.sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  void _startAppointmentsListener() {
    Query<Map<String, dynamic>> query = _firestore.collection('appointments');
    if (currentUserRole == 'patient') {
      query = query.where('patientId', isEqualTo: currentUserId);
    } else if (currentUserRole == 'doctor') {
      query = query.where('doctorId', isEqualTo: currentUserId);
    }

    final subscription = query.snapshots().listen(
      (snapshot) {
        appointments
          ..clear()
          ..addAll(snapshot.docs.map(AppointmentModel.fromFirestore));
        appointments.sort((first, second) {
          final firstTime = _combineDateAndTime(first.date, first.time);
          final secondTime = _combineDateAndTime(second.date, second.time);
          return firstTime.compareTo(secondTime);
        });
        _rebuildPatientNames();
        _recalculateDoctorQueues();
        _chooseChatPartner();
        notifyListeners();
      },
      onError: (Object error) {
        lastActionError = 'Unable to load appointments.';
        notifyListeners();
      },
    );
    _subscriptions.add(subscription);
  }

  void _startPrescriptionsListener() {
    Query<Map<String, dynamic>> query = _firestore.collection('prescriptions');
    if (currentUserRole == 'patient') {
      query = query.where('patientId', isEqualTo: currentUserId);
    } else if (currentUserRole == 'doctor') {
      query = query.where('doctorId', isEqualTo: currentUserId);
    }

    final subscription = query.snapshots().listen(
      (snapshot) {
        prescriptions
          ..clear()
          ..addAll(snapshot.docs.map(PrescriptionModel.fromFirestore));
        prescriptions.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  void _startFavoritesListener() {
    final subscription = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      _favoriteDoctorIds
        ..clear()
        ..addAll(snapshot.docs.map((document) => document.id));
      for (final doctor in doctors) {
        doctor.isFavorite = _favoriteDoctorIds.contains(doctor.id);
      }
      notifyListeners();
    });
    _subscriptions.add(subscription);
  }

  void _startHealthProfileListener() {
    final subscription = _firestore
        .collection('health_profiles')
        .doc(currentUserId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      healthProfile = HealthProfileModel.fromMap(data);
      _profilesByPatientId[currentUserId] = healthProfile;
      notifyListeners();
    });
    _subscriptions.add(subscription);
  }

  void _startMedicinesListener() {
    final subscription = _firestore
        .collection('medicines')
        .where('patientId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      medicines
        ..clear()
        ..addAll(snapshot.docs.map(MedicineModel.fromFirestore));
      medicines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });
    _subscriptions.add(subscription);
  }

  void _startTimelineListener() {
    final subscription = _firestore
        .collection('timeline_events')
        .where('patientId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      timeline
        ..clear()
        ..addAll(snapshot.docs.map(TimelineItem.fromFirestore));
      timeline.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    });
    _subscriptions.add(subscription);
  }

  void _startNotificationsListener() {
    final notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      _directNotifications
        ..clear()
        ..addAll(snapshot.docs.map(NotificationModel.fromFirestore));
      _mergeNotifications();
    });
    _subscriptions.add(notificationSubscription);

    final announcementSubscription =
        _firestore.collection('announcements').snapshots().listen((snapshot) {
      _announcements
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (document) => NotificationModel.fromFirestore(
              document,
              isAnnouncement: true,
            ),
          ),
        );
      _mergeNotifications();
    });
    _subscriptions.add(announcementSubscription);
  }

  void _mergeNotifications() {
    notifications
      ..clear()
      ..addAll(_directNotifications)
      ..addAll(_announcements);
    notifications.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _startAdminUsersListener() {
    final subscription = _firestore.collection('users').snapshots().listen(
      (snapshot) {
        totalUserCount = snapshot.docs.length;
        _patientIdByName.clear();
        final patientNames = <String>[];
        for (final document in snapshot.docs) {
          final data = document.data();
          if ((data['role'] ?? '').toString() != 'patient') continue;
          final name = (data['name'] ?? 'Patient').toString();
          _patientIdByName[name] = document.id;
          patientNames.add(name);
        }
        patientNames.sort();
        patients
          ..clear()
          ..addAll(patientNames);
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  void _startEmergencyCountListener() {
    final subscription =
        _firestore.collection('emergency_requests').snapshots().listen(
      (snapshot) {
        emergencyRequestCount = snapshot.docs.length;
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  void _rebuildPatientNames() {
    if (currentUserRole == 'admin') return;
    _patientIdByName.clear();
    final names = <String>[];
    for (final appointment in appointments) {
      final name = appointment.patientName.trim();
      if (name.isEmpty || appointment.patientId.isEmpty) continue;
      _patientIdByName[name] = appointment.patientId;
      if (!names.contains(name)) names.add(name);
    }
    names.sort();
    patients
      ..clear()
      ..addAll(names);

    if (currentUserRole == 'doctor') {
      for (final patientId in _patientIdByName.values) {
        _startAssignedPatientProfileListener(patientId);
      }
    }
  }

  void _startAssignedPatientProfileListener(String patientId) {
    if (patientId.isEmpty || _listeningPatientProfileIds.contains(patientId)) {
      return;
    }
    _listeningPatientProfileIds.add(patientId);
    final subscription = _firestore
        .collection('health_profiles')
        .doc(patientId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      _profilesByPatientId[patientId] = HealthProfileModel.fromMap(data);
      notifyListeners();
    }, onError: (_) {});
    _subscriptions.add(subscription);
  }

  void _recalculateDoctorQueues() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    for (final doctor in doctors) {
      doctor.queueLength = appointments.where((appointment) {
        if (appointment.doctorId != doctor.id) return false;
        if (_dateKey(appointment.date) != todayKey) return false;
        return appointment.status == 'Pending' ||
            appointment.status == 'Accepted' ||
            appointment.status == 'In Consultation';
      }).length;
    }
  }

  void _chooseChatPartner() {
    String partnerId = '';
    String partnerName = 'Healthcare Contact';
    String subtitle = '';

    if (currentUserRole == 'patient') {
      final eligible = appointments.where((appointment) {
        return appointment.doctorId.isNotEmpty &&
            appointment.status != 'Cancelled' &&
            appointment.status != 'Rejected';
      }).toList();
      if (eligible.isNotEmpty) {
        eligible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final appointment = eligible.first;
        partnerId = appointment.doctorId;
        partnerName = appointment.doctorName;
        subtitle = appointment.specialty;
      } else if (approvedDoctors.isNotEmpty) {
        final doctor = approvedDoctors.first;
        partnerId = doctor.id;
        partnerName = doctor.name;
        subtitle = doctor.specialty;
      }
    } else if (currentUserRole == 'doctor') {
      final eligible = appointments.where((appointment) {
        return appointment.patientId.isNotEmpty &&
            appointment.status != 'Cancelled' &&
            appointment.status != 'Rejected';
      }).toList();
      if (eligible.isNotEmpty) {
        eligible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        partnerId = eligible.first.patientId;
        partnerName = eligible.first.patientName;
        subtitle = 'Patient';
      }
    }

    if (partnerId == activeChatPartnerId) {
      activeChatPartnerName = partnerName;
      activeChatPartnerSubtitle = subtitle;
      return;
    }

    activeChatPartnerId = partnerId;
    activeChatPartnerName = partnerName;
    activeChatPartnerSubtitle = subtitle;
    chatMessages.clear();

    if (partnerId.isNotEmpty) {
      _startChatListener(partnerId);
    }
  }

  void _startChatListener(String partnerId) {
    final conversationId = _conversationId(currentUserId, partnerId);
    final subscription = _firestore
        .collection('messages')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      final conversationDocuments = snapshot.docs.where((document) {
        return (document.data()['conversationId'] ?? '').toString() ==
            conversationId;
      });
      chatMessages
        ..clear()
        ..addAll(
          conversationDocuments.map(
            (document) => ChatMessageModel.fromFirestore(
              document,
              currentUserId,
              currentUserRole,
            ),
          ),
        );
      chatMessages.sort((a, b) => a.time.compareTo(b.time));
      notifyListeners();
    });
    _subscriptions.add(subscription);
  }

  String _conversationId(String firstId, String secondId) {
    final ids = <String>[firstId, secondId]..sort();
    return ids.join('_');
  }

  Future<void> refreshDoctors() async {
    isLoadingDoctors = true;
    doctorLoadError = null;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('doctors').get();
      final updated = snapshot.docs.map(DoctorModel.fromFirestore).toList();
      for (final doctor in updated) {
        doctor.isFavorite = _favoriteDoctorIds.contains(doctor.id);
      }
      updated.sort((a, b) => a.name.compareTo(b.name));
      doctors
        ..clear()
        ..addAll(updated);
      _applyReviewAggregates();
      _recalculateDoctorQueues();
      isLoadingDoctors = false;
      notifyListeners();
    } catch (_) {
      isLoadingDoctors = false;
      doctorLoadError = 'Unable to refresh doctors. Please try again.';
      notifyListeners();
    }
  }

  List<DoctorModel> get approvedDoctors {
    return doctors.where((doctor) {
      return doctor.approved && doctor.available;
    }).toList();
  }

  double doctorScore(DoctorModel doctor) {
    final ratingScore = doctor.rating * 20;
    final availabilityScore = doctor.availableSlots.length * 2;
    final queuePenalty = doctor.queueLength * 1.5;
    return ratingScore + availabilityScore - queuePenalty;
  }

  List<DoctorModel> get rankedDoctors {
    final result = List<DoctorModel>.from(approvedDoctors);
    result.sort(
      (first, second) => doctorScore(second).compareTo(doctorScore(first)),
    );
    return result;
  }

  int predictedQueueMinutes(DoctorModel doctor) {
    final consultationTime = doctor.averageConsultationMinutes <= 0
        ? 12
        : doctor.averageConsultationMinutes;
    if (doctor.queueLength == 0) return 0;
    return doctor.queueLength * consultationTime;
  }

  String suggestDepartment(List<String> selectedSymptoms) {
    if (selectedSymptoms.isEmpty) return 'Please select symptoms';
    final symptoms =
        selectedSymptoms.map((item) => item.toLowerCase()).toList();

    if (symptoms.any(
      (item) => item.contains('chest') || item.contains('heartbeat'),
    )) {
      return 'Cardiology';
    }
    if (symptoms.any(
      (item) =>
          item.contains('skin') ||
          item.contains('rash') ||
          item.contains('itch'),
    )) {
      return 'Dermatology';
    }
    if (symptoms.any(
      (item) =>
          item.contains('joint') ||
          item.contains('bone') ||
          item.contains('back'),
    )) {
      return 'Orthopedics';
    }
    if (symptoms.any(
      (item) =>
          item.contains('stomach') ||
          item.contains('vomit') ||
          item.contains('digestion'),
    )) {
      return 'Gastroenterology';
    }
    if (symptoms.any(
      (item) => item.contains('eye') || item.contains('vision'),
    )) {
      return 'Ophthalmology';
    }
    return 'General Medicine';
  }

  String healthSuggestion(List<String> selectedSymptoms) {
    final symptoms =
        selectedSymptoms.map((item) => item.toLowerCase()).toList();
    if (symptoms.any(
      (item) => item.contains('chest pain') || item.contains('breathing'),
    )) {
      return 'Urgent attention may be required. Contact emergency support or a qualified doctor.';
    }
    if (healthProfile.bmi >= 30) {
      return 'Your BMI is high. Discuss a safe health plan with a qualified healthcare professional.';
    }
    if (healthProfile.bmi > 0 && healthProfile.bmi < 18.5) {
      return 'Your BMI is below the healthy range. Consider discussing nutrition with a healthcare professional.';
    }
    return 'This is educational decision support, not a diagnosis. Continue healthy habits and consult a doctor when needed.';
  }

  Future<void> toggleFavorite(String doctorId) async {
    if (currentUserId.isEmpty || currentUserRole != 'patient') return;
    final reference = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(doctorId);
    final isFavorite = _favoriteDoctorIds.contains(doctorId);

    try {
      if (isFavorite) {
        await reference.delete();
      } else {
        await reference.set({
          'doctorId': doctorId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      lastActionError = 'Favorite could not be updated.';
      notifyListeners();
    }
  }

  Future<void> bookAppointment({
    required DoctorModel doctor,
    required DateTime date,
    required String time,
    required String symptoms,
    required String notes,
  }) async {
    if (currentUserId.isEmpty || currentUserRole != 'patient') {
      throw StateError('Only a signed-in patient can book an appointment.');
    }

    final appointmentReference = _firestore.collection('appointments').doc();
    final slotId = '${doctor.id}_${_dateKey(date)}_${_safeKey(time)}';
    final slotReference =
        _firestore.collection('appointment_slots').doc(slotId);
    final timelineReference = _firestore.collection('timeline_events').doc();
    final notificationReference = _firestore.collection('notifications').doc();
    final profileReference =
        _firestore.collection('health_profiles').doc(currentUserId);
    final scheduledAt = _combineDateAndTime(date, time);

    await _firestore.runTransaction((transaction) async {
      final slotSnapshot = await transaction.get(slotReference);
      if (slotSnapshot.exists && slotSnapshot.data()?['booked'] == true) {
        throw StateError('That time slot has already been booked.');
      }

      transaction.set(slotReference, {
        'doctorId': doctor.id,
        'dateKey': _dateKey(date),
        'time': time,
        'booked': true,
        'appointmentId': appointmentReference.id,
        'patientId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(appointmentReference, {
        'patientId': currentUserId,
        'patientName': currentPatientName,
        'doctorId': doctor.id,
        'doctorName': doctor.name,
        'specialty': doctor.specialty,
        'appointmentDate': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day),
        ),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'time': time,
        'symptoms': symptoms,
        'preVisitNotes': notes,
        'notes': notes,
        'status': 'Pending',
        'slotId': slotId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        profileReference,
        {
          'uid': currentUserId,
          'doctorIds': FieldValue.arrayUnion(<String>[doctor.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(timelineReference, {
        'patientId': currentUserId,
        'type': 'appointment_booked',
        'title': 'Appointment Booked',
        'details': 'Appointment booked with ${doctor.name} at $time.',
        'appointmentId': appointmentReference.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(notificationReference, {
        'userId': currentUserId,
        'title': 'Booking Successful',
        'message': 'Your appointment with ${doctor.name} was booked.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final appointmentReference =
        _firestore.collection('appointments').doc(appointmentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(appointmentReference);
      if (!snapshot.exists) throw StateError('Appointment not found.');
      final data = snapshot.data()!;
      final slotId = (data['slotId'] ?? '').toString();
      transaction.update(appointmentReference, {
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (slotId.isNotEmpty) {
        transaction.set(
          _firestore.collection('appointment_slots').doc(slotId),
          {
            'booked': false,
            'appointmentId': '',
            'patientId': '',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    await _createNotification(
      userId: currentUserId,
      title: 'Appointment Cancelled',
      message: 'Your appointment was cancelled.',
    );
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime date,
    required String time,
  }) async {
    final appointmentReference =
        _firestore.collection('appointments').doc(appointmentId);

    await _firestore.runTransaction((transaction) async {
      final appointmentSnapshot = await transaction.get(appointmentReference);
      if (!appointmentSnapshot.exists) {
        throw StateError('Appointment not found.');
      }
      final appointmentData = appointmentSnapshot.data()!;
      final doctorId = (appointmentData['doctorId'] ?? '').toString();
      final oldSlotId = (appointmentData['slotId'] ?? '').toString();
      final newSlotId = '${doctorId}_${_dateKey(date)}_${_safeKey(time)}';
      final newSlotReference =
          _firestore.collection('appointment_slots').doc(newSlotId);
      final newSlotSnapshot = await transaction.get(newSlotReference);

      if (newSlotSnapshot.exists && newSlotSnapshot.data()?['booked'] == true) {
        throw StateError('That time slot has already been booked.');
      }

      if (oldSlotId.isNotEmpty && oldSlotId != newSlotId) {
        transaction.set(
          _firestore.collection('appointment_slots').doc(oldSlotId),
          {
            'booked': false,
            'appointmentId': '',
            'patientId': '',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(newSlotReference, {
        'doctorId': doctorId,
        'dateKey': _dateKey(date),
        'time': time,
        'booked': true,
        'appointmentId': appointmentId,
        'patientId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(appointmentReference, {
        'appointmentDate': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day),
        ),
        'scheduledAt': Timestamp.fromDate(_combineDateAndTime(date, time)),
        'time': time,
        'slotId': newSlotId,
        'status': 'Pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _createNotification(
      userId: currentUserId,
      title: 'Appointment Rescheduled',
      message: 'Your appointment was moved to ${formatDate(date)} at $time.',
    );
  }

  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    final reference = _firestore.collection('appointments').doc(appointmentId);
    final snapshot = await reference.get();
    if (!snapshot.exists) throw StateError('Appointment not found.');
    final data = snapshot.data()!;
    final patientId = (data['patientId'] ?? '').toString();
    final doctorName = (data['doctorName'] ?? currentDoctorName).toString();
    final slotId = (data['slotId'] ?? '').toString();

    final batch = _firestore.batch();
    batch.update(reference, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'Completed') 'completedAt': FieldValue.serverTimestamp(),
    });

    if ((status == 'Rejected' || status == 'Cancelled') && slotId.isNotEmpty) {
      batch.set(
        _firestore.collection('appointment_slots').doc(slotId),
        {
          'booked': false,
          'appointmentId': '',
          'patientId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (patientId.isNotEmpty) {
      batch.set(_firestore.collection('notifications').doc(), {
        'userId': patientId,
        'title': 'Appointment $status',
        'message': 'Your appointment with $doctorName is now $status.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (status == 'Completed') {
        batch.set(_firestore.collection('timeline_events').doc(), {
          'patientId': patientId,
          'type': 'appointment_completed',
          'title': 'Appointment Completed',
          'details': 'Consultation completed with $doctorName.',
          'appointmentId': appointmentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> addMedicine({
    required String name,
    required String dosage,
    required String time,
  }) async {
    if (currentUserId.isEmpty) return;
    await _firestore.collection('medicines').add({
      'patientId': currentUserId,
      'name': name.trim(),
      'dosage': dosage.trim(),
      'time': time.trim(),
      'taken': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: currentUserId,
      title: 'Medicine Added',
      message: '$name reminder was added.',
    );
  }

  Future<void> toggleMedicineTaken(String medicineId) async {
    final reference = _firestore.collection('medicines').doc(medicineId);
    final snapshot = await reference.get();
    if (!snapshot.exists) return;
    final currentValue = snapshot.data()?['taken'] == true;
    await reference.update({
      'taken': !currentValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHealthProfile({
    required double heightCm,
    required double weightKg,
    required String bloodGroup,
    required List<String> allergies,
  }) async {
    if (currentUserId.isEmpty) return;
    await _firestore.collection('health_profiles').doc(currentUserId).set({
      'uid': currentUserId,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'height': heightCm,
      'weight': weightKg,
      'bloodGroup': bloodGroup.trim(),
      'allergies': allergies,
      'bmi':
          heightCm > 0 ? weightKg / ((heightCm / 100) * (heightCm / 100)) : 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendChatMessage(String message) async {
    final text = message.trim();
    if (text.isEmpty || activeChatPartnerId.isEmpty || currentUserId.isEmpty) {
      return;
    }
    await _firestore.collection('messages').add({
      'conversationId': _conversationId(currentUserId, activeChatPartnerId),
      'participants': <String>[currentUserId, activeChatPartnerId],
      'senderId': currentUserId,
      'receiverId': activeChatPartnerId,
      'senderRole': currentUserRole,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> sendCallRequest() async {
    if (activeChatPartnerId.isEmpty || currentUserId.isEmpty) return;
    await _firestore.collection('call_requests').add({
      'requesterId': currentUserId,
      'receiverId': activeChatPartnerId,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: activeChatPartnerId,
      title: 'Call Request',
      message: '$currentDisplayName requested a call.',
    );
  }

  Future<void> addPrescription({
    required String patientName,
    required String doctorName,
    required List<String> medicines,
    required String notes,
  }) async {
    final patientId = _patientIdByName[patientName] ?? '';
    if (patientId.isEmpty) {
      throw StateError('Select a patient who has an appointment with you.');
    }
    final reference = _firestore.collection('prescriptions').doc();
    final batch = _firestore.batch();
    batch.set(reference, {
      'patientId': patientId,
      'doctorId': currentUserId,
      'patientName': patientName,
      'doctorName': doctorName,
      'medicines': medicines,
      'doctorNotes': notes,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('timeline_events').doc(), {
      'patientId': patientId,
      'type': 'prescription_added',
      'title': 'New Prescription',
      'details': 'A prescription was added by $doctorName.',
      'prescriptionId': reference.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('notifications').doc(), {
      'userId': patientId,
      'title': 'New Prescription',
      'message': '$doctorName added a prescription for you.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> addReview({
    required AppointmentModel appointment,
    required int rating,
    required String comment,
  }) async {
    if (currentUserRole != 'patient' || currentUserId.isEmpty) {
      throw StateError('Only patients can submit reviews.');
    }
    if (appointment.status != 'Completed') {
      throw StateError('A review can be added after a completed appointment.');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('Rating must be between 1 and 5.');
    }

    await _firestore.collection('reviews').doc(appointment.id).set({
      'appointmentId': appointment.id,
      'patientId': currentUserId,
      'patientName': currentPatientName,
      'doctorId': appointment.doctorId,
      'doctorName': appointment.doctorName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addAvailability(String doctorId, String time) async {
    final normalizedTime = time.trim();
    if (normalizedTime.isEmpty) return;
    await _firestore.collection('doctors').doc(doctorId).update({
      'availableSlots': FieldValue.arrayUnion(<String>[normalizedTime]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAvailability(String doctorId, String time) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'availableSlots': FieldValue.arrayRemove(<String>[time]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> toggleDoctorApproval(String doctorId) async {
    final doctor = doctors.firstWhere((item) => item.id == doctorId);
    final newValue = !doctor.approved;
    final batch = _firestore.batch();
    batch.update(_firestore.collection('doctors').doc(doctorId), {
      'approved': newValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('users').doc(doctorId), {
      'approved': newValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return newValue;
  }

  Future<void> removeDoctor(String doctorId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('doctors').doc(doctorId));
    batch.update(_firestore.collection('users').doc(doctorId), {
      'isActive': false,
      'approved': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> sendAnnouncement(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    await _firestore.collection('announcements').add({
      'title': 'Admin Announcement',
      'message': text,
      'createdBy': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEmergencyRequest() async {
    if (currentUserId.isEmpty) return;
    double? latitude;
    double? longitude;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {
      // Request is still saved without a location.
    }

    await _firestore.collection('emergency_requests').add({
      'userId': currentUserId,
      'userName': currentDisplayName,
      'role': currentUserRole,
      'status': 'Open',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: currentUserId,
      title: 'Emergency Request Sent',
      message: 'Your emergency request was recorded.',
    );
  }

  Future<void> markNotificationRead(NotificationModel notification) async {
    final previousValue = notification.read;
    notification.read = true;
    notifyListeners();
    if (notification.id.isEmpty || notification.isAnnouncement) return;

    try {
      await _firestore.collection('notifications').doc(notification.id).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      notification.read = previousValue;
      notifyListeners();
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    if (userId.isEmpty) return;
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  HealthProfileModel? healthProfileForPatient(String patientName) {
    final patientId = _patientIdByName[patientName];
    if (patientId == null) return null;
    return _profilesByPatientId[patientId];
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
