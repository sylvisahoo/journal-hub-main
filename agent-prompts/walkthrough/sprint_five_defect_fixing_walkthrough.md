# Walkthrough - Sprint 5 Defects Fixing

We have resolved all the QA-reported defects for Sprint 5 covering **Module 10 (Data Export)** and **Module 11 (Draft Preservation & Offline Handling)**. All backend and frontend test suites are passing successfully.

---

## 1. Overview of Resolved Defects

We addressed three primary QA findings:
1. **DEF-M10-001 (Medium)**: PDF and DOCX exports were generated as plain-text files with incorrect extensions instead of binary files.
2. **DEF-M10-002 (Low)**: The JSON format card was displayed in the UI, but requesting it returned an API validation 400 error.
3. **DEF-M11-001 (Low)**: No explicit user warning dialog or SnackBar was shown when remote auto-save failed and fell back to local storage.

---

## 2. Technical Fixes & Implementation Details

### Data Export Binary PDF & DOCX Generation (DEF-M10-001)
* **Real Binary Formats**: Updated [`exportService.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js) to compile structured documents:
  - **PDF compilation**: Configured `pdfkit` to compile valid PDF documents containing headers, metadata, titles, dates, word counts, and formatting.
  - **DOCX compilation**: Configured `docx` to package Word documents using correct paragraphs, tables, formatting, and spacing, converting the packer promise to a buffer write.
* **Stream Checks in Tests**: Updated `tests/export.test.js` to assert file signatures (`%PDF-` header check) rather than raw ASCII matching since the files are now binary.

### Data Export JSON Format Support (DEF-M10-002)
* **Backend Validation**: Modified Joi schema in [`exportValidation.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/validation/exportValidation.js) to accept and validate `'JSON'` format requests.
* **JSON Serialization**: Configured [`exportService.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/services/exportService.js) to serialize all user entries into a JSON array file under the static route when format is `'JSON'`.
* **Database CHECK Constraint Update**: Modified table schema DDL in [`schema.sql`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/schema.sql) to include `'JSON'` in the `ExportRequest` `export_format` constraint: `CHECK(export_format IN ('PDF', 'DOCX', 'JSON'))`.
* **Database Test Schema Recreation**: Updated [`initDb.js`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/backend/src/config/initDb.js) to drop existing SQLite tables before recreation in `test` mode, ensuring schema CHECK constraint updates are correctly applied to the SQLite instance.

### Editor Screen Offline SnackBar & Icon Status (DEF-M11-001)
* **Initial Transition Alert**: Added state variable `_hasShownOfflineAlert` in [`editor_screen.dart`](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/journal-hub/outputs/frontend/lib/src/features/journal/presentation/editor_screen.dart). When `saveDraftRemote()` fails, the catch block triggers an orange SnackBar: `"Auto-save failed: Storing draft locally (offline)"` on the initial offline save state to prevent toast spamming.
* **App Bar Status Customization**: Updated App Bar status rendering inside the widget tree to check for `_saveStatus == 'Local draft saved'`. When true, it renders `Icons.cloud_off_rounded` in `Colors.orangeAccent` with orange status text, explicitly warning the user that their edits are saved locally but not yet synced to the cloud.

---

## 3. Verification & Test Execution

### Backend Integration Tests (Jest)
All 11 test suites and 100 tests passed successfully, including new checks for binary PDF signatures, JSON formatting, and database constraints:
```bash
Test Suites: 11 passed, 11 total
Tests:       100 passed, 100 total
Snapshots:   0 total
Time:        12.887 s
Ran all test suites.
```

### Frontend Widget Tests (Flutter)
All 5 widget/smoke test cases in `widget_test.dart` compile and pass successfully:
```bash
00:03 +5: All tests passed!
```
