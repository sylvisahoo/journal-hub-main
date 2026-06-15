# Implementation Plan - Sprint 5 Defects Fixing

We will resolve the QA findings reported for Sprint 5 covering Module 10 (Data Export) and Module 11 (Draft Preservation & Offline Handling).

## Proposed Changes

### 1. Data Export Format Mismatch & JSON Support (DEF-M10-002)

To resolve the discrepancy where "Export as JSON" card is in the UI but rejected by the backend:
* **`outputs/backend/src/validation/exportValidation.js`**: Update Joi schema to validate and allow `JSON` format.
* **`outputs/backend/src/services/exportService.js`**:
  - Update format check to allow `JSON`.
  - In background processor, if format is `JSON`, map entries list to JSON and write to `journal_export_{id}.json` using `JSON.stringify()`.

### 2. Valid Binary Export Generation (DEF-M10-001)

To resolve files being generated as plain text with incorrect extensions:
* **`outputs/backend/package.json`**: Done (added `pdfkit` and `docx` dependencies).
* **`outputs/backend/src/services/exportService.js`**:
  - Implement PDF compilation using `pdfkit` library (generating valid binary PDFs containing export headers, user info, and entries).
  - Implement DOCX compilation using `docx` library (generating valid Microsoft Word binary documents).
* **`outputs/backend/tests/export.test.js`**:
  - Update Supertest response assertion to expect the standard `%PDF` file signature instead of raw ASCII matching since the PDF is now a binary stream.
  - Add test case verifying JSON export executes and generates a valid JSON file.

### 3. Explicit Offline Auto-Save Notification (DEF-M11-001)

To alert the user explicitly when remote auto-save fails:
* **`outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart`**:
  - In `_performAutoSave()`, when `draftRepo.saveDraftRemote()` throws an exception, show a transient orange SnackBar informing the user: `"Auto-save failed: Storing draft locally (offline)"` (triggered only on initial transition to prevent spamming).
  - Update App Bar status indicator row when `_saveStatus == 'Local draft saved'` to render a `Icons.cloud_off_rounded` icon in `Colors.orangeAccent` to explicitly signal offline state.

---

## Verification Plan

### Automated Tests
* Run Jest test suite to check new export validations and binary output assertions:
  ```bash
  npm test
  ```
* Run Flutter test suite to verify no UI compile regressions:
  ```bash
  flutter test
  ```

### Manual Verification
* Start server and trigger all three export formats (`PDF`, `DOCX`, `JSON`) from the Flutter UI and verify they complete successfully.
* Open generated `.pdf` and `.docx` files in native document readers to confirm valid binary structure.
* Toggle network link during editor session and verify SnackBar warning appears and app bar indicator turns orange with `Local draft saved` text.
