DOCMATE STEP 6 - DYNAMIC DOCTOR DATA

This patch keeps the current UI and replaces demo doctor data with real-time
Cloud Firestore doctor records.

What becomes dynamic in this step:
- Patient doctor discovery and search
- Current patient/doctor display name
- Admin doctor list
- Doctor approval/unapproval
- Doctor removal from Firestore
- Doctor availability slots in Dart
- Loading, empty, refresh, and error states
- Doctor dashboard safely loads the signed-in doctor's own Firestore profile

Appointments, prescriptions, chat, medicines, notifications, and timeline are
still demo/static in this step. They will be migrated in later steps.

APPLY
1. Put DocMate_Dynamic_Doctors_Patch.zip inside D:\DocMate
2. Run:

Set-Location D:\DocMate
Expand-Archive -LiteralPath .\DocMate_Dynamic_Doctors_Patch.zip -DestinationPath . -Force
Remove-Item .\DocMate_Dynamic_Doctors_Patch.zip -Force
dart format lib
flutter analyze
flutter test

Do not commit until flutter analyze and flutter test succeed.

TEST
1. Run the app and log in as admin.
2. Open Manage Doctors. The doctors must match Firestore, not demo names.
3. Approve/unapprove one doctor.
4. In Firestore, confirm approved changes in both doctors/{uid} and users/{uid}.
5. Log in as a patient. Only approved and available doctors should appear.
6. Log in as an approved doctor. The dashboard should show that doctor's real
   name and specialty.

Do not test appointment booking yet. Appointment migration is the next step.
