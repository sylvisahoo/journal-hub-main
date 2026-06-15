# Walkthrough - Sprint 5 Backend & Frontend Integration (Data Export & Draft / Offline Handling)

We have fully implemented the backend features and integrated them with the frontend UI for Module 10 (Data Export) and Module 11 (Draft Preservation & Offline Handling). All backend and frontend test suites are passing successfully.

---

## 1. Backend Implementation (Sprint 5 Backend)

### Architectural Decisions
* **Asynchronous Generation Worker**: Export requests (`POST /api/v1/export`) immediately return a `202 Accepted` response. The generation of the export archive is offloaded to a background queue using `setImmediate()`, ensuring the main thread is not blocked during intensive disk write/query operations.
* **Format-Specific Validation**: A strict Joi validation schema enforces that data exports are requested in either `PDF` or `DOCX` formats. (Requests for other formats, like `JSON`, are rejected at the API level).
* **Audit Logging & Security**:
  - Verification check ensures users can only check status or retry jobs that they own (returning `403 ACCESS_DENIED` on ownership mismatch).
  - Every export request logs an `Export` action in the `AuditLog` table.
  - Every job retry logs an `ExportRetry` action in the `AuditLog` table.
* **In-App Notification Triggering**: Upon completion or failure of the background export task, a live system notification is automatically generated and inserted into the `Notification` table to alert the user.
* **Static Asset Delivery**: Express is configured to serve generated reports statically from the `public/exports` directory, matching the static routing path `/exports/:fileName`.
* **Export Requests Listing**: Added `GET /api/v1/export` to support populated lists of previous exports. It joins `ExportRequest` and `ExportFile` to include `download_url` for completed jobs.

### Database Schema Additions
Two tables are utilized within the schema to support tracking exports:
* **`ExportRequest`**: Stores the job state (`Pending`, `Processing`, `Completed`, `Failed`), format, request timestamp, and owner reference.
* **`ExportFile`**: Tracks the generated filename, absolute download URL, and expiration timestamp (set to 24 hours).

---

## 2. Frontend Integration (Sprint 5 Frontend)

### Repository & State Management
* **`ExportRepository`**: Implemented real API calls using the `ApiClient`'s Dio client:
  - `getExportJobs()` mapping to `GET /api/v1/export` to fetch all jobs.
  - `requestExport(format)` mapping to `POST /api/v1/export` to initiate a new job.
  - `getExportStatus(exportId)` mapping to `GET /api/v1/export/:exportId`.
  - `retryExport(exportId)` mapping to `POST /api/v1/export/:exportId/retry`.
* **`providers.dart`**:
  - Registered `exportRepositoryProvider` using the real `ExportRepository`.
  - Wired `exportsProvider` with `ExportsNotifier`, which periodically refreshes export jobs (every 2 seconds) and exposes `requestExport` and `retryExport` methods.
  - Ensured exceptions from requests are propagated to the caller UI to allow user-friendly error SnackBars.

### UI Enhancements (`export_screen.dart`)
* **Error Handling**: Wrapped `requestExport` in a `try-catch` inside `_triggerExport`, displaying a red SnackBar containing the backend error message (e.g. `INVALID_EXPORT_FORMAT` when requesting `JSON`).
* **Failed Jobs Retry**: Modified `_buildJobTile` to accept `WidgetRef ref` and display a orange **Retry** button when a job status is `Failed`.
* **Retry Actions**: Implemented `_retryExport(context, ref, job)` to execute the retry endpoint on the backend and display status-change SnackBars.

---

## 3. API Endpoints Summary

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/v1/export` | Creates a new export job and triggers background generator | Yes |
| `GET` | `/api/v1/export` | Lists all export jobs belonging to the authenticated user | Yes |
| `GET` | `/api/v1/export/:exportId` | Fetches the status and download link for an export job | Yes |
| `POST` | `/api/v1/export/:exportId/retry` | Resets a failed export job to `Pending` and triggers retry | Yes |

---

## 4. Verification & Testing

### Backend Test Execution
All 11 test suites and 99 tests passed successfully:
```bash
Test Suites: 11 passed, 11 total
Tests:       99 passed, 99 total
Snapshots:   0 total
Time:        11.681 s
Ran all test suites.
```

### Frontend Test Execution
All 5 widget/smoke test cases in `widget_test.dart` passed successfully:
```bash
00:04 +5: All tests passed!
```
