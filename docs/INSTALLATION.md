# Installation and Firebase Setup

## Prerequisites

Install:

- Flutter SDK compatible with Dart `^3.5.0`
- Android Studio or Android SDK command-line tools
- VS Code with Flutter and Dart extensions
- Git
- Node.js and npm only if Firebase Functions will be deployed
- Firebase CLI

Verify the environment:

```powershell
flutter doctor -v
firebase --version
```

## Clone and prepare the project

```powershell
git clone https://github.com/moureee/DOCMATE.git
cd DOCMATE
git switch release-prep
flutter pub get
flutter analyze
flutter test
```

## Firebase project requirements

The checked-in project is configured for the Firebase project `docmate-2026`. A teammate using the same Firebase backend must have access to that Firebase project.

Required Firebase services:

1. **Authentication**
   - Email/Password must be enabled.
   - Google Sign-In requires provider configuration and platform credentials.
   - Phone authentication requires provider setup, quota, and device verification. Email/password is the recommended defence-demo baseline.

2. **Cloud Firestore**
   - The default database must exist.
   - `firestore.rules` must be deployed.
   - `firestore.indexes.json` should be deployed even if it currently contains no composite indexes.

3. **Android Firebase configuration**
   - `android/app/google-services.json` must match the Firebase Android app.
   - `lib/firebase_options.dart` must match the Firebase project.

## Deploy Firestore rules and indexes

From the project root:

```powershell
firebase login
firebase use docmate-2026
firebase deploy --only firestore:rules,firestore:indexes
```

Do not replace the deployed rules with open test-mode rules.

## Admin account

Public registration only creates patient or doctor accounts. Create the first admin manually:

1. Firebase Console → Authentication → Users → Add user.
2. Copy the created user's UID.
3. Firestore → `users` → create a document whose document ID is that UID.
4. Add at least:

```text
uid: <authentication UID>
name: DocMate Admin
email: <admin email>
role: admin
isActive: true
createdAt: <timestamp>
```

Never expose or commit the admin password.

## Seed symptom rules

After signing in as admin:

```text
Admin Dashboard → Symptom Rules → Add Default Rules
```

The app can use built-in fallback mappings, but seeding Firestore makes the rules editable and dynamic.

## Optional hospital data

Emergency screens read from the `hospitals` collection. Add documents with fields such as:

```text
name: City Hospital
address: Example Road
phone: +8801XXXXXXXXX
latitude: 24.0000
longitude: 91.0000
isOpen24Hours: true
services: [Emergency, Cardiology]
```

Use realistic test data, not real emergency claims, unless the information has been verified.

## Run the application

```powershell
flutter run
```

Build a debug APK:

```powershell
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Optional Firebase Functions prototype

The `functions/` directory contains an OpenAI-based callable-function prototype. It is not required for the rule-based app flow.

To experiment with it, the team must separately:

- install Node dependencies in `functions/`
- configure the `OPENAI_API_KEY` Firebase secret
- add and test the matching Flutter callable-functions integration
- validate cost, authentication, output parsing, safety, and failure handling

Do not put API keys in Dart files, Git, or screenshots.

## Common commands

```powershell
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter test
flutter build apk --debug
firebase deploy --only firestore:rules,firestore:indexes
```

## Troubleshooting

### Kotlin incremental-cache error followed by successful build

If Gradle prints a Kotlin daemon/cache stack trace but ends with:

```text
Built build\app\outputs\flutter-apk\app-debug.apk
```

then the build succeeded. If it fails without an APK, run:

```powershell
flutter clean
Remove-Item .\build -Recurse -Force -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --debug
```

### Permission denied from Firestore

Record:

- signed-in role
- collection and action
- document fields
- exact error

Then compare the request with `firestore.rules`. Do not reopen the entire database for testing.

### Doctor cannot sign in

Confirm both documents use the same UID and have approval enabled:

```text
users/{uid}.role == doctor
users/{uid}.approved == true
doctors/{uid}.approved == true
```
