# Implementation Plan - Frontend Module 1: User Registration & Verification

Connect the existing Flutter registration screen flow to the real backend APIs (`POST /auth/register` and `POST /auth/verify-email`) using Dio and Riverpod.

## User Review Required

> [!IMPORTANT]
> - **Self-Contained Verification Dialog**: A custom `_showVerificationDialog(String email)` will be integrated into the `RegisterScreen`. This dialog will display a text field allowing the QA team and users to input the verification token directly in the app to call the `/auth/verify-email` endpoint. This maintains a fully clickable, testable onboarding flow without redesigning the screens.
> - **Session Management**: Successful registration returns a pending user account. The user session (`authProvider`) remains unauthenticated until the email is verified and the user logs in via the login screen.

---

## Proposed Changes

### [Frontend Client & Repositories]

All modifications are under [outputs/frontend](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend).

#### [NEW] [auth_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/auth_repository.dart)
Create real auth repository using `ApiClient`:
- `register(fullName, email, password)`: calls `POST /auth/register`.
- `verifyEmail(token)`: calls `POST /auth/verify-email`.
- `login(email, password)`, `forgotPassword(email)`, `resetPassword(token, password)`: retain mock configurations to keep downstream features compiled and testable.

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
Connect real repository and update notifier:
- Define `apiClientProvider` exposing `ApiClient`.
- Update `authRepositoryProvider` to return `AuthRepository` injecting the `ApiClient`.
- Update `AuthNotifier.register` to return `Future<User>` on success, keeping the active session state as `null`.

#### [MODIFY] [auth_screens.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/auth/presentation/auth_screens.dart)
Integrate email verification dialog in `RegisterScreen`:
- Implement `_showVerificationDialog(String email)` containing verification token input and a "Verify" action calling `authRepositoryProvider.verifyEmail`.
- Update `_handleRegister` to call `AuthNotifier.register` asynchronously and display the verification dialog upon successful request.
- Remove registration data listener in `ref.listen` since the flow is handled directly in `_handleRegister`.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure zero compilation or static analysis issues.
- Update `widget_test.dart` to mock/verify the register and email verification flows if possible.
- Run `flutter test`.

### Manual Verification
- Start backend server on port 5001.
- Run the Flutter application on Chrome Web.
- Open registration page, input details, and submit.
- Retrieve verification token from backend stdout terminal logs.
- Paste token into the verification dialog, click "Verify", and verify that a success snackbar is shown.
- Navigate to login page, input registration credentials, and verify dashboard loads with user details.
