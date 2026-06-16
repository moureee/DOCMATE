# DocMate

**DocMate: Bridging Patients and Doctors with Smart Care** is a Flutter application written in Dart for a university defence project. It connects patients, doctors, and administrators through role-based workflows backed by Firebase Authentication and Cloud Firestore.

> **Important:** DocMate is an educational decision-support project. It is not a certified medical device, does not provide a medical diagnosis, and does not replace professional or emergency healthcare services.

## Project status

- Release candidate: `v0.9-rc1`
- Main development branch: `remaining-dynamic-features`
- Release preparation branch: `release-prep`
- Dart analyzer: clean at the release-candidate checkpoint
- Flutter tests: passing at the release-candidate checkpoint
- Android debug APK: successfully built at the release-candidate checkpoint

Runtime acceptance testing with patient, doctor, and admin accounts is still required before creating `v1.0.0`.

## Main features

### Patient

- Register and sign in
- Find approved doctors by name or specialty
- View doctor profiles, ratings, queues, and availability
- Favourite doctors
- Book, cancel, and reschedule appointments
- View appointment status and estimated queue time
- Maintain a health profile and BMI
- Use a rule-based symptom checker
- Receive department, urgency, and doctor suggestions
- View prescriptions and maintain medicines
- View health timeline and quick health card
- Exchange text messages with an eligible doctor
- Send a call request
- View notifications and announcements
- Submit an emergency request with location when permission is available
- Review a doctor after a completed appointment

### Doctor

- Register and wait for admin approval
- Manage profile and availability slots
- View assigned appointments
- Accept, reject, start, and complete consultations
- View eligible patient health information
- Create prescriptions and clinical notes
- Exchange text messages with eligible patients
- View patient totals and measured consultation-time insights

### Admin

- Approve, unapprove, and deactivate doctors
- View users and appointments
- View dashboard totals
- Publish announcements
- Manage rule-based symptom mappings
- View and resolve emergency requests

## Smart decision features

DocMate implements transparent, explainable rules rather than claiming clinical diagnosis:

- **Symptom mapping:** selected symptoms are matched to Firestore-managed department and urgency rules.
- **Doctor ranking:** rating and available slots increase the score; queue length reduces it.
- **Queue prediction:** queue length is multiplied by the doctor's measured or configured average consultation duration.
- **Health suggestions:** BMI ranges and symptom urgency produce educational guidance.

The repository also contains an optional Firebase Function prototype for an OpenAI-based symptom check. The current Flutter app uses the local/Firestore rule-based flow as its dependable university-demo path; the cloud AI function requires separate secret, dependency, deployment, cost, and safety validation.

## Technology stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase CLI
- Geolocator
- Permission Handler
- URL Launcher
- Google Sign-In dependency
- Firebase Functions prototype in Node.js

## Project structure

```text
lib/
├── core/
│   └── theme/
├── data/
│   └── app_data.dart
├── features/
│   ├── auth/
│   ├── patient/
│   ├── doctor/
│   ├── admin/
│   └── shared/
├── firebase_options.dart
└── main.dart
```

`AppData` currently acts as the shared application state and Firestore data layer. Screens are grouped by feature to keep patient, doctor, admin, authentication, and shared functionality separate.

## Quick start

```powershell
git clone https://github.com/moureee/DOCMATE.git
cd DOCMATE
git switch release-prep
flutter pub get
flutter analyze
flutter test
flutter run
```

A working Firebase project configuration is required. Read [docs/INSTALLATION.md](docs/INSTALLATION.md) before running a fresh clone.

## Documentation

- [Installation and Firebase setup](docs/INSTALLATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Firestore schema](docs/FIRESTORE_SCHEMA.md)
- [User guide](docs/USER_GUIDE.md)
- [Testing checklist](docs/TESTING_CHECKLIST.md)
- [Security and limitations](docs/SECURITY_AND_LIMITATIONS.md)
- [Team workflow](docs/TEAM_WORKFLOW.md)
- [University defence guide](docs/DEFENCE_GUIDE.md)

## Release process

Do not merge the release candidate into `main` until runtime testing is complete.

Recommended sequence:

```text
Test release candidate
→ record defects
→ fix confirmed defects
→ rerun analyzer/tests/build
→ merge release-prep into main
→ create v1.0.0 tag
→ build final APK
```
