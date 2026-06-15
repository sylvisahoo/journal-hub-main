# Implementation Plan - Sprint 5 Backend (Data Export & Draft / Offline Support)

We will implement the backend logic, repositories, services, controllers, and routing for Module 10 (Data Export) and ensure draft/offline endpoints (Module 11) are fully robust.

## User Review Required

> [!IMPORTANT]
> - **Asynchronous Background Processing**: Export requests (`POST /api/v1/export`) will immediately return `202 Accepted` and offload generation of PDF/DOCX archives to a background worker queue, preventing API timeouts.
> - **Notification Triggering**: Once an export finishes (or fails), a live in-app notification is inserted into the `Notification` database table so the frontend can display alert statuses.
> - **Retry Mechanism**: We will provide a retry endpoint `POST /api/v1/export/:exportId/retry` which resets a failed export job to `Pending` and re-triggers background generation.
> - **Static File Delivery**: Express will be configured to statically serve completed exports from the `/exports` folder, providing download file access.

## Proposed Changes

### Component: Database & Repositories

We will implement repository files for managing export jobs and files.

#### [NEW] [exportRepository.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/repositories/exportRepository.js)
- `createExportRequest(exportId, userId, format)`: Insert pending export request.
- `getExportRequest(exportId)`: Fetch export details (including format, status, and request date).
- `updateExportRequestStatus(exportId, status, completedAt)`: Update job state (`Pending`, `Processing`, `Completed`, `Failed`).
- `createExportFile(fileId, exportId, fileName, downloadUrl, expiresAt)`: Insert file download details.
- `getExportFileByExportId(exportId)`: Retrieve download path for completed exports.
- `getUserExportRequests(userId)`: Retrieve list of export jobs for a user.

---

### Component: Service Layer

We will implement business logic for asynchronous generation, file assembly, notifications, and retrying.

#### [NEW] [exportService.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js)
- `requestExport(userId, format, hostUrl, clientIp)`: Validate format. Generate export ID. Insert pending request and trigger background worker. Log an `Export` action in the `AuditLog`. Return job info.
- `getExportStatus(userId, exportId)`: Fetch export status. Validate ownership (returns `403 ACCESS_DENIED` if requested by another user). If complete, attach `downloadUrl` from `ExportFile`.
- `retryExport(userId, exportId, hostUrl, clientIp)`: Validate ownership. Check if job failed. If so, reset to `Pending`, re-trigger worker, and return 202.
- `processExportBackground(exportId, userId, format, hostUrl)`: Background worker.
  - Update status to `Processing`.
  - Fetch all active user entries.
  - Formulate journal report content (date, category, title, content, tags).
  - Write report to static export directory.
  - Insert `ExportFile` entry (expires in 24 hours).
  - Update status to `Completed` and insert success notification.
  - On failure, catch error, update status to `Failed` and insert failure notification.

---

### Component: Controller & Route Layer

We will expose the endpoints to handle export triggers.

#### [NEW] [exportController.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/controllers/exportController.js)
- `requestExport`: Parse body format, call service, return `202` with job info.
- `getExportStatus`: Parse export ID, call service, return `200` with status/download URL.
- `retryExport`: Parse export ID, call service, return `202` with updated job.

#### [NEW] [exportValidation.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/exportValidation.js)
- Define schema validating that `format` is strictly `PDF` or `DOCX`.

#### [NEW] [exportRoutes.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/routes/exportRoutes.js)
- Expose endpoints:
  - `POST /` (creates export)
  - `GET /:exportId` (checks status)
  - `POST /:exportId/retry` (retries failed export)
- Apply `authMiddleware` across all endpoints.

#### [MODIFY] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/app.js)
- Mount `exportRoutes` on `/api/v1/export`.
- Configure `express.static` to serve files from `public/exports` on route `/exports`.

---

## Verification Plan

### Automated Tests
- Create `outputs/backend/tests/export.test.js`:
  - Verify `POST /api/v1/export` returns 202 and pending status.
  - Verify invalid format returns 400 `INVALID_EXPORT_FORMAT`.
  - Verify background generation transitions status: `Pending` -> `Processing` -> `Completed`.
  - Verify completing the job writes a file to disk, creates an `ExportFile` database record, and writes a success entry to `Notification`.
  - Verify `GET /api/v1/export/:exportId` returns status and download URL.
  - Verify ownership constraints (unauthorized users cannot view status).
  - Verify simulating a failure sets status to `Failed` and creates a failure notification.
  - Verify `POST /api/v1/export/:exportId/retry` resets job and triggers successful recovery.

### Manual Verification
- Execute `npm test` inside `outputs/backend` to run all tests.
