# Implementation Plan - Sprint 5 Frontend (Data Export & Draft / Offline Handling)

We will connect the Flutter UI to the real backend APIs for Module 10 (Data Export) and ensure Module 11 (Draft Preservation & Offline Handling) operates robustly.

## User Review Required

> [!IMPORTANT]
> - **Adding GET /export Route in Backend**: The API contract currently specifies creating (`POST /export`) and querying single statuses (`GET /export/:exportId`), but doesn't define listing previous exports. To populate "Recent Export Requests" in the Flutter UI dynamically, we will add an authenticated `GET /api/v1/export` endpoint to the Express backend that returns all previous exports for the logged-in user (joined with their file metadata to provide active `downloadUrl` paths).
> - **Failed Export Retry UI**: We will add a "Retry" button to export job list tiles in the `Failed` state. Tapping it will call the backend `POST /api/v1/export/:exportId/retry` endpoint and reset the UI's progress polling.
> - **Error Handling**: Currently, the export UI swallows request exceptions. We will propagate exceptions to show error SnackBars (e.g., when a user attempts a forbidden `JSON` format that the backend doesn't support).

## Proposed Changes

### Component: Backend API Extensions

#### [MODIFY] [exportRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/exportRepository.js)
* Update `getUserExportRequests(userId)` to use a LEFT JOIN query with the `ExportFile` table:
  ```sql
  SELECT r.*, f.download_url
  FROM ExportRequest r
  LEFT JOIN ExportFile f ON r.export_id = f.export_id
  WHERE r.user_id = ?
  ORDER BY r.requested_at DESC;
  ```
* Include `downloadUrl` mapping in the returned result list.

#### [MODIFY] [exportService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js)
* Expose `getUserExports(userId)` method returning list from `exportRepository.getUserExportRequests(userId)`.

#### [MODIFY] [exportController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/exportController.js)
* Add `getUserExports(req, res, next)` to query the service and respond with a `200` JSON list.

#### [MODIFY] [exportRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/exportRoutes.js)
* Mount `GET /` to `exportController.getUserExports`.

#### [MODIFY] [export.test.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/tests/export.test.js)
* Add unit test verifying `GET /api/v1/export` successfully lists user export history with status codes and download URLs.

---

### Component: Frontend Repositories & Providers

#### [NEW] [export_repository.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/repositories/export_repository.dart)
* Implement `ExportRepository` using the injected `ApiClient`:
  - `getExportJobs()`: Send `GET /export` request and deserialize response list into `List<ExportJob>`.
  - `requestExport(String format)`: Send `POST /export` with `{ 'format': format }` and deserialize response into `ExportJob`.
  - `retryExport(String exportId)`: Send `POST /export/:exportId/retry` and deserialize response.

#### [MODIFY] [providers.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/core/providers/providers.dart)
* Replace mock repository reference `exportRepositoryProvider` with:
  ```dart
  final exportRepositoryProvider = Provider<ExportRepository>((ref) {
    final apiClient = ref.watch(apiClientProvider);
    return ExportRepository(apiClient);
  });
  ```
* Update `ExportsNotifier` to consume the real `ExportRepository`.
* Update `ExportsNotifier.requestExport` to throw exceptions so caller interfaces (UI) can display error SnackBars.
* Add `retryExport(String exportId)` in `ExportsNotifier` calling repository retry.

---

### Component: Frontend UI (Export Screen)

#### [MODIFY] [export_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/export/presentation/export_screen.dart)
* Wrap `requestExport` in a `try-catch` block inside `_triggerExport` to show an error SnackBar on failure (e.g. for invalid format requests like `JSON`).
* In `_buildJobTile`, check if `job.status == 'Failed'`. If so, render a "Retry" button that calls a `_retryExport` helper.
* Ensure download alerts use the authentic backend URL dynamically.

---

## Verification Plan

### Automated Tests
* Run backend integration tests:
  ```bash
  npm test
  ```
* Run frontend unit and widget tests:
  ```bash
  flutter test
  ```

### Manual Verification
* Start the backend server on port 5001.
* Trigger exports in both supported formats (`PDF`, `DOCX`) and verify they transition to `Completed` with valid download paths.
* Verify triggering a `JSON` format properly shows an error SnackBar.
* Simulate a failed generation, verify the job lists as `Failed` in the queue, click "Retry", and confirm recovery.
