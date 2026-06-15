# Module 10: Data Export — Test Cases Report
# Module 11: Draft Preservation & Offline Handling — Test Cases Report

**Sprint:** Sprint 5  
**Tester:** Senior QA Engineer  
**Test Execution Date:** 2026-06-12  
**Backend Version:** Node.js/Express — Port 5001  
**Frontend Version:** Flutter (Riverpod State Management)  
**Environment:** Development  

---

## Scope

This report covers functional, integration, validation, security, and performance testing for:

- **Module 10:** Data Export (KPI-072 → KPI-079)
- **Module 11:** Draft Preservation & Offline Handling (KPI-080 → KPI-084)

---

# Module 10: Data Export

## Validation Functions Table

| KPI Number | KPI | Validation Method | Expected Output | Actual Output | Status | Notes |
| ---------- | --- | ----------------- | --------------- | ------------- | ------ | ----- |
| KPI-072 | User can export all journal entries | Execute POST `/api/v1/export` with valid format; verify export generation process starts | HTTP 202 Accepted response with export ID and `Pending` status | HTTP 202 returned with `{"exportId":"exp-...","status":"Pending"}` | ✅ PASS | Generation starts asynchronously on backend background queue |
| KPI-073 | PDF export generates successfully | Generate PDF export and verify file integrity and content completeness | Background process compiles PDF file on disk, updates status to `Completed`, and registers static route | HTTP 200 download of PDF containing journal entry structure, status set to `Completed` | ✅ PASS | PDF compiled as a valid binary file using `pdfkit` library |
| KPI-074 | DOCX export generates successfully | Generate DOCX export and verify file integrity and content completeness | Background process compiles DOCX file on disk, updates status to `Completed`, and registers static route | HTTP 200 download of DOCX containing journal entries, status set to `Completed` | ✅ PASS | DOCX compiled as a valid Microsoft Word binary document using `docx` library |
| KPI-075 | Exported files contain all user entries | Compare export content with database records and verify completeness | Generated archive contents match active user journal entries | Export file content verified to contain all user titles, dates, word counts, and text bodies | ✅ PASS | Soft-deleted entries are correctly excluded from compilation |
| KPI-076 | Large exports are processed asynchronously | Trigger large export and verify background processing workflow executes correctly | POST `/export` returns immediately without blocking main thread; status transitions asynchronously | HTTP 202 returned immediately (~5ms); status transitions `Pending` -> `Processing` -> `Completed` | ✅ PASS | Executed using `setImmediate` block to release event loop |
| KPI-077 | Export completion notification is generated | Complete export and verify user receives completion notification | Live notification is generated and saved in the `Notification` table for the user | Notification record added in SQLite database: "Your journal export (ID: ...) is ready" | ✅ PASS | Correctly generated on both success and background fail paths |
| KPI-078 | Export retry mechanism works after failure | Simulate export failure and verify retry process executes successfully | POST `/api/v1/export/:exportId/retry` resets status to `Pending` and triggers background regeneration | HTTP 202 returned; job resets status, begins processing, and completes successfully | ✅ PASS | Audited under `ExportRetry` action type in `AuditLog` table |
| KPI-079 | Export download URL provides valid file access | Access generated download URL and verify file download succeeds | Static download URL responds with HTTP 200 and the compiled file payload | HTTP 200 returned with the correct file contents from static server path `/exports/` | ✅ PASS | Served via Express static middleware from local `public/exports` directory |

---

## Additional Test Cases — Module 10

| Test ID | Test Case | Test Steps | Expected | Actual | Status |
|---------|-----------|------------|----------|--------|--------|
| TC-M10-SEC-01 | Unauthenticated export request rejected | Call POST `/api/v1/export` without Authorization header | HTTP 401 UNAUTHORIZED | HTTP 401 Unauthorized | ✅ PASS |
| TC-M10-SEC-02 | Cross-user export status isolation | Access status endpoint of User1's export job using User2's auth token | HTTP 403 ACCESS_DENIED | HTTP 403 Forbidden with `ACCESS_DENIED` error code | ✅ PASS |
| TC-M10-SEC-03 | Cross-user retry request isolated | Request retry of User1's failed job using User2's auth token | HTTP 403 ACCESS_DENIED | HTTP 403 Forbidden with `ACCESS_DENIED` error code | ✅ PASS |
| TC-M10-VAL-01 | Unsupported JSON export validation | Request JSON export via card click in UI | Export request is accepted and JSON file generated successfully | HTTP 202 Accepted response; JSON file created on disk with correct entries | ✅ PASS | JSON export is now fully supported on the backend (DEF-M10-002 fixed) |
| TC-M10-VAL-02 | Query status of non-existent export ID | GET `/api/v1/export/exp-missing-999` | HTTP 404 EXPORT_NOT_FOUND | HTTP 404 Not Found with `EXPORT_NOT_FOUND` error code | ✅ PASS |
| TC-M10-VAL-03 | Retry non-failed export request | POST `/api/v1/export/:exportId/retry` for job in `Completed` status | HTTP 400 INVALID_RETRY | HTTP 400 Bad Request with `INVALID_RETRY` error code | ✅ PASS |
| TC-M10-INT-01 | Frontend list view loads active requests | Open Export screen in app | List of recent exports is shown with accurate statuses | ListView shows exports with text names and status symbols | ✅ PASS |
| TC-M10-INT-02 | Automatic status polling refreshes list | Trigger export; observe status change without refreshing screen | Status updates in real-time in UI | Provider timer polling refreshes jobs every 2 seconds; status changes to Completed | ✅ PASS |
| TC-M10-INT-03 | Frontend retry click triggers backend | Click "Retry" button on a failed export job list tile | SnackBar indicates retry starting; job status updates to Pending | Orange SnackBar is shown; status becomes Pending and changes to Completed | ✅ PASS |

