# Architecture

## Overview

DocMate is a Flutter/Dart client backed by Firebase Authentication and Cloud Firestore.

```text
Flutter screens
    ↓
AppData (ChangeNotifier-style shared state and operations)
    ↓
Firebase Authentication + Cloud Firestore
```

The application is grouped by feature rather than keeping every screen in one flat directory.

## Feature folders

```text
features/auth     Authentication, role selection, intro, splash, auth gate
features/patient  Patient dashboard and patient-only workflows
features/doctor   Doctor dashboard and doctor-only workflows
features/admin    Admin dashboard and management workflows
features/shared   Chat, symptom checker, emergency, notifications
```

## Startup flow

1. `main.dart` initializes Firebase using `firebase_options.dart`.
2. `SplashScreen` starts the application experience.
3. `AuthGate` checks Firebase Authentication.
4. The matching `users/{uid}` document is read.
5. Routing is based on `role`:
   - `patient` → patient home
   - approved `doctor` → doctor home
   - `admin` → admin home
6. Unapproved doctors are signed out and must wait for admin approval.

## Data flow

`AppData`:

- listens to authentication changes
- starts role-specific Firestore listeners
- converts Firestore documents into Dart models
- exposes lists and calculated values to screens
- performs writes such as booking, status updates, prescriptions, messages, reviews, notifications, and emergency requests
- notifies the UI when data changes

This is a practical beginner-friendly architecture. A larger production system would normally split models, repositories, services, and controllers into separate files.

## Main models

The current shared data file defines models for:

- doctors
- appointments
- medicines
- prescriptions
- health profiles
- chat messages
- timeline entries
- notifications
- hospitals
- symptom rules
- emergency requests

## Appointment transaction

Booking uses a Firestore transaction:

```text
Check deterministic appointment slot
→ reject if already booked
→ mark slot booked
→ create appointment
→ connect doctor to health profile
→ create timeline entry
→ create notification
```

The deterministic slot identifier combines doctor, date, and time, reducing accidental double booking.

## Queue prediction

```text
predicted waiting time = current queue length × average consultation minutes
```

Average consultation duration is calculated from appointments with measured `startedAt` and `completedAt` timestamps. When no measured duration exists, the configured doctor average is used, with a fallback of 12 minutes.

## Doctor ranking

The current score is transparent:

```text
rating × 20
+ available-slot count × 2
− queue length × 1.5
```

Only approved and available doctors are ranked for patient discovery.

## Symptom decision logic

1. Patient selects symptoms.
2. Enabled Firestore symptom rules are examined.
3. The best matching rule supplies:
   - department
   - urgency
   - advice
4. Approved doctors can be filtered/ranked for the suggested department.
5. BMI contributes to the educational health suggestion.

This is explainable rule-based decision support, not diagnosis.

## Role-specific listeners

All signed-in roles receive shared doctor, hospital, review, and symptom-rule data. Additional listeners are started according to role:

- **Patient:** appointments, prescriptions, notifications, favourites, health profile, medicines, timeline
- **Doctor:** appointments, prescriptions, notifications, eligible patient profiles, chat
- **Admin:** appointments, notifications, users, emergency requests

## Security boundary

Screens hide features by role, but UI visibility is not the security boundary. Firestore Security Rules enforce document access on the backend.

## Future architecture improvement

For a post-defence version, split `AppData` into:

```text
models/
services/
repositories/
controllers/
```

Suggested repositories:

- AuthRepository
- DoctorRepository
- AppointmentRepository
- PrescriptionRepository
- HealthRepository
- ChatRepository
- EmergencyRepository
- AdminRepository

Make this refactor only after the current release candidate is stable, because it touches many files without changing visible features.
