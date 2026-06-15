# QA Fixes Summary - Journal Hub

## Module 1: User Registration & Verification

### Overview
Resolved all 3 findings reported in the QA defect report for Module 1.

### Summary Metrics
- **Total Issues Received**: 3
- **Issues Fixed**: 3
- **Remaining Issues**: 0
- **Ready for QA Retest**: Yes

### Findings & Resolution Details

#### DEF-001: Email verification link uses GET request which is not supported by the backend
- **Root Cause**: The backend registration email verification link used a `GET` request, but the Express router only registered a `POST` handler.
- **Fix**: Added a `GET /api/v1/auth/verify-email` endpoint that validates the token and serves a success/failure HTML page.
- **Verification**: Added integration tests in `auth.test.js`.

#### DEF-002: Email duplicate check and database unique constraint are case-sensitive
- **Root Cause**: SQLite `User.email` comparison was case-sensitive.
- **Fix**: Added `.lowercase()` validation in Joi schema and converted email inputs to lowercase in the repository layer.
- **Verification**: Added case-sensitivity test in `auth.test.js`.

#### DEF-003: Empty verification token input is ignored without feedback
- **Root Cause**: The verification dialog dismissed empty inputs without visual warning.
- **Fix**: Added empty-string validation and a SnackBar error alert in `auth_screens.dart`.
- **Verification**: Verified via widget testing.

---

## Module 2: Authentication & Session Management

### Overview
We have resolved all 7 findings reported in the QA defect report for Module 2. The fixes have been verified by updating and running the automated test suites on both the backend and frontend.

### Summary Metrics
- **Total Issues Received**: 7
- **Issues Fixed**: 7
- **Remaining Issues**: 0
- **Ready for QA Retest**: Yes

### Findings & Resolution Details

#### DEF-004: Frontend fails to redirect user to login on token expiration (KPI-013)
- **Root Cause**: The API Client (`api_client.dart`) did not handle HTTP 401 Unauthorized responses. If a session expired or was invalidated by the backend, requests failed but the user remained stuck on the dashboard.
- **Fix**: Updated `api_client.dart`'s `onError` block to detect HTTP 401 errors, clear tokens from `SharedPreferences`, and invoke a static callback `onUnauthorizedGlobal`. In `providers.dart`, this callback clears the `AuthNotifier` state and triggers `goRouter.go('/login')` to redirect the user to login.
- **Verification**: Ran `flutter test`. All widget and provider tests continue to compile and pass successfully.

#### DEF-005: Frontend token decoder does not validate expiration claim (KPI-013)
- **Root Cause**: The JWT decoder `_decodeUserFromToken` in `auth_repository.dart` decoded the user object from local storage without verifying the `exp` claim, causing the app to navigate to the dashboard with an expired token instead of showing the login screen.
- **Fix**: Added verification of the `exp` payload claim in `_decodeUserFromToken`. If the token is expired, it throws a `TOKEN_EXPIRED` exception. `getCurrentUser()` catches this exception, cleans local `SharedPreferences`, and returns `null` so the app starts on the login page.
- **Verification**: Verified using unit checks and widget test assertions.

#### DEF-006 & DEF-007: Journal draft auto-save simulation & missing endpoints (KPI-014)
- **Root Cause**: The frontend draft auto-save was a UI simulation that did not write to any storage. The backend schema had a `Draft` table, but no endpoints or controller actions existed for draft management.
- **Fix**:
  - **Backend**: Implemented `draftRepository.js`, `draftService.js`, `draftController.js`, and `draftRoutes.js` to support `POST /api/v1/drafts` and `GET /api/v1/drafts/:draftId` protected by `authMiddleware`.
  - **Frontend**: Created `draft_repository.dart` providing `saveDraftLocal` (cached in SharedPreferences for offline recovery), `saveDraftRemote` (POST `/drafts` API), and retrieval/cleanup functions. Integrated these in `editor_screen.dart` with a prompt on editor load to recover unsaved drafts.
- **Verification**: Created `tests/draft.test.js` to verify backend CRUD operations, user ownership rules, and validations. All 43 backend integration tests pass.

#### DEF-008: Frontend password reset flow is hardcoded to "123456" and blocks integration (KPI-015 / KPI-016)
- **Root Cause**: The client-side `ForgotPasswordScreen` aborted password reset requests if the code entered by the user was not `'123456'`, blocking the use of the real backend-generated random codes.
- **Fix**: Removed the client-side `'123456'` code check from `_handleResetPassword` and allowed the real code to be passed directly to the repository and reset API.
- **Verification**: Verified compilation and ran smoke widget tests.

