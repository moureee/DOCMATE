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

String availabilitySlotValue(DateTime date, String time) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day|${time.trim()}';
}

DateTime? availabilitySlotDate(String value) {
  final separatorIndex = value.indexOf('|');
  if (separatorIndex <= 0) return null;
  return DateTime.tryParse(value.substring(0, separatorIndex));
}

String availabilitySlotTime(String value) {
  final separatorIndex = value.indexOf('|');
  if (separatorIndex < 0 || separatorIndex == value.length - 1) {
    return value.trim();
  }
  return value.substring(separatorIndex + 1).trim();
}

String availabilitySlotLabel(String value) {
  final date = availabilitySlotDate(value);
  final time = availabilitySlotTime(value);
  if (date == null) return 'Every day • $time';
  return '${formatDate(date)} • $time';
}

List<String> availabilityTimesForDate(
  DoctorModel doctor,
  DateTime date,
) {
  final requestedKey = _dateKey(date);
  final exception = doctor.scheduleExceptions[requestedKey];

  if (exception?.unavailable == true) {
    return <String>[];
  }

  final times = <String>{};

  if (exception != null && exception.customTimes.isNotEmpty) {
    times.addAll(exception.customTimes);
  } else {
    final weeklyRule = doctor.weeklySchedule[date.weekday];
    if (weeklyRule != null) {
      times.addAll(_generateTimesForRule(date, weeklyRule));
    }

    times.addAll(
      doctor.availableSlots
          .where((slot) {
            final slotDate = availabilitySlotDate(slot);
            return slotDate == null || _dateKey(slotDate) == requestedKey;
          })
          .map(availabilitySlotTime)
          .where((time) => time.isNotEmpty),
    );
  }

  final result = times.toList();
  result.sort((first, second) {
    final firstDate = _combineDateAndTime(date, first);
    final secondDate = _combineDateAndTime(date, second);
    return firstDate.compareTo(secondDate);
  });
  return result;
}

String _safeKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

