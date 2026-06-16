# Runtime Acceptance Testing Checklist

Static analysis and one widget test are not enough. Complete this checklist with separate Firebase accounts.

## Test record template

```text
Tester:
Date/device:
App branch/tag:
Role:
Screen:
Action:
Expected result:
Actual result:
Error text:
Screenshot/video:
Firestore documents affected:
Pass/Fail:
```

## Pre-test checks

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes
- [ ] debug APK builds
- [ ] Firestore rules are deployed
- [ ] patient, approved doctor, unapproved doctor, and admin accounts exist
- [ ] symptom rules are seeded
- [ ] at least one hospital test record exists

## Authentication and roles

- [ ] Patient registration creates correct `users` document
- [ ] Doctor registration creates `users` and `doctors` documents with approval false
- [ ] Unapproved doctor cannot enter doctor dashboard
- [ ] Admin approval enables doctor access
- [ ] Patient cannot open doctor/admin data by changing UI flow
- [ ] Doctor cannot access unrelated patient data
- [ ] Logout clears role-specific state

## Core appointment workflow

- [ ] Doctor adds availability
- [ ] Patient sees approved doctor and availability
- [ ] Patient books a slot
- [ ] A second patient cannot book the same doctor/date/time
- [ ] Appointment appears for patient and doctor
- [ ] Doctor accepts
- [ ] Doctor starts consultation
- [ ] Doctor completes
- [ ] Patient sees status changes
- [ ] Timeline receives appropriate records
- [ ] Notifications appear

## Cancel and reschedule

- [ ] Patient cancels an allowed appointment
- [ ] Old slot becomes available
- [ ] Patient reschedules to a free slot
- [ ] Rescheduling to a booked slot is rejected
- [ ] Appointment date/time and slot records remain consistent

## Prescriptions and medicines

- [ ] Doctor can prescribe only to an eligible patient
- [ ] Patient sees the new prescription
- [ ] Timeline receives prescription event
- [ ] Patient notification appears
- [ ] Patient can add a manual medicine
- [ ] Taken state persists after reopening

## Health profile

- [ ] Patient can save height and weight
- [ ] BMI calculation is correct for known test values
- [ ] Allergies and conditions persist
- [ ] Quick health card shows the signed-in patient
- [ ] Last visit uses latest completed appointment
- [ ] Eligible doctor can read linked profile
- [ ] Unrelated doctor is denied

## Smart features

- [ ] Symptom rules load from Firestore
- [ ] Admin can add/edit/disable/delete a rule
- [ ] Default rules can be seeded without harmful duplicates
- [ ] Department suggestion matches selected symptoms
- [ ] Urgency and advice display
- [ ] Doctor ranking changes with rating, availability, and queue
- [ ] Queue estimate uses current queue and consultation average
- [ ] Medical disclaimer is visible

## Reviews and favourites

- [ ] Favourite persists after relaunch
- [ ] Patient cannot review before completion
- [ ] Patient can review completed appointment
- [ ] Only one review document exists per appointment
- [ ] Doctor rating display updates from reviews

## Chat and communication

- [ ] Eligible patient and doctor can exchange messages
- [ ] Messages appear in correct order
- [ ] Unrelated users cannot read the conversation
- [ ] Call request creates a record and notification
- [ ] UI does not claim that a real call was started

## Emergency

- [ ] Location permission accepted path works
- [ ] Permission denied path still saves request without location
- [ ] Hospital phone action opens the device dialler
- [ ] Admin sees emergency request
- [ ] Admin changes request status
- [ ] Patient cannot manage other users' requests

## Admin

- [ ] Dashboard totals match Firestore
- [ ] User list loads
- [ ] Appointment monitor loads
- [ ] Doctor approval updates both relevant documents
- [ ] Announcement appears for authenticated users
- [ ] Emergency request status persists

## Offline/error/empty states

- [ ] Empty doctor list has a clear message
- [ ] Empty appointment list has a clear message
- [ ] Loading indicator appears during initial fetch
- [ ] Firestore permission error is handled without a permanent spinner
- [ ] Network loss does not crash the app
- [ ] Repeated button taps do not create obvious duplicate records

## Build and device checks

- [ ] Android debug APK installs on at least two devices/emulators
- [ ] Location permission text is understandable
- [ ] Phone link opens correctly
- [ ] Back navigation works
- [ ] No overflow on common screen sizes
- [ ] No debug banner
- [ ] App relaunch preserves login appropriately

## Release gate

Create `v1.0.0` only when:

- [ ] all critical workflow tests pass
- [ ] no open security defect remains
- [ ] analyzer and tests pass
- [ ] final APK builds
- [ ] known limitations are documented
- [ ] defence demo accounts and data are prepared