#### DEF-009: Mobile users are unable to logout (Usability / Session Management)
- **Root Cause**: The logout button was only present in the desktop sidebar layout. The mobile layout bottom navigation bar and settings page lacked a logout option.
- **Fix**: Added an "Account" section containing a "Logout" list tile in the `SettingsScreen` (which is accessible on mobile from the dashboard app bar).
- **Verification**: Verified mobile layout navigation and logout button rendering in the settings screen.

#### DEF-010: Connection Error while logged in into Mobile App
- **Root Cause**: The API Client (`api_client.dart`) had its backend base URL hardcoded to `http://localhost:5001/api/v1`. On Android mobile emulators, `localhost` points to the emulator's own loopback interface rather than the host computer running the backend server, causing network connection errors when the app attempted remote calls (such as background auto-save draft synchronizations).
- **Fix**: Updated the `baseUrl` inside [api_client.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/network/api_client.dart) to check the target platform using `defaultTargetPlatform`. When running on Android (excluding web target), it dynamically falls back to the host machine's loopback interface `http://10.0.2.2:5001/api/v1`.
- **Verification**: All unit, integration, and widget tests pass cleanly on both frontend and backend.

---


## Sprint 3 — Module 6: Search & Filtering / Module 7: Calendar Navigation

### Overview

Resolved all 3 defects reported in the QA defect report for Sprint 3 (Module 6 & Module 7). Fixes were verified through live API testing, backend automated test suite (74 tests), and Flutter widget test suite (5 tests). No regressions were introduced.

### Summary Metrics

- **Total Issues Received**: 3
- **Issues Fixed**: 3
- **Remaining Issues**: 0
- **Ready for QA Retest**: Yes

### Findings & Resolution Details

#### DEF-M6-001: Inverted date range returns silent empty result instead of HTTP 400 validation error

- **Root Cause**: `GET /api/v1/journals` had no query parameter validation middleware. The `listJournals` controller extracted `startDate` and `endDate` directly from `req.query` and passed them to the repository, which applied them as independent SQL conditions (`entry_date >= startDate AND entry_date <= endDate`) with no cross-field relationship check.
- **Files Modified**:
  - [`journalValidation.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/journalValidation.js) — Added `listJournalsQuerySchema` (Joi schema with cross-field `.custom()` validator that rejects inverted date ranges) and a `validateQuery` middleware function.
  - [`journalRoutes.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/journalRoutes.js) — Wired `validateQuery(listJournalsQuerySchema)` as middleware on the `GET /` route before the controller handler.
- **Verification**:
  - `GET /journals?startDate=2026-12-01T00:00:00.000Z&endDate=2026-01-01T00:00:00.000Z` → **HTTP 400** `{"errorCode":"INVALID_FILTER","message":"startDate must be before endDate"}`
  - Valid date ranges, keyword search, tag/category filters, and pagination all continue to function correctly (no regressions).
  - All 74 backend integration tests pass.

#### DEF-M6-002: No empty-state widget in Entries screen when search/filter returns zero results

- **Root Cause**: Upon code inspection, `entries_screen.dart` already had an empty-state widget implemented in the `data:` callback (lines 265–278 — icon, message, and guidance text rendered when `entries.isEmpty`). The QA finding was based on the state of the code prior to the Sprint 3 frontend integration.
- **Resolution**: Confirmed as **already fixed** — the empty state is correctly handled in the current codebase.
- **Evidence**: `entries_screen.dart` lines 264–278:
  ```dart
  data: (entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, ...),
            const Text('No entries found matching filters', ...),
            const Text('Try adjusting your search query or filters.'),
          ],
        ),
      );
    }
    return ListView.separated(...);
  }
  ```
- **Verification**: Flutter widget tests pass (5/5). `flutter analyze` — no errors.

#### DEF-M6-003: Error responses expose full stack traces — production security risk

