# Security, Privacy, and Limitations

## Security controls

The Firestore rules apply role-based access for:

- users
- doctors
- health profiles
- appointments and slots
- prescriptions
- medicines
- timeline events
- notifications and announcements
- messages and call requests
- emergency requests
- hospitals
- symptom rules
- reviews

Key principles:

- Authentication is required for application data.
- Users cannot publicly register as admin.
- Patients access their own health and appointment records.
- Doctors access assigned appointments and linked patient profiles.
- Admins manage approvals and system-level data.
- Reviews require a completed appointment.
- Messages require the signed-in user to be a participant.

## Important security testing still required

Rules must be tested against attempted invalid operations, not only through visible UI buttons. Test at least:

- patient reading another patient's profile
- doctor reading an unrelated profile
- patient writing admin or doctor approval fields
- unapproved doctor accessing doctor features
- user reading a conversation they do not participate in
- patient reviewing a non-completed appointment

## Sensitive files

Do not commit:

- `.env` files
- service-account JSON files
- keystores or `key.properties`
- API keys
- passwords
- exported real patient data

`firebase_options.dart` and `google-services.json` identify the Firebase app but are not service-account credentials. Firestore rules still protect data; nevertheless, only authorized teammates should have Firebase Console access.

## Medical limitations

DocMate:

- does not diagnose disease
- does not verify medicines entered manually by a patient
- does not replace a doctor
- does not validate a prescription against drug interactions
- does not guarantee queue times
- does not dispatch an ambulance
- does not monitor a patient in real time
- does not provide a certified emergency service

The symptom checker and health suggestions must always be described as educational decision support.

## Technical limitations

- Current shared state and data operations are concentrated in `AppData`; this is acceptable for the project scope but not ideal for a large production codebase.
- Automated coverage is currently minimal; most confidence must come from runtime acceptance testing.
- No operating-system-level local-notification package is currently declared, so medicine reminders should not be claimed as guaranteed scheduled background alarms.
- Push notification delivery through Firebase Cloud Messaging is not part of the current dependency set.
- Text chat uses Firestore; there is no end-to-end encryption layer implemented by the app.
- Call request is a database workflow, not voice or video calling.
- Hospital records depend on admin-entered Firestore data and may be incomplete.
- Phone authentication can be limited by Firebase quotas/configuration.
- Google Sign-In requires platform-specific Firebase/OAuth configuration.
- The optional OpenAI Firebase Function is not the tested default symptom-checker path.
- No payment, insurance, video consultation, or clinical analytics system is included.

## Data protection recommendations for a real deployment

A real healthcare deployment would require:

- legal and regulatory review for the target country
- explicit patient consent and privacy notices
- minimum necessary data collection
- retention and deletion policies
- audit logs
- verified healthcare-provider identities
- incident response procedures
- encryption and device-security review
- secure backup and recovery
- accessibility and clinical safety assessment
- professional penetration testing

Do not use university demo data as real clinical records.
