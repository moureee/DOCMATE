# Team Workflow

## Branch roles

- `main`: stable presentation-ready code only
- `remaining-dynamic-features`: release candidate used for runtime testing
- `release-prep`: documentation, cleanup, and final-release preparation

Avoid making unrelated changes directly on `main` while testers are validating a release candidate.

## Update local project

```powershell
git fetch origin --tags
git switch release-prep
git pull origin release-prep
flutter pub get
```

## Start a bug-fix branch

```powershell
git switch release-prep
git pull
git switch -c fix/short-problem-name
```

After the fix:

```powershell
dart format lib
flutter analyze
flutter test
flutter build apk --debug
git add -A
git commit -m "Fix: describe the problem"
git push -u origin fix/short-problem-name
```

Open a pull request instead of asking teammates to copy individual Dart files.

## Avoid merge conflicts

Assign ownership by feature:

```text
Patient tester/developer → features/patient
Doctor tester/developer  → features/doctor
Admin tester/developer   → features/admin
Shared/auth owner        → features/shared and features/auth
Backend owner            → firestore.rules, firebase.json, functions
```

Tell the team before modifying `lib/data/app_data.dart`, because many screens depend on it.

## Bug report format

```text
Branch/tag:
Commit:
Role:
Device:
Screen:
Steps to reproduce:
Expected:
Actual:
Error:
Screenshot/video:
Firestore documents affected:
```

## Before merging

```powershell
git status
dart format lib
flutter analyze
flutter test
flutter build apk --debug
```

Review:

- security-rule changes
- role restrictions
- collection/field names
- generated files
- accidental secrets
- unrelated formatting

## Final merge outline

After acceptance testing and fixes:

```powershell
git switch release-prep
git pull origin release-prep
git switch main
git pull origin main
git merge --no-ff release-prep
git push origin main

git tag -a v1.0.0 -m "DocMate university defence release"
git push origin v1.0.0
```

Only perform this after the team agrees that the release gate in `TESTING_CHECKLIST.md` is satisfied.