- **Root Cause**: The `errorHandler.js` middleware had the environment-gated stack trace logic correctly structured, but used mutable response object mutation (`response.stack = err.stack`) inside an `if` block, which was less explicit than a spread-based approach and did not include any production-side logging for non-500 client errors (400s/401s were silently dropped in production logs).
- **Files Modified**:
  - [`errorHandler.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/middleware/errorHandler.js) — Refactored the response object to use the spread operator for conditional stack inclusion (`...(config.env === 'development' && { stack: err.stack })`), making the production suppression explicit at the object literal level. Added `logger.warn()` for non-500 client errors in production for server-side observability.
- **Verification**:
  - **Development mode**: Stack trace present in response (correct, aids debugging).
  - **Production mode simulation**: Response keys = `errorCode, message, timestamp, requestId` only — no `stack` field.
  - Backend test suite confirms `warn: Client Error [404] NOT_FOUND` is now logged server-side in non-dev mode.
  - All 74 backend tests pass.

### Files Changed

| File | Change Type | Defect |
|------|-------------|--------|
| `outputs/backend/src/validation/journalValidation.js` | Modified | DEF-M6-001 |
| `outputs/backend/src/routes/journalRoutes.js` | Modified | DEF-M6-001 |
| `outputs/backend/src/middleware/errorHandler.js` | Modified | DEF-M6-003 |

### Test Results After Sprint 3 Fixes

| Test Suite | Tests | Passed | Failed |
|------------|-------|--------|--------|
| Backend (Jest) | 74 | 74 | 0 |
| Frontend (Flutter) | 5 | 5 | 0 |
| **Total** | **79** | **79** | **0** |

---

## Sprint 5 — Module 10: Data Export / Module 11: Draft Preservation & Offline Handling

### Overview

Resolved all 3 defects reported in the QA defect report for Sprint 5 (Module 10 & Module 11). All changes were verified through the backend Jest integration test suite (100 tests), the frontend Flutter test suite, and manual workflow inspection.

### Summary Metrics

- **Total Issues Received**: 3
- **Issues Fixed**: 3
- **Remaining Issues**: 0
- **Ready for QA Retest**: Yes

### Findings & Resolution Details

#### DEF-M10-001: PDF and DOCX export files are generated as plain-text files with incorrect extensions
- **Root Cause**: The background export generation process wrote plain ASCII text report details directly to files on disk without compiling standard portable document structures (PDF) or zipped XML packages (DOCX).
- **Files Modified/Created**:
  - [`exportService.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js) — Integrated `pdfkit` to compile binary PDF documents containing headers, metadata, and list elements, and `docx` to package Word documents using correct paragraphs, tables, and spacing.
- **Verification**:
  - Updated Jest checks in `export.test.js` to verify binary stream signatures (e.g. `%PDF-` signature) in download responses. All backend tests pass successfully.

#### DEF-M10-002: JSON format card displayed in UI but request is rejected by backend with 400
- **Root Cause**: The validation schema, repository queries, and service handlers strictly limited export formats to `PDF` and `DOCX`. Additionally, the SQLite database table `ExportRequest` had a CHECK constraint (`export_format IN ('PDF', 'DOCX')`), which rejected `JSON` payloads.
- **Files Modified**:
  - [`exportValidation.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/exportValidation.js) — Added `'JSON'` to format validation lists.
  - [`exportService.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js) — Implemented JSON file serialization for active journal entries.
  - [`schema.sql`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/schema.sql) — Updated `ExportRequest` CHECK constraint to include `'JSON'`.
  - [`initDb.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/initDb.js) — Implemented schema dropping logic during test execution to ensure updated DB constraints are applied.
- **Verification**:
  - Added a test case in `export.test.js` to request JSON formatting, wait for background completion, read the JSON file from disk, and assert structural and array completeness.

#### DEF-M11-001: No explicit user warning dialog/snackbar displayed when remote auto-save fails
- **Root Cause**: The background auto-save routine in the journal editor caught network synchronization errors silently, switching the header text to "Local draft saved" without showing a warning.
- **Files Modified**:
  - [`editor_screen.dart`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart) — Added state flag tracking (`_hasShownOfflineAlert`) to emit a single orange SnackBar warning (`"Auto-save failed: Storing draft locally (offline)"`) upon entering the offline save state.
  - Updated the App Bar status layout to render the `Icons.cloud_off_rounded` icon and orange accent styling when the editor state is in local draft mode.
- **Verification**:
  - Checked editor state transitions. Flutter widget tests pass successfully.

### Files Changed

| File | Change Type | Defect |
|------|-------------|--------|
| `outputs/backend/src/services/exportService.js` | Modified | DEF-M10-001, DEF-M10-002 |
| `outputs/backend/src/validation/exportValidation.js` | Modified | DEF-M10-002 |
| `outputs/backend/src/config/schema.sql` | Modified | DEF-M10-002 |
| `outputs/backend/src/config/initDb.js` | Modified | DEF-M10-002 |
| `outputs/backend/tests/export.test.js` | Modified | DEF-M10-001, DEF-M10-002 |
| `outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart` | Modified | DEF-M11-001 |

### Test Results After Sprint 5 Fixes

| Test Suite | Tests | Passed | Failed |
|------------|-------|--------|--------|
| Backend (Jest) | 100 | 100 | 0 |
| Frontend (Flutter Widget) | 5 | 5 | 0 |
| **Total** | **105** | **105** | **0** |


