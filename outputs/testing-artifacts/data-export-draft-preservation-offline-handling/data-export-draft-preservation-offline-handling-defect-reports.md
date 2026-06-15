# Defect Report — Sprint 5: Module 10 & Module 11

**Sprint:** Sprint 5  
**Modules:** Module 10 (Data Export) | Module 11 (Draft Preservation & Offline Handling)  
**Tester:** Senior QA Engineer  
**Report Date:** 2026-06-12  
**Environment:** Development (localhost:5001)  

---

## Defect Summary

| Defect ID | Module | Title | Severity | Priority | Status |
|-----------|--------|-------|----------|----------|--------|
| DEF-M10-001 | Module 10 | PDF and DOCX export files are generated as plain-text files with incorrect extensions | Medium | Medium | Fixed |
| DEF-M10-002 | Module 10 | JSON format card displayed in UI but request is rejected by backend with 400 | Low | Medium | Fixed |
| DEF-M11-001 | Module 11 | No explicit user warning dialog/snackbar displayed when remote auto-save fails | Low | Low | Fixed |

---

## Detailed Defect Reports

### DEF-M10-001: PDF and DOCX export files are generated as plain text
| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M10-001 |
| **Module** | Module 10: Data Export (Backend) |
| **Title** | PDF and DOCX export files are generated as plain text |
| **Severity** | Medium |
| **Priority** | Medium |
| **Status** | Fixed |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-12 |
| **Impacted KPI** | KPI-073 (PDF generation), KPI-074 (DOCX generation) |

**Steps to Reproduce:**
1. Authenticate and request a PDF export using `POST /api/v1/export` with `{ "format": "PDF" }`.
2. Wait for background processing to complete and locate the generated file under `public/exports/journal_export_{exportId}.pdf`.
3. Try to open the file in standard document viewers (e.g. Adobe Acrobat Reader, Preview).
4. Observe viewer error.

**Expected Result:**  
The file should be compiled using standard binary formats for PDF (portable document structure) or DOCX (zipped XML package format) so that they can be read by respective document applications.

**Actual Result:**  
The background writer simply writes raw plain text to the file on disk (i.e. `journal_export_{exportId}.pdf` is a plain text file, containing ASCII/UTF-8 lines of title/content, despite the extension). Standard readers reject the file as corrupted.

**Root Cause (Analysis):**  
In `exportService.js` (lines 149-153), the text content is written directly using standard node file-system module without using styling or generator libraries (like `pdfkit` or `docx` package):
```js
fs.writeFileSync(filePath, reportText, 'utf8');
```

**Evidence:**  
Inspecting file contents reveals plain text format:
```text
==================================================
JOURNAL ARCHIVE EXPORT (PDF)
User Name: User One
...
```

**Recommended Fix:**  
Integrate npm libraries such as `pdfkit` (for PDF compilation) and `docx` (for Word document generation) to output valid structured documents.

---

### DEF-M10-002: JSON format card shown in UI but rejected by backend
| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M10-002 |
| **Module** | Module 10: Data Export (Frontend/Backend Mismatch) |
| **Title** | JSON format card shown in UI but rejected by backend |
| **Severity** | Low |
| **Priority** | Medium |
| **Status** | Fixed |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-12 |
| **Impacted KPI** | KPI-072 (Trigger export), KPI-079 (Download URL access) |

**Steps to Reproduce:**
1. Open the Data Export screen in the mobile app.
2. Tap on the card "Export as JSON".
3. Observe the SnackBar message.

**Expected Result:**  
JSON exports should either be supported by the backend, or the card should be removed/disabled in the UI.

**Actual Result:**  
A red SnackBar appears showing: `Export failed: INVALID_EXPORT_FORMAT`. The backend Joi schema and controller specifically reject any format except `PDF` or `DOCX`.

**Root Cause (Analysis):**  
`export_screen.dart` renders a JSON export card at line 149, which calls `_triggerExport(context, ref, 'JSON')`. However, the backend validation in `exportValidation.js` and checking in `exportService.js` restricts valid formats strictly to PDF and DOCX:
```js
if (!format || (format !== 'PDF' && format !== 'DOCX')) {
  throw new ApiError(400, 'INVALID_EXPORT_FORMAT', 'Format must be either PDF or DOCX');
}
```

**Evidence:**  
Response from API:
```json
{
  "errorCode": "INVALID_EXPORT_FORMAT",
  "message": "Format must be either PDF or DOCX"
}
```

**Recommended Fix:**  
Remove the JSON option from `export_screen.dart` grid or implement JSON serialization and support in `exportService.js` in the backend.

---

### DEF-M11-001: No explicit user warning dialog when remote auto-save fails
| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M11-001 |
| **Module** | Module 11: Draft Preservation & Offline Handling (Frontend) |
| **Title** | No explicit user warning dialog when remote auto-save fails |
| **Severity** | Low |
| **Priority** | Low |
| **Status** | Fixed |
| **Reported By** | QA Engineer |
| **Date Found** | 2026-06-12 |
| **Impacted KPI** | KPI-081 (Auto-save failure notification) |

**Steps to Reproduce:**
1. Open a journal entry in the editor screen.
2. Disconnect internet access (simulate network loss).
3. Type in the content field to trigger auto-save.
4. Watch for visual warning alerts or dialog notifications.

**Expected Result:**  
The user receives an explicit, non-intrusive alert, toast, or banner notifying them that remote backup sync failed and changes are stored locally only.

**Actual Result:**  
The app bar text changes to "Local draft saved", but no explicit toast, warning badge, or alert dialog is shown. If a user is focused on the text area, they may not notice the small app-bar status change and assume their draft is backed up in the cloud.

**Root Cause (Analysis):**  
In `editor_screen.dart` (lines 205-211), the `catch (_)` block of the async remote save silently swallows the error and updates state text without triggering any alert or SnackBar notification:
```dart
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveStatus = 'Local draft saved';
        });
      }
    }
```

**Evidence:**  
Code review of the catch block in `_performAutoSave`.

**Recommended Fix:**  
Add a subtle warning badge (e.g. orange warning icon) next to the status message, or show a transient toast message when the transition from "Draft saved" to "Local draft saved" first occurs.
