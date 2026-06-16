# User Guide

## Patient workflow

### Create an account

1. Choose Patient.
2. Register using the configured authentication method.
3. Complete the health profile.
4. Sign in and open the patient dashboard.

Email/password is the recommended test path. Google and phone login require additional Firebase configuration and should be tested separately.

### Find and book a doctor

1. Open doctor discovery.
2. Search by doctor name or specialty.
3. Open a doctor profile.
4. Choose an available time.
5. Enter symptoms and pre-visit notes.
6. Confirm the booking.
7. Verify it appears in My Appointments.

### Cancel or reschedule

Open the appointment and choose the relevant action. Rescheduling checks the new deterministic slot before releasing the old one.

### Symptom checker

1. Select symptoms.
2. Review suggested department and urgency.
3. Review the educational health suggestion.
4. Open a suggested doctor when available.

Always show and explain the disclaimer during the defence: the feature is decision support, not diagnosis.

### Health profile and card

Enter height, weight, allergies, blood group, conditions, and emergency-contact details. BMI is calculated from height and weight. The quick health card summarizes the current patient and latest completed visit.

### Prescriptions and medicines

Doctors create prescriptions. Patients can view them and maintain manual medicine records. Do not describe manual medicine entries as verified prescriptions.

### Chat and call request

Chat is restricted to an eligible patient-doctor relationship created through appointment history. A call request records a request and notification; it does not initiate a real call.

### Emergency mode

The app can:

- request location permission
- show stored hospitals
- open a phone number through the device
- save an emergency request for admin review

It does not dispatch an ambulance and must not be presented as a real emergency-response service.

## Doctor workflow

### Registration and approval

1. Register as doctor and choose a specialty.
2. The user and doctor documents are created with `approved: false`.
3. Admin approves the doctor.
4. The doctor can then sign in.

### Availability

Add or remove displayable availability times. Patients can use these times during booking. Check for real booking conflicts through the `appointment_slots` collection.

### Appointment management

1. Open assigned appointments.
2. Accept or reject.
3. Start consultation when applicable.
4. Mark completed.
5. Add prescription and notes.

Starting and completing consultations provides data for average consultation duration.

### Patient information

Doctors should only view profiles for patients linked to them. Firestore rules use `doctorIds` in the health profile as part of the authorization check.

### Insights

Doctor insights are based on actual loaded appointment records, including patient count and measured average consultation time where timestamps exist.

## Admin workflow

### Doctor management

Approve/unapprove doctors and deactivate profiles. The approval state must remain consistent in both `users/{uid}` and `doctors/{uid}`.

### Symptom rules

Use **Add Default Rules** once if the collection is empty. Admins can then add, update, disable, or remove rules.

### Emergency requests

Open the emergency-request screen, review the requesting user and available location data, and update status. This is an administrative record, not emergency dispatch.

### Announcements

Publish an announcement for authenticated users. Avoid entering private medical information in global announcements.