---

# Module 11: Draft Preservation & Offline Handling

## Validation Functions Table

| KPI Number | KPI | Validation Method | Expected Output | Actual Output | Status | Notes |
| ---------- | --- | ----------------- | --------------- | ------------- | ------ | ----- |
| KPI-080 | Draft content is preserved during temporary connectivity loss | Disconnect network while editing and verify draft remains available locally | Periodic auto-save successfully writes draft to local SharedPreferences | `saveDraftLocal` writes key `draft_{id}` to SharedPreferences; state stays preserved | ✅ PASS | Offline edits persist locally without application crash |
| KPI-081 | User receives notification when auto-save fails | Simulate auto-save failure and verify error notification appears | User receives visual indicator or alert when server sync fails | SnackBar warning displayed and status icon updates to orange cloud_off_rounded | ✅ PASS | Transient orange SnackBar warning displayed on initial offline transition (DEF-M11-001 fixed) |
| KPI-082 | Draft content can be recovered after browser refresh | Refresh page before saving and verify locally stored draft restoration | Reopening editor detects local draft and prompts user to restore or discard | restoration dialog "Recover Unsaved Draft?" displays; clicking Restore recovers title & content | ✅ PASS | Restored fields match previous unsaved editor text exactly |
| KPI-083 | Application handles offline state gracefully | Operate application offline and verify appropriate messaging and limited functionality | Application remains responsive; API calls fail safely, local drafts save | Navigation operates; category/tag load errors caught; no runtime crash | ✅ PASS | Network exceptions are caught safely in repository layers |
| KPI-084 | Draft synchronization resumes after connectivity restoration | Reconnect network and verify draft uploads successfully | Subsequent auto-save triggers successful request to `/api/v1/drafts` | Next keystroke triggers auto-save which updates remote draft; status updates to "Draft saved" | ✅ PASS | Synced status and draft ID successfully updated in local state notifier |

---

## Additional Test Cases — Module 11

| Test ID | Test Case | Test Steps | Expected | Actual | Status |
|---------|-----------|------------|----------|--------|--------|
| TC-M11-SEC-01 | Unauthenticated draft save request rejected | Call POST `/api/v1/drafts` without Authorization header | HTTP 401 UNAUTHORIZED | HTTP 401 Unauthorized | ✅ PASS |
| TC-M11-SEC-02 | Cross-user draft modification isolation | Try to edit another user's draft ID | HTTP 403 ACCESS_DENIED | HTTP 403 Forbidden with `ACCESS_DENIED` error code | ✅ PASS |
| TC-M11-SEC-03 | Cross-user draft fetch isolation | Try to fetch another user's draft details | HTTP 403 ACCESS_DENIED | HTTP 403 Forbidden with `ACCESS_DENIED` error code | ✅ PASS |
| TC-M11-VAL-01 | Missing draft details in request | POST `/api/v1/drafts` with empty payload | HTTP 400 Bad Request | HTTP 400 validation error (Joi schema validation) | ✅ PASS |
| TC-M11-VAL-02 | Fetch non-existent draft ID | GET `/api/v1/drafts/d-missing-999` | HTTP 404 DRAFT_NOT_FOUND | HTTP 404 Not Found with `DRAFT_NOT_FOUND` error code | ✅ PASS |
| TC-M11-INT-01 | Discard draft clears SharedPreferences | Click "Discard Draft" on the recovery dialog | Local draft cleared; editor loads default original state | SharedPreferences `draft_{id}` key is removed; original entry or blank state loaded | ✅ PASS |
| TC-M11-INT-02 | Saving journal clears local draft storage | Edit a recovered draft and press the main "Save" button | Entry is saved; local SharedPreferences draft is deleted | Entry persists to entries repository; `clearLocalDraft` called; list reloads | ✅ PASS |
| TC-M11-INT-03 | Auto-save debouncing works correctly | Type rapidly in the content editor field | Save request is debounced and delayed until typing pauses | Debouncer waits 2 seconds after last keystroke before saving | ✅ PASS |

---

## Test Environment

| Parameter | Value |
|-----------|-------|
| Backend URL | http://localhost:5001/api/v1 |
| Database | SQLite (journal.db) |
| Device coverage | iOS / Android Emulators, Desktop Web Portal |
| Testing Tools | Supertest, Jest, Flutter Integration Tests |
