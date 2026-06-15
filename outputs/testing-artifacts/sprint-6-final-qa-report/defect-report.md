# Sprint 6 QA Defect Report

**Report Date:** 2026-06-12  
**Tester:** Senior QA Engineer  
**UAT Environment:** Local Development Environment  

---

## Defect Summary

| Defect ID | Module | Title | Severity | Priority | Status |
|-----------|--------|-------|----------|----------|--------|
| DEF-M13-001 | Module 13 | Audit logs omit critical user actions (registration, login, journal creation, updates, and deletions) | High | High | Open |

---

## Detailed Defect Report: DEF-M13-001

| Field | Details |
|-------|---------|
| **Defect ID** | DEF-M13-001 |
| **Module** | Module 13: Security, Performance & System Reliability |
| **Title** | Audit logs omit critical user actions (registration, login, journal creation, updates, and deletions) |
| **Environment** | Development (localhost:5001) |
| **Severity** | High |
| **Priority** | High |
| **Status** | Open |
| **Impacted KPI** | KPI-100 (Audit logging captures critical user actions) |

### Steps to Reproduce

1. Register a user via `POST /api/v1/auth/register` and verify their email.
2. Authenticate the user via `POST /api/v1/auth/login`.
3. Create a journal entry via `POST /api/v1/journals`.
4. Edit the journal entry via `PUT /api/v1/journals/{id}`.
5. Delete the journal entry via `DELETE /api/v1/journals/{id}`.
6. Open the SQLite database at `outputs/backend/data/journal.db` using an SQLite explorer or DB utility, and query the `AuditLog` table:
   ```sql
   SELECT * FROM AuditLog;
   ```

### Expected vs Actual Results

* **Expected Result:**  
  The `AuditLog` table contains records for all critical actions including registration, login, journal creation, edits, deletions, sharing, and exports (as specified in the KPI-100 specification).

* **Actual Result:**  
  The `AuditLog` table only contains rows for journal sharing (`Share`, `RevokeShare`) and data exports (`Export`, `ExportRetry`). Critical security and transactional operations (registration, login, journal entry creation, updates, and soft/hard deletions) are completely omitted from the database audit log.

### Impact

* **Compliance & Auditing Failure:** Without logging critical account actions (registration, login) and content changes (creation, modification, deletion), there is no tamper-evident audit trail. Security teams cannot trace unauthorized entry modifications or monitor brute-force/account creation attacks.
* **KPI Failure:** Violates KPI-100, which explicitly requires audit coverage for these events.

### Evidence

A search for references to `auditRepository` in the backend codebase (`src/`) reveals that it is imported and invoked strictly in:
1. `src/services/exportService.js` (for data export actions)
2. `src/services/shareService.js` (for journal sharing actions)

No calls to `auditRepository` exist in:
* `src/services/authService.js` (registration, verification, login, password resets)
* `src/services/journalService.js` (creation, updates, deletions)

### Recommendation

Modify `authService.js` and `journalService.js` to import and call `auditRepository`:
1. In `authService.registerUser`: log registration action.
2. In `authService.loginUser`: log login action.
3. In `journalService.createJournal`: log creation action.
4. In `journalService.updateJournal`: log update action.
5. In `journalService.deleteJournal`: log soft or hard deletion action.
