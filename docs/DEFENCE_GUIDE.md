# University Defence Guide

## 30-second introduction

DocMate is a Flutter application written in Dart that connects patients, doctors, and administrators through Firebase. Patients can discover doctors, book appointments, manage health information, receive rule-based symptom guidance, and view prescriptions. Doctors manage availability, appointments, patient information, and prescriptions. Admins approve doctors, monitor the system, manage symptom rules, announcements, and emergency requests.

## Problem statement

Patients often face fragmented doctor discovery, appointment scheduling, queue uncertainty, medicine tracking, and emergency-information access. Small clinics may also lack a simple shared platform for patients, doctors, and administrators.

## Proposed solution

DocMate combines role-based healthcare workflows in one mobile application with a dynamic Firestore backend. It emphasizes transparent decision rules and manageable scope rather than unsafe claims of automated diagnosis.

## Why Flutter and Dart?

- one codebase for multiple platforms
- fast UI development
- strong widget ecosystem
- Dart null safety
- suitable for a university team and limited development time

## Why Firebase?

- Authentication for account identity
- Firestore real-time listeners
- transactions for appointment slots
- Security Rules for backend authorization
- rapid setup without building a custom server

## What makes the system dynamic?

Data is not stored as fixed dashboard text. Users, doctors, appointments, statuses, prescriptions, messages, reviews, symptom rules, notifications, and emergency requests are loaded from or written to Firestore. Changes can appear to other authorized accounts through listeners.

## Explain the AI features honestly

### Symptom checker

The tested app uses rule-based decision support. Symptoms are matched against admin-managed Firestore rules that return department, urgency, and advice. This is safer and more explainable for the project than pretending to diagnose disease.

### Doctor ranking

```text
score = rating × 20 + available slots × 2 − queue length × 1.5
```

### Queue prediction

```text
waiting time = queue length × average consultation duration
```

The average comes from measured consultation timestamps when available, otherwise from the configured doctor duration.

### Health suggestion

BMI category and symptom urgency are combined to show educational guidance. The system does not declare that the patient has a disease.

## Strong demonstration sequence

Use prepared accounts and data:

1. Admin approves a doctor.
2. Doctor signs in and adds availability.
3. Patient signs in and finds the doctor.
4. Patient books a slot.
5. Show that a duplicate booking is prevented.
6. Doctor accepts, starts, and completes the appointment.
7. Doctor creates a prescription.
8. Patient sees status, prescription, notification, and timeline changes.
9. Patient submits a review.
10. Admin opens dashboard, symptom rules, and emergency requests.

## Likely viva questions and answers

### Is this a real AI diagnosis system?

No. The tested feature is rule-based decision support. It recommends a department and urgency level and includes a disclaimer. Diagnosis remains the responsibility of a qualified clinician.

### How do you prevent two patients booking the same slot?

The app generates a deterministic slot document and uses a Firestore transaction. The transaction checks whether the slot is already booked before creating the appointment and marking the slot.

### How do you protect patient information?

Firebase Authentication identifies the user, role documents define patient/doctor/admin access, and Firestore Security Rules enforce document-level authorization. We also test cross-user access attempts.

### Why is hiding a button not enough?

A modified client could call Firestore directly. Therefore backend rules, not only UI navigation, must deny unauthorized requests.

### How is queue time predicted?

Current queued patients are multiplied by the doctor's average consultation duration. It is shown as an estimate because consultation time varies.

### How are doctors ranked?

The score rewards higher ratings and more available slots and penalizes longer queues. The formula is transparent and easy to explain.

### Why did you remove video and payments?

They add high complexity, legal risk, external-service dependencies, and limited value to the core academic objective. The project focuses on complete, testable healthcare workflows.

### Can a doctor see every patient's health profile?

No. The rules require an allowed relationship. Booking adds the doctor's UID to the patient's authorized doctor list, and rules use that relationship.

### How are reviews protected?

The review document uses the appointment ID, and rules verify that the signed-in patient owns a completed appointment with the reviewed doctor.

### What happens without internet?

The app depends on Firebase for current data. Firestore may cache some data, but complete offline behavior was not designed or guaranteed for this release.

### Why is the app not production-ready for real healthcare?

It has not undergone medical-device, privacy, security, accessibility, clinical, or regulatory certification. Emergency requests are records, not dispatch. The project is an educational prototype/release candidate.

### What would you improve next?

- expand automated tests and rule tests
- split `AppData` into repositories/controllers
- add verified local reminders and push notifications
- improve audit logging
- add provider verification
- add accessibility testing
- add stronger privacy and retention controls

## Known limitations to admit confidently

- no real ambulance dispatch
- no video consultation
- no payment system
- no guaranteed background medicine alarms
- no certified clinical diagnosis
- optional cloud AI prototype is not the default tested path
- acceptance testing is required before final release

Being honest about scope is stronger than claiming unimplemented features.

## Final defence checklist

- Prepare patient, approved doctor, unapproved doctor, and admin accounts.
- Seed symptom rules.
- Add at least one hospital.
- Prepare one available doctor slot.
- Use non-sensitive fake data.
- Keep screenshots or a short recording as backup.
- Keep a debug APK and charging cable.
- Demonstrate a clean end-to-end workflow rather than opening every screen.
- State the medical disclaimer before showing smart features.
