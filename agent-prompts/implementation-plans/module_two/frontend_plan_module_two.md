# Implementation Plan - Frontend Module 2: Authentication & Session Management

Connect the existing Flutter login, logout, forgot-password, and reset-password flows to the real backend endpoints using Dio, Riverpod, and SharedPreferences.

## Proposed Changes

### [Frontend Repositories]

#### [MODIFY] [auth_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/auth_repository.dart)
Connect login, password recovery, and logout APIs:
- Add `_decodeUserFromToken(String token)` helper which decodes base64url JWT payloads to reconstruct a `User` entity locally.
- Implement `getCurrentUser()`: reads `access_token` from `SharedPreferences` and restores active session at app startup.
- Update `login(email, password)`: calls `POST /auth/login`, saves `access_token` and `refresh_token` to `SharedPreferences`, and returns reconstructed `User`.
- Update `forgotPassword(email)`: calls `POST /auth/forgot-password`.
- Update `resetPassword(token, password)`: calls `POST /auth/reset-password`.
- Add `logout()`: calls `POST /auth/logout` (swallowing HTTP failures to ensure local logout is reliable) and clears `SharedPreferences`.

---

### [State Management & Providers]

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
Sync AuthNotifier with token persistence and backend state changes:
- In `AuthNotifier` constructor, set initial state to `AsyncValue.loading()` and call private `_init()` method to restore active session via `_repo.getCurrentUser()`.
- Update `AuthNotifier.login` to load, call `_repo.login`, and assign the returned `User` as active state data.
- Update `AuthNotifier.logout` to load, call `_repo.logout`, and reset active state to `null`.
- Add `AuthNotifier.resetPassword` to expose password reset logic through Riverpod.

---

### [Widgets & Verification UI]

#### [MODIFY] [auth_screens.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/auth/presentation/auth_screens.dart)
Update reset password action triggers:
- Update `ForgotPasswordScreen`'s `_handleSendCode` and `_handleResetPassword` to call real repository methods from `authRepositoryProvider`.

---

## Verification Plan

### Automated Tests
- Update `TestAuthRepository` subclass in `widget_test.dart` to support Module 2 mock endpoints, ensuring existing smoke tests continue to compile and pass.
- Run `flutter analyze` to ensure zero compilation/lint issues.
- Run `flutter test` to ensure all widget and unit test suites pass.

### Manual Verification
- Run backend on port 5001.
- Open frontend client, test login flow with verified credentials.
- Test login failures for pending/disabled accounts.
- Test forgot-password and reset-password flows by extracting token from terminal log and changing account password.
- Test logout, confirming subsequent protected queries fail.
