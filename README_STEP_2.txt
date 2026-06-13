DOCMATE STEP 2 - LINT FIX PATCH

This patch keeps the existing UI and Firebase behavior.
It only fixes the remaining Dart/Flutter analyzer issues in four files.

From PowerShell in D:\DocMate:

1. Put DocMate_LintFix_Patch.zip inside D:\DocMate
2. Run:

Expand-Archive -Path .\DocMate_LintFix_Patch.zip -DestinationPath . -Force
dart format lib
flutter analyze

Expected result:
No issues found!

The patch changes:
- mounted checks after asynchronous Firebase calls
- deprecated withOpacity() calls to withValues(alpha: ...)
- safe controller disposal in EditHealthProfile
- Firestore server timestamp for health profile updates
