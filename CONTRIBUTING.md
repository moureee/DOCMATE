# Contributing to DocMate

Use feature or fix branches and open pull requests. Before committing Dart changes, run:

```powershell
dart format lib
flutter analyze
flutter test
```

Before a release-candidate update, also run:

```powershell
flutter build apk --debug
```

Do not commit generated ZIP/APK files, secrets, service-account credentials, keystores, passwords, or real patient data.

See [docs/TEAM_WORKFLOW.md](docs/TEAM_WORKFLOW.md) for the full collaboration process.