DateTime _combineDateAndTime(DateTime date, String timeText) {
  final normalized = timeText.trim();
  final twelveHourMatch = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(normalized);

  if (twelveHourMatch != null) {
    var hour = int.parse(twelveHourMatch.group(1)!);
    final minute = int.parse(twelveHourMatch.group(2)!);
    final period = twelveHourMatch.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  final twentyFourHourMatch = RegExp(
    r'^(\d{1,2}):(\d{2})$',
  ).firstMatch(normalized);
  if (twentyFourHourMatch != null) {
    final hour = int.parse(twentyFourHourMatch.group(1)!);
    final minute = int.parse(twentyFourHourMatch.group(2)!);
    if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
  }

  return DateTime(date.year, date.month, date.day, 9);
}

class DoctorDaySchedule {
  const DoctorDaySchedule({
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.slotMinutes,
  });

  final bool enabled;
  final String startTime;
  final String endTime;
  final int slotMinutes;

  factory DoctorDaySchedule.fromMap(Map<String, dynamic> data) {
    return DoctorDaySchedule(
      enabled: data['enabled'] == true,
      startTime: (data['startTime'] ?? '09:00 AM').toString(),
      endTime: (data['endTime'] ?? '05:00 PM').toString(),
      slotMinutes: _readInt(data['slotMinutes'], 30).clamp(10, 180).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'startTime': startTime,
      'endTime': endTime,
      'slotMinutes': slotMinutes,
    };
  }
}

class ScheduleException {
  const ScheduleException({
    required this.unavailable,
    required this.customTimes,
    this.note = '',
  });

  final bool unavailable;
  final List<String> customTimes;
  final String note;

  factory ScheduleException.fromMap(Map<String, dynamic> data) {
    return ScheduleException(
      unavailable: data['unavailable'] == true,
      customTimes: _readStringList(data['customTimes']),
      note: (data['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'unavailable': unavailable,
      'customTimes': customTimes,
      'note': note,
    };
  }
}

Map<int, DoctorDaySchedule> _readWeeklySchedule(dynamic value) {
  final result = <int, DoctorDaySchedule>{};
  if (value is Map) {
    value.forEach((key, item) {
      final weekday = int.tryParse(key.toString());
      if (weekday == null || weekday < 1 || weekday > 7 || item is! Map) {
        return;
      }
      result[weekday] = DoctorDaySchedule.fromMap(
        Map<String, dynamic>.from(item),
      );
    });
  }
  return result;
}

Map<String, ScheduleException> _readScheduleExceptions(dynamic value) {
  final result = <String, ScheduleException>{};
  if (value is Map) {
    value.forEach((key, item) {
      if (item is! Map) return;
      result[key.toString()] = ScheduleException.fromMap(
        Map<String, dynamic>.from(item),
      );
    });
  }
  return result;
}

List<String> _generateTimesForRule(
  DateTime date,
  DoctorDaySchedule rule,
) {
  if (!rule.enabled) return <String>[];
  final start = _combineDateAndTime(date, rule.startTime);
  final end = _combineDateAndTime(date, rule.endTime);
  if (!end.isAfter(start)) return <String>[];

  final result = <String>[];
  var cursor = start;
  while (cursor.isBefore(end)) {
    final hour = cursor.hour;
    final minute = cursor.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    result.add(
      '${displayHour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')} $period',
    );
    cursor = cursor.add(Duration(minutes: rule.slotMinutes));
  }
  return result;
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
    Map<int, DoctorDaySchedule>? weeklySchedule,
    Map<String, ScheduleException>? scheduleExceptions,
  })  : weeklySchedule = weeklySchedule ?? <int, DoctorDaySchedule>{},
        scheduleExceptions =
            scheduleExceptions ?? <String, ScheduleException>{};

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
  Map<int, DoctorDaySchedule> weeklySchedule;
  Map<String, ScheduleException> scheduleExceptions;

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
      weeklySchedule: _readWeeklySchedule(data['weeklySchedule']),
      scheduleExceptions: _readScheduleExceptions(data['scheduleExceptions']),
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
    weeklySchedule = _readWeeklySchedule(data['weeklySchedule']);
    scheduleExceptions = _readScheduleExceptions(data['scheduleExceptions']);
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
    this.startedAt,
    this.completedAt,
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
  final DateTime? startedAt;
  final DateTime? completedAt;
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
      startedAt: data['startedAt'] == null
          ? null
          : _readDate(data['startedAt'], fallback: DateTime.now()),
      completedAt: data['completedAt'] == null
          ? null
          : _readDate(data['completedAt'], fallback: DateTime.now()),
    );
  }

  int? get consultationMinutes {
    if (startedAt == null || completedAt == null) return null;
    final minutes = completedAt!.difference(startedAt!).inMinutes;
    if (minutes <= 0 || minutes > 240) return null;
    return minutes;
  }
}

class MedicineModel {
  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.patientId = '',
    this.lastTakenDateKey = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String patientId;
  final DateTime createdAt;
  final String lastTakenDateKey;
  String name;
  String dosage;
  String time;

  bool get taken => lastTakenDateKey == _dateKey(DateTime.now());

  factory MedicineModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    var lastTakenKey = (data['lastTakenDateKey'] ?? '').toString();

    // Backward compatibility for old records that only stored `taken`.
    if (lastTakenKey.isEmpty && data['taken'] == true) {
      final updatedAt = data['lastTakenAt'] ?? data['updatedAt'];
      if (updatedAt != null) {
        final updatedDate = _readDate(updatedAt, fallback: DateTime.now());
        if (_dateKey(updatedDate) == _dateKey(DateTime.now())) {
          lastTakenKey = _dateKey(DateTime.now());
        }
      }
    }

