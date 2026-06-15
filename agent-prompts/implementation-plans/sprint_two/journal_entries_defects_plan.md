# Implementation Plan - Debug & Fix Journal Entries Flow

This plan addresses the critical defects in the **Journal Entries** flow (white screen on save, app crash, and missing security audit logs).

## User Review Required

> [!IMPORTANT]
> - **Error Rethrowing in Notifier**: The Riverpod state notifier `JournalsNotifier` will now rethrow network and data mapping exceptions so the UI can intercept them, display an error message, and keep the user on the editor screen instead of navigating away.
> - **Inline Loading State**: We will replace the dialog-route loading indicator (`showDialog` with `CircularProgressIndicator`) with an inline loading state (`_isLoading` flag). This prevents mixing Navigator pops with GoRouter transitions, which causes race conditions leading to a white screen.

## Proposed Changes

---

### [Frontend Notifier & UI Layer]

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
- Update `addEntry`, `updateEntry`, and `deleteEntry` methods in `JournalsNotifier` to rethrow exceptions:
  ```dart
  try {
    await _repo.createEntry(entry);
    _ref.invalidate(allEntriesProvider);
    await loadEntries();
  } catch (e, stack) {
    state = AsyncValue.error(e, stack);
    rethrow; // Rethrow to let UI handle the error state
  }
  ```

#### [MODIFY] [editor_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart)
- Add a boolean state variable `bool _isLoading = false;` to `_EditorScreenState`.
- Modify `_saveEntry()` to:
  1. Set `_isLoading = true;` and trigger `setState()`.
  2. Perform the save/update.
  3. Show success SnackBar and navigate `context.go('/journals')`.
  4. In `catch (e)`, show error SnackBar, set `_isLoading = false;` and trigger `setState()`.
- Update the UI to render a `LinearProgressIndicator` when `_isLoading` is true and disable the Save button.

---

### [Backend Controller & Service Layer]

#### [MODIFY] [authController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/authController.js)
- Extract client IP address using `req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;`.
- Pass the extracted IP address to `authService.registerUser` and `authService.loginUser`.

#### [MODIFY] [authService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/authService.js)
- Update `registerUser` to accept `clientIp` and call `auditRepository.log(user.user_id, 'User', user.user_id, 'Register', clientIp)`.
- Update `loginUser` to accept `clientIp` and call `auditRepository.log(user.user_id, 'User', user.user_id, 'Login', clientIp)`.

#### [MODIFY] [journalController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/journalController.js)
- Extract client IP address from request.
- Pass the IP address to `journalService.createJournal`, `journalService.updateJournal`, and `journalService.deleteJournal`.

#### [MODIFY] [journalService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/journalService.js)
- Update `createJournal`, `updateJournal`, and `deleteJournal` to accept `clientIp`.
- Log audits to `AuditLog` table using `auditRepository.log()`:
  - Inside `createJournal`: log `Create` action on `JournalEntry`.
  - Inside `updateJournal`: log `Update` action on `JournalEntry`.
  - Inside `deleteJournal`: log `Delete` (or `'SoftDelete'` / `'HardDelete'`) action on `JournalEntry`.

---

## Verification Plan

### Automated Tests
- Run Jest automated tests on the backend: `npm test`
- Run Flutter unit and widget tests on the frontend: `flutter test`

### Manual Verification
- Register a user and log in.
- Create a new journal entry, select category/tags, and verify it saves successfully.
- Verify that saving does not show a white screen.
- Query the SQLite database and assert that the `AuditLog` table successfully records `Register`, `Login`, `Create`, `Update`, and `Delete` actions.