    return MedicineModel(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      name: (data['name'] ?? 'Medicine').toString(),
      dosage: (data['dosage'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
      lastTakenDateKey: lastTakenKey,
      createdAt: _readDate(data['createdAt'], fallback: DateTime.now()),
    );
  }
}

class PrescriptionMedicineModel {
  const PrescriptionMedicineModel({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  factory PrescriptionMedicineModel.fromMap(Map<String, dynamic> data) {
    return PrescriptionMedicineModel(
      name: (data['name'] ?? 'Medicine').toString(),
      dosage: (data['dosage'] ?? '').toString(),
      frequency: (data['frequency'] ?? '').toString(),
      duration: (data['duration'] ?? '').toString(),
      instructions: (data['instructions'] ?? '').toString(),
    );
  }

  factory PrescriptionMedicineModel.fromLegacy(String value) {
    return PrescriptionMedicineModel(
      name: value.trim().isEmpty ? 'Medicine' : value.trim(),
      dosage: '',
      frequency: '',
      duration: '',
      instructions: '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  String get summary {
    final details = <String>[
      if (dosage.isNotEmpty) dosage,
      if (frequency.isNotEmpty) frequency,
      if (duration.isNotEmpty) duration,
    ];
    return details.isEmpty ? name : '$name — ${details.join(' • ')}';
  }
}

class PrescriptionModel {
  PrescriptionModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.medicineItems,
    required this.notes,
    required this.date,
    this.patientId = '',
    this.doctorId = '',
    this.appointmentId = '',
    this.diagnosis = '',
    this.followUpDate,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final List<PrescriptionMedicineModel> medicineItems;
  final String notes;
  final String diagnosis;
  final DateTime? followUpDate;
  final DateTime date;

  List<String> get medicines =>
      medicineItems.map((medicine) => medicine.summary).toList();

  factory PrescriptionModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final structuredItems = <PrescriptionMedicineModel>[];
    final rawItems = data['medicationItems'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          structuredItems.add(
            PrescriptionMedicineModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    if (structuredItems.isEmpty) {
      structuredItems.addAll(
        _readStringList(data['medicines']).map(
          PrescriptionMedicineModel.fromLegacy,
        ),
      );
    }

    final followUpValue = data['followUpDate'];

    return PrescriptionModel(
      id: document.id,
      patientId: (data['patientId'] ?? '').toString(),
      doctorId: (data['doctorId'] ?? '').toString(),
      appointmentId: (data['appointmentId'] ?? '').toString(),
      patientName: (data['patientName'] ?? 'Patient').toString(),
      doctorName: (data['doctorName'] ?? 'Doctor').toString(),
      medicineItems: structuredItems,
      notes: (data['notes'] ?? data['doctorNotes'] ?? '').toString(),
      diagnosis: (data['diagnosis'] ?? '').toString(),
      followUpDate: followUpValue == null
          ? null
          : _readDate(followUpValue, fallback: DateTime.now()),
      date: _readDate(
        data['createdAt'] ?? data['date'],
        fallback: DateTime.now(),
      ),
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

class ChatPartnerModel {
  const ChatPartnerModel({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String subtitle;
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

class SymptomRuleModel {
  SymptomRuleModel({
    required this.id,
    required this.symptoms,
    required this.department,
    required this.urgency,
    required this.advice,
    this.enabled = true,
  });

  final String id;
  final List<String> symptoms;
  final String department;
  final String urgency;
  final String advice;
  final bool enabled;

  factory SymptomRuleModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return SymptomRuleModel(
      id: document.id,
      symptoms: _readStringList(data['symptoms']),
      department: (data['department'] ?? 'General Medicine').toString(),
      urgency: (data['urgency'] ?? 'Routine').toString(),
      advice: (data['advice'] ?? '').toString(),
      enabled: data['enabled'] != false,
    );
  }
}

class EmergencyRequestModel {
  EmergencyRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String userId;
  final String userName;
  final String role;
  final String status;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  factory EmergencyRequestModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return EmergencyRequestModel(
      id: document.id,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'User').toString(),
      role: (data['role'] ?? '').toString(),
      status: (data['status'] ?? 'Open').toString(),
      createdAt: _readDate(data['createdAt'], fallback: DateTime.now()),
      latitude: data['latitude'] == null ? null : _readDouble(data['latitude']),
      longitude:
          data['longitude'] == null ? null : _readDouble(data['longitude']),
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
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
  final List<SymptomRuleModel> symptomRules = <SymptomRuleModel>[];
  final List<EmergencyRequestModel> emergencyRequests =
      <EmergencyRequestModel>[];

  final Set<String> _favoriteDoctorIds = <String>{};
  final Set<String> _bookedSlotIds = <String>{};
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
  int todayUserCount = 0;

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
    _startAppointmentSlotsListener();
    _startHospitalListener();
    _startReviewListener();
    _startSymptomRulesListener();
  }

  Future<void> _cancelDataSubscriptions() async {
    await _chatSubscription?.cancel();
    _chatSubscription = null;
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
    symptomRules.clear();
    emergencyRequests.clear();
    _favoriteDoctorIds.clear();
    _bookedSlotIds.clear();
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
    todayUserCount = 0;
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
      _startEmergencyRequestsListener();
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

  void _startAppointmentSlotsListener() {
    final subscription = _firestore
        .collection('appointment_slots')
        .where('booked', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        _bookedSlotIds
          ..clear()
          ..addAll(snapshot.docs.map((document) => document.id));
        notifyListeners();
      },
      onError: (_) {},
    );
    _subscriptions.add(subscription);
  }

  String appointmentSlotId(
    String doctorId,
    DateTime date,
    String time,
  ) {
    return '${doctorId}_${_dateKey(date)}_${_safeKey(time)}';
  }

  bool isSlotBooked(
    String doctorId,
    DateTime date,
    String time, {
    String? excludingAppointmentId,
  }) {
    final slotId = appointmentSlotId(doctorId, date, time);
    if (!_bookedSlotIds.contains(slotId)) return false;
    if (excludingAppointmentId == null) return true;
    return appointments.any(
      (appointment) =>
          appointment.slotId == slotId &&
          appointment.id != excludingAppointmentId &&
          appointment.status != 'Cancelled' &&
          appointment.status != 'Rejected',
    );
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

  List<SymptomRuleModel> get _defaultSymptomRules {
    return <SymptomRuleModel>[
      SymptomRuleModel(
        id: 'default_cardiology',
        symptoms: <String>[
          'Chest pain',
          'Breathing difficulty',
          'Fast heartbeat',
        ],
        department: 'Cardiology',
        urgency: 'Urgent',
        advice:
            'Chest or breathing symptoms may require urgent professional assessment.',
      ),
      SymptomRuleModel(
        id: 'default_dermatology',
        symptoms: <String>['Skin rash', 'Skin itching'],
        department: 'Dermatology',
        urgency: 'Routine',
        advice:
            'Avoid known irritants and arrange a consultation if symptoms continue.',
      ),
      SymptomRuleModel(
        id: 'default_orthopedics',
        symptoms: <String>['Joint pain', 'Back pain'],
        department: 'Orthopedics',
        urgency: 'Routine',
        advice:
            'Limit activities that worsen the pain and seek professional guidance if it persists.',
      ),
      SymptomRuleModel(
        id: 'default_gastroenterology',
        symptoms: <String>['Stomach pain', 'Vomiting'],
        department: 'Gastroenterology',
        urgency: 'Priority',
        advice:
            'Maintain hydration and seek medical advice if symptoms are severe or persistent.',
      ),
      SymptomRuleModel(
        id: 'default_general',
        symptoms: <String>['Fever', 'Headache', 'Cough', 'Weakness'],
        department: 'General Medicine',
        urgency: 'Routine',
        advice:
            'Rest, stay hydrated, and consult a qualified professional if symptoms continue or worsen.',
      ),
    ];
  }

  List<SymptomRuleModel> get effectiveSymptomRules {
    final enabledRules = symptomRules.where((rule) => rule.enabled).toList();
    return enabledRules.isEmpty ? _defaultSymptomRules : enabledRules;
  }

  List<String> get availableSymptoms {
    final result = effectiveSymptomRules
        .expand((rule) => rule.symptoms)
        .map((symptom) => symptom.trim())
        .where((symptom) => symptom.isNotEmpty)
        .toSet()
        .toList();
    result.sort((first, second) => first.compareTo(second));
    return result;
  }

  SymptomRuleModel? matchingSymptomRule(List<String> selectedSymptoms) {
    if (selectedSymptoms.isEmpty) return null;
    final selected =
        selectedSymptoms.map((symptom) => symptom.toLowerCase().trim()).toSet();

    SymptomRuleModel? bestRule;
    var bestMatches = 0;
    for (final rule in effectiveSymptomRules) {
      final matches = rule.symptoms.where((symptom) {
        return selected.contains(symptom.toLowerCase().trim());
      }).length;
      if (matches > bestMatches) {
        bestMatches = matches;
        bestRule = rule;
      }
    }
    return bestRule;
  }

  void _startSymptomRulesListener() {
    final subscription =
        _firestore.collection('symptom_rules').snapshots().listen(
      (snapshot) {
        symptomRules
          ..clear()
          ..addAll(snapshot.docs.map(SymptomRuleModel.fromFirestore));
        symptomRules.sort(
          (first, second) => first.department.compareTo(second.department),
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
        final now = DateTime.now();
        todayUserCount = snapshot.docs.where((document) {
          final createdAt = document.data()['createdAt'];
          if (createdAt is! Timestamp) return false;
          final date = createdAt.toDate();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).length;
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

  void _startEmergencyRequestsListener() {
    final subscription =
        _firestore.collection('emergency_requests').snapshots().listen(
      (snapshot) {
        emergencyRequests
          ..clear()
          ..addAll(snapshot.docs.map(EmergencyRequestModel.fromFirestore));
        emergencyRequests.sort(
          (first, second) => second.createdAt.compareTo(first.createdAt),
        );
        emergencyRequestCount = emergencyRequests.length;
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

  List<ChatPartnerModel> get chatPartners {
    final partners = <String, ChatPartnerModel>{};

    for (final appointment in appointments) {
      if (appointment.status == 'Cancelled' ||
          appointment.status == 'Rejected') {
        continue;
      }

      if (currentUserRole == 'patient' && appointment.doctorId.isNotEmpty) {
        partners[appointment.doctorId] = ChatPartnerModel(
          id: appointment.doctorId,
          name: appointment.doctorName,
          subtitle: appointment.specialty,
        );
      } else if (currentUserRole == 'doctor' &&
          appointment.patientId.isNotEmpty) {
        partners[appointment.patientId] = ChatPartnerModel(
          id: appointment.patientId,
          name: appointment.patientName,
          subtitle: 'Patient',
        );
      }
    }

    final result = partners.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  void _chooseChatPartner() {
    final availablePartners = chatPartners;

    if (availablePartners.isEmpty) {
      activeChatPartnerId = '';
      activeChatPartnerName = 'Healthcare Contact';
      activeChatPartnerSubtitle = '';
      chatMessages.clear();
      unawaited(_chatSubscription?.cancel());
      _chatSubscription = null;
      return;
    }

    final currentStillAvailable = availablePartners.any(
      (partner) => partner.id == activeChatPartnerId,
    );
    final partner = currentStillAvailable
        ? availablePartners.firstWhere(
            (item) => item.id == activeChatPartnerId,
          )
        : availablePartners.first;

    selectChatPartner(partner);
  }

  void selectChatPartner(ChatPartnerModel partner) {
    if (partner.id.isEmpty) return;

    final partnerChanged = partner.id != activeChatPartnerId;
    activeChatPartnerId = partner.id;
    activeChatPartnerName = partner.name;
    activeChatPartnerSubtitle = partner.subtitle;

    if (partnerChanged) {
      chatMessages.clear();
      _startChatListener(partner.id);
    }
    notifyListeners();
  }

  void _startChatListener(String partnerId) {
    unawaited(_chatSubscription?.cancel());
    final conversationId = _conversationId(currentUserId, partnerId);
    _chatSubscription = _firestore
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

  int averageConsultationMinutesForDoctor(String doctorId) {
    final measured = appointments
        .where((appointment) => appointment.doctorId == doctorId)
        .map((appointment) => appointment.consultationMinutes)
        .whereType<int>()
        .toList();
    if (measured.isEmpty) {
      for (final doctor in doctors) {
        if (doctor.id == doctorId) {
          return doctor.averageConsultationMinutes <= 0
              ? 12
              : doctor.averageConsultationMinutes;
        }
      }
      return 12;
    }
    final total =
        measured.fold<int>(0, (runningTotal, item) => runningTotal + item);
    return (total / measured.length).round();
  }

  DateTime? get lastCompletedVisitForCurrentPatient {
    final completed = appointments
        .where((appointment) => appointment.status == 'Completed')
        .toList();
    if (completed.isEmpty) return null;
    completed.sort((first, second) => second.date.compareTo(first.date));
    return completed.first.completedAt ?? completed.first.date;
  }

  int predictedQueueMinutes(DoctorModel doctor) {
    final consultationTime = averageConsultationMinutesForDoctor(doctor.id);
    if (doctor.queueLength == 0) return 0;
    return doctor.queueLength * consultationTime;
  }

  String suggestDepartment(List<String> selectedSymptoms) {
    if (selectedSymptoms.isEmpty) return 'Please select symptoms';
    return matchingSymptomRule(selectedSymptoms)?.department ??
        'General Medicine';
  }

  String symptomUrgency(List<String> selectedSymptoms) {
    return matchingSymptomRule(selectedSymptoms)?.urgency ?? 'Routine';
  }

  String healthSuggestion(List<String> selectedSymptoms) {
    final rule = matchingSymptomRule(selectedSymptoms);
    final urgency = rule?.urgency.toLowerCase() ?? '';

    if (urgency == 'emergency' || urgency == 'urgent') {
      return rule?.advice.isNotEmpty == true
          ? rule!.advice
          : 'Urgent attention may be required. Contact emergency support or a qualified doctor.';
    }
    if (healthProfile.bmi >= 30) {
      return 'Your BMI is high. Discuss a safe health plan with a qualified healthcare professional. ${rule?.advice ?? ''}'
          .trim();
    }
    if (healthProfile.bmi > 0 && healthProfile.bmi < 18.5) {
      return 'Your BMI is below the healthy range. Consider discussing nutrition with a healthcare professional. ${rule?.advice ?? ''}'
          .trim();
    }
    if (rule != null && rule.advice.isNotEmpty) return rule.advice;
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
    final slotId = appointmentSlotId(doctor.id, date, time);
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
      final newSlotId = appointmentSlotId(doctorId, date, time);
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
      if (status == 'In Consultation')
        'startedAt': FieldValue.serverTimestamp(),
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
      'repeat': 'Daily',
      'taken': false,
      'lastTakenDateKey': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: currentUserId,
      title: 'Medicine Added',
      message: '$name daily reminder was added.',
    );
  }

  Future<void> toggleMedicineTaken(String medicineId) async {
    final reference = _firestore.collection('medicines').doc(medicineId);
    final snapshot = await reference.get();
    if (!snapshot.exists) return;

    final todayKey = _dateKey(DateTime.now());
    final alreadyTakenToday =
        (snapshot.data()?['lastTakenDateKey'] ?? '').toString() == todayKey;

    await reference.update({
      'taken': !alreadyTakenToday,
      'lastTakenDateKey': alreadyTakenToday ? '' : todayKey,
      'lastTakenAt': alreadyTakenToday ? null : FieldValue.serverTimestamp(),
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
    required List<PrescriptionMedicineModel> medicines,
    required String diagnosis,
    required String notes,
    DateTime? followUpDate,
  }) async {
    final patientId = _patientIdByName[patientName] ?? '';
    if (patientId.isEmpty) {
      throw StateError('Select a patient who has an appointment with you.');
    }
    if (medicines.isEmpty) {
      throw StateError('Add at least one medicine.');
    }

    final relatedAppointments = appointments.where((appointment) {
      return appointment.patientId == patientId &&
          appointment.doctorId == currentUserId;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final appointmentId =
        relatedAppointments.isEmpty ? '' : relatedAppointments.first.id;

    final reference = _firestore.collection('prescriptions').doc();
    final batch = _firestore.batch();
    batch.set(reference, {
      'patientId': patientId,
      'doctorId': currentUserId,
      'appointmentId': appointmentId,
      'patientName': patientName,
      'doctorName': doctorName,
      'diagnosis': diagnosis.trim(),
      'medicationItems': medicines.map((item) => item.toMap()).toList(),
      'medicines': medicines.map((item) => item.summary).toList(),
      'doctorNotes': notes.trim(),
      'notes': notes.trim(),
      if (followUpDate != null)
        'followUpDate': Timestamp.fromDate(
          DateTime(followUpDate.year, followUpDate.month, followUpDate.day),
        ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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

  Future<void> saveWeeklySchedule(
    String doctorId,
    Map<int, DoctorDaySchedule> schedule,
  ) async {
    final serialized = <String, dynamic>{
      for (final entry in schedule.entries)
        entry.key.toString(): entry.value.toMap(),
    };
    await _firestore.collection('doctors').doc(doctorId).update({
      'weeklySchedule': serialized,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveScheduleException({
    required String doctorId,
    required DateTime date,
    required bool unavailable,
    required List<String> customTimes,
    String note = '',
  }) async {
    final key = _dateKey(date);
    await _firestore.collection('doctors').doc(doctorId).update({
      'scheduleExceptions.$key': <String, dynamic>{
        'unavailable': unavailable,
        'customTimes': customTimes,
        'note': note.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeScheduleException(
    String doctorId,
    DateTime date,
  ) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'scheduleExceptions.${_dateKey(date)}': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAccountProfile({
    required String name,
    required String phone,
    String specialty = '',
    String qualification = '',
    int experienceYears = 0,
    String hospitalName = '',
    String bio = '',
    int averageConsultationMinutes = 30,
  }) async {
    if (currentUserId.isEmpty) {
      throw StateError('No signed-in user was found.');
    }

    final cleanedName = name.trim();
    if (cleanedName.length < 2) {
      throw StateError('Please enter a valid name.');
    }

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(currentUserId),
      <String, dynamic>{
        'name': cleanedName,
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (currentUserRole == 'doctor') {
      batch.set(
        _firestore.collection('doctors').doc(currentUserId),
        <String, dynamic>{
          'name': cleanedName,
          'phone': phone.trim(),
          'specialty': specialty.trim(),
          'designation': specialty.trim(),
          'qualification': qualification.trim(),
          'experienceYears': experienceYears,
          'hospitalName': hospitalName.trim(),
          'bio': bio.trim(),
          'averageConsultationMinutes':
              averageConsultationMinutes.clamp(10, 180),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> addAvailability(
    String doctorId,
    DateTime date,
    String time,
  ) async {
    final normalizedTime = time.trim();
    if (normalizedTime.isEmpty) return;
    final slot = availabilitySlotValue(date, normalizedTime);
    await _firestore.collection('doctors').doc(doctorId).update({
      'availableSlots': FieldValue.arrayUnion(<String>[slot]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAvailability(String doctorId, String slot) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'availableSlots': FieldValue.arrayRemove(<String>[slot]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> toggleDoctorApproval(String doctorId) async {
    final doctor = doctors.firstWhere((item) => item.id == doctorId);
    final newValue = !doctor.approved;
    final batch = _firestore.batch();
    batch.update(_firestore.collection('doctors').doc(doctorId), {
      'approved': newValue,
      'accountStatus': newValue ? 'approved' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('users').doc(doctorId), {
      'approved': newValue,
      'accountStatus': newValue ? 'approved' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return newValue;
  }

  Future<void> removeDoctor(String doctorId) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('doctors').doc(doctorId),
      {
        'available': false,
        'approved': false,
        'accountStatus': 'disabled',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('users').doc(doctorId),
      {
        'isActive': false,
        'approved': false,
        'accountStatus': 'disabled',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> restoreDoctor(String doctorId) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('doctors').doc(doctorId),
      {
        'available': true,
        'approved': false,
        'accountStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('users').doc(doctorId),
      {
        'isActive': true,
        'approved': false,
        'accountStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> saveSymptomRule({
    String? ruleId,
    required List<String> symptoms,
    required String department,
    required String urgency,
    required String advice,
    bool enabled = true,
  }) async {
    if (currentUserRole != 'admin') {
      throw StateError('Only an administrator can manage symptom rules.');
    }
    final cleanedSymptoms = symptoms
        .map((symptom) => symptom.trim())
        .where((symptom) => symptom.isNotEmpty)
        .toSet()
        .toList();
    if (cleanedSymptoms.isEmpty || department.trim().isEmpty) {
      throw StateError('Symptoms and department are required.');
    }
    final reference = ruleId == null || ruleId.isEmpty
        ? _firestore.collection('symptom_rules').doc()
        : _firestore.collection('symptom_rules').doc(ruleId);
    await reference.set({
      'symptoms': cleanedSymptoms,
      'department': department.trim(),
      'urgency': urgency.trim().isEmpty ? 'Routine' : urgency.trim(),
      'advice': advice.trim(),
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      if (ruleId == null || ruleId.isEmpty)
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSymptomRule(String ruleId) async {
    if (currentUserRole != 'admin') {
      throw StateError('Only an administrator can manage symptom rules.');
    }
    await _firestore.collection('symptom_rules').doc(ruleId).delete();
  }

  Future<void> seedDefaultSymptomRules() async {
    if (currentUserRole != 'admin') {
      throw StateError('Only an administrator can manage symptom rules.');
    }
    final batch = _firestore.batch();
    for (final rule in _defaultSymptomRules) {
      batch.set(
        _firestore.collection('symptom_rules').doc(rule.id),
        {
          'symptoms': rule.symptoms,
          'department': rule.department,
          'urgency': rule.urgency,
          'advice': rule.advice,
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> updateEmergencyRequestStatus({
    required String requestId,
    required String status,
  }) async {
    if (currentUserRole != 'admin') {
      throw StateError('Only an administrator can update emergency requests.');
    }
    await _firestore.collection('emergency_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'handledBy': currentUserId,
    });
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
